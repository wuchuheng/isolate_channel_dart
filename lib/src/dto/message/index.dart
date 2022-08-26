import 'package:json_annotation/json_annotation.dart';

enum DataType {
  CLOSE,
  DATA,
  ERROR,
}

@JsonSerializable()
class Message {
  final String data;
  final int channelId;
  final DataType dataType;
  final String name;
  final Exception? exception;

  Message({
    this.data = '',
    this.exception,
    required this.channelId,
    required this.name,
    this.dataType = DataType.DATA,
  });
}
