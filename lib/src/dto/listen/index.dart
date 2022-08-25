class Listen {
  late final Function() _cancel;

  Listen(Function() cancel) {
    _cancel = cancel;
  }

  void cancel() => _cancel();
}
