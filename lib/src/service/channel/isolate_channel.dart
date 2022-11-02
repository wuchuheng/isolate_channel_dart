import 'dart:async';
import 'dart:isolate';

import 'package:stack_trace/stack_trace.dart';
import 'package:uuid/uuid.dart';
import 'package:wuchuheng_isolate_channel/src/dto/listen/listen.dart';
import 'package:wuchuheng_isolate_channel/src/service/channel/channel_abstract.dart';
import 'package:wuchuheng_task_util/wuchuheng_task_util.dart';

import '../../../wuchuheng_isolate_channel.dart';
import '../../dto/message/index.dart';
import '../../exception/error_exception.dart';

class IsolateChannel implements ChannelAbstract {
  SingleTaskPool singleTaskPool = SingleTaskPool.builder();
  @override
  final String channelId;

  late final SendPort _sendPort;
  final List<Function(String name)> _onCloseCallbackList = [];
  final List<Function(Exception error)> _onErrorCallbackList = [];
  final List<Function(String message)> _toFutureCallback = [];

  @override
  final String name;
  final Map<String, IsolateSubjectCallback> _idMapCallback = {};

  IsolateChannel({
    required SendPort sendPort,
    required this.name,
    required this.channelId,
  }) : _sendPort = sendPort;

  @override
  void close() {
    for (var callback in _onCloseCallbackList) {
      callback(name);
    }
    _onCloseCallbackList.clear();
    final data = Message(channelId: channelId, dataType: DataType.CLOSE, name: name);
    _sendPort.send(data);
    singleTaskPool.start(() async {
      _onErrorCallbackList.clear();
    });
  }

  @override
  void send(String message) {
    final data = Message(channelId: channelId, data: message, dataType: DataType.DATA, name: name);
    _sendPort.send(data);
  }

  @override
  void onClose(Function(String name) callback) => _onCloseCallbackList.add(callback);

  @override
  Listen listen(IsolateSubjectCallback callback) {
    final String id = Uuid().v4();
    _idMapCallback[id] = callback;
    return Listen(() {
      if (_idMapCallback.containsKey(id)) _idMapCallback.remove(id);
    });
  }

  @override
  void onMessage(Message message) {
    switch (message.dataType) {
      case DataType.CLOSE:
        for (var callback in _onCloseCallbackList) {
          callback(name);
        }
        _onCloseCallbackList.clear();
        break;
      case DataType.DATA:
        for (var id in _idMapCallback.keys) {
          (() async {
            try {
              await _idMapCallback[id]!(message.data, this);
            } on Exception catch (e) {
              _sendPort.send(Message(channelId: channelId, name: name, dataType: DataType.ERROR, exception: e));
            } on Error catch (e, stack) {
              final chain = Chain.forTrace(stack);
              final frames = chain.toTrace().frames;
              final frame = frames[1];
              final file = '${frame.uri}:${frame.line}:${frame.column}';
              final err = ErrorException(file);
              _sendPort.send(Message(channelId: channelId, name: name, dataType: DataType.ERROR, exception: err));
            }
          })();
        }
        for (var callback in _toFutureCallback) {
          callback(message.data);
        }
        _toFutureCallback.clear();

        break;
      case DataType.ERROR:
        singleTaskPool.start(() async {
          for (final callback in _onErrorCallbackList) {
            callback(message.exception!);
          }
        });
        break;
    }
  }

  @override
  void onError(Function(Exception e) callback) async => await singleTaskPool.start(() async {
        _onErrorCallbackList.add(callback);
      });

  @override
  Future<String> listenToFuture() {
    Completer<String> completer = Completer();
    _toFutureCallback.add((message) => completer.complete(message));

    return completer.future;
  }
}
