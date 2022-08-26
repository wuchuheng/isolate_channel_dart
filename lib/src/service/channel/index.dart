import 'dart:isolate';

import '../../dto/listen/index.dart';
import '../../dto/message/index.dart';
import 'index_abstract.dart';

class Channel implements ChannelAbstract {
  late final Function() _close;
  final int channelId;
  final SendPort sendPort;
  final List<Function(String name)> _onCloseCallbackList = [];
  final List<Function(Exception error)> _onErrorCallbackList = [];
  @override
  final String name;
  final Map<int, Function(String message, ChannelAbstract channel)> _idMapCallback = {};

  Channel({
    required this.sendPort,
    required this.name,
    required this.channelId,
    required Function() close,
  }) {
    _close = close;
  }

  @override
  void close() {
    for (var callback in _onCloseCallbackList) {
      callback(name);
    }
    _onCloseCallbackList.clear();
    final data = Message(channelId: channelId, dataType: DataType.CLOSE, name: name);
    sendPort.send(data);
    _onErrorCallbackList.clear();
    _close();
  }

  @override
  void send(String message) {
    final data = Message(channelId: channelId, data: message, dataType: DataType.DATA, name: name);
    sendPort.send(data);
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
            sendPort.send(Message(channelId: channelId, name: name, dataType: DataType.ERROR, exception: e));
          }
        }
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
}
