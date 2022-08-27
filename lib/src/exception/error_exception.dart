class ErrorException implements Exception {
  final String msg;
  ErrorException(this.msg);
  String toString() => 'FooException: $msg';
}
