class Channel {
  late final Function() _unsubscribe;

  late final Function(String message) _send;

  Channel({
    required Function() unsubscribe,
    required Function(String message) send,
  }) {
    _unsubscribe = unsubscribe;
    _send = send;
  }

  void unsubscribe() => _unsubscribe();

  void send(String message) => _send(message);
}
