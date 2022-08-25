class Channel {
  late final Function() _close;
  final int channelId;
  late final Function(String message) _send;
  List<Function> onCloseCallbackList = [];

  Channel({
    required this.channelId,
    required Function() close,
    required Function(String message) send,
  }) {
    _close = close;
    _send = send;
  }

  void unsubscribe() => _close();

  void send(String message) => _send(message);

  void onClose(Function callback) => onCloseCallbackList.add(callback);
}
