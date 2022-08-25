import 'dart:convert';
import 'dart:isolate';

import 'package:wuchuheng_isolate_subject/src/dto/message/index.dart';

typedef SenderFunc = Function(String message) Function(
  SendPort sendPort,
  Message message,
);

final SenderFunc sender = (SendPort sendPort, Message message) {
  return (String newMessage) {
    final str = jsonEncode(
      Message(channelId: message.channelId, data: newMessage),
    );
    sendPort.send(str);
  };
};
