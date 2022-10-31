import 'dart:async';
import 'dart:isolate';

import 'package:stack_trace/stack_trace.dart';
import 'package:wuchuheng_isolate_channel/src/exception/error_exception.dart';
import 'package:wuchuheng_task_util/wuchuheng_task_util.dart';

import '../../../wuchuheng_isolate_channel.dart';
import '../../dto/listen/index.dart';
import '../../dto/message/index.dart';
import 'index_abstract.dart';

class Channel implements ChannelAbstract {
  SingleTaskPool singleTaskPool = SingleTaskPool.builder();
  late final Function() _close;
  @override
  final int channelId;

  late final SendPort _sendPort;
  final List<Function(String name)> _onCloseCallbackList = [];
  final List<Function(Exception error)> _onErrorCallbackList = [];
  final List<Function(String message)> _toFutureCallback = [];

  @override
  final String name;
  final Map<int, IsolateSubjectCallback> _idMapCallback = {};

  Channel({
    required SendPort sendPort,
    required this.name,
    required this.channelId,
    required Function() close,
  }) {
    _sendPort = sendPort;
    _close = close;
  }

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
    _close();
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
    final id = DateTime.now().microsecondsSinceEpoch;
    _idMapCallback[id] = callback;
    return Listen(() {
      if (_idMapCallback.containsKey(id)) _idMapCallback.remove(id);
    });
  }

  Map<int, Channel> childChannel = {};

  @override
  void onMessage(Message message) {
    switch (message.dataType) {
      case DataType.CLOSE:
        for (var callback in _onCloseCallbackList) {
          callback(name);
        }
        _onCloseCallbackList.clear();
        _close();
        break;
      case DataType.DATA:
        for (var id in _idMapCallback.keys) {
          (() async {
            try {
              final int childChannelId = DateTime.now().microsecondsSinceEpoch;
              final channel = Channel(
                  sendPort: _sendPort,
                  name: name,
                  channelId: channelId,
                  close: () {
                    childChannel.removeWhere((key, value) => key == childChannelId);
                  });
              childChannel.addAll({childChannelId: channel});
              await _idMapCallback[id]!(message.data, childChannel[childChannelId]!);
              channel.onMessage(message);
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
