// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'index.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
      data: json['data'] as String,
      channelId: json['channelId'] as int,
    );

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
      'data': instance.data,
      'channelId': instance.channelId,
    };
