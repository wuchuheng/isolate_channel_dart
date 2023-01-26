import 'package:json_annotation/json_annotation.dart';

enum DataType {
  CLOSE,
  DATA,
  ERROR,
}

@JsonSerializable()
class Message<T> {
  final dynamic data;
  final String channelId;
  final DataType dataType;
  final T name;
  final Exception? exception;

  Message({
    this.data = '',
    this.exception,
    required this.channelId,
    required this.name,
    this.dataType = DataType.DATA,
  });
}
