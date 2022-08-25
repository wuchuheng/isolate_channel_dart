class Channel {
  late final Function() _close;
  final int channelId;
  late final Function(String message) _send;
  final List<Function> onCloseCallbackList = [];
  final String name;

  Channel({
    required this.name,
    required this.channelId,
    required Function() close,
    required Function(String message) send,
  }) {
    _close = close;
    _send = send;
  }

  void close() => _close();

  void send(String message) => _send(message);

  void onClose(Function callback) => onCloseCallbackList.add(callback);
}
