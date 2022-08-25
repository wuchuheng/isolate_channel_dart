import 'dart:async';

class SubjectHook<T> {
  final List<Function(T value)> _callback = [];

  Future<T> toPromise() async {
    Completer<T> completer = Completer();
    _callback.add((T value) {
      completer.complete(value);
    });

    return completer.future;
  }

  next(T value) {
    for (var callback in _callback) {
      callback(value);
    }
    _callback.clear();
  }
}
