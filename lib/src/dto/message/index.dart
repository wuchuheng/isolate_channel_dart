import 'package:json_annotation/json_annotation.dart';

part 'index.g.dart';

enum DataType {
  CLOSE,
  DATA,
}

@JsonSerializable()
class Message {
  final String data;
  final int channelId;
  final DataType dataType;
  final String name;

  Message({
    this.data = '',
    required this.channelId,
    required this.name,
    this.dataType = DataType.DATA,
  });

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);

  Map<String, dynamic> toJson() => _$MessageToJson(this);
}
