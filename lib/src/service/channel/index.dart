import 'dart:async';
import 'dart:isolate';

import '../../dto/listen/index.dart';
import '../../dto/message/index.dart';
import 'index_abstract.dart';

class Channel implements ChannelAbstract {
  late final Function() _close;
  final int channelId;
  late final SendPort _sendPort;
  final List<Function(String name)> _onCloseCallbackList = [];
  final List<Function(Exception error)> _onErrorCallbackList = [];
  final List<Function(String message)> _toFutureCallback = [];

  @override
  final String name;
  final Map<int, Function(String message, ChannelAbstract channel)> _idMapCallback = {};

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
    _onErrorCallbackList.clear();
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
  Listen listen(Function(String message, ChannelAbstract channel) callback) {
    final id = DateTime.now().microsecondsSinceEpoch;
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
        _close();
        break;
      case DataType.DATA:
        for (var id in _idMapCallback.keys) {
          try {
            _idMapCallback[id]!(message.data, this);
          } on Exception catch (e) {
            _sendPort.send(Message(channelId: channelId, name: name, dataType: DataType.ERROR, exception: e));
          }
        }
        for (var callback in _toFutureCallback) {
          callback(message.data);
        }
        _toFutureCallback.clear();
        break;
      case DataType.ERROR:
        for (final callback in _onErrorCallbackList) {
          callback(message.exception!);
        }
        break;
    }
  }

  @override
  void onError(Function(Exception e) callback) => _onErrorCallbackList.add(callback);

  @override
  Future<String> listenToFuture() {
    Completer<String> completer = Completer();
    _toFutureCallback.add((message) => completer.complete(message));

    return completer.future;
  }
}
