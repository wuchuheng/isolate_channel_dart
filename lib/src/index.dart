// TODO: Put public facing types in this file.

import 'dart:convert';
import 'dart:isolate';

import 'package:wuchuheng_isolate_subject/src/dto/message/index.dart';
import 'package:wuchuheng_isolate_subject/src/util/sender_util.dart';
import 'package:wuchuheng_isolate_subject/src/util/subject_hook.dart';

import 'dto/subscription/index.dart';

typedef Sender = Function(String message);
typedef IsolateSubjectCallback = Function(
  String message,
  Function(String message) sender,
);

Future<Subject> isolateSubject(IsolateSubjectCallback callback) async {
  ReceivePort receivePort = ReceivePort();
  Isolate.spawn<SendPort>((SendPort isolateSendPort) async {
    ReceivePort isolateReceivePort = ReceivePort();
    isolateSendPort.send(isolateReceivePort.sendPort);
    await for (var messageJson in isolateReceivePort) {
      final message = Message.fromJson(jsonDecode(messageJson));
      callback(message.data, sender(isolateSendPort, message));
    }
  }, receivePort.sendPort);
  return await Subject().init(receivePort);
}

class Subject {
  Map<int, Function(String message, Sender sender)> channelIdMapCallback = {};
  late final SendPort sendPort;
  late final ReceivePort receivePort;

  init(ReceivePort receivePort) async {
    this.receivePort = receivePort;
    bool isFirst = false;
    final sendPortSubject = SubjectHook<SendPort>();
    receivePort.listen((value) {
      if (!isFirst) {
        isFirst = true;
        sendPortSubject.next(value as SendPort);
      } else {
        final message = Message.fromJson(jsonDecode(value));
        if (channelIdMapCallback.containsKey(message.channelId)) {
          channelIdMapCallback[message.channelId]!(message.data, (String str) {
            sendPort.send(jsonEncode(Message(data: str, channelId: message.channelId)));
          });
        }
      }
    });
    sendPort = await sendPortSubject.toPromise();
    return this;
  }

  Subscribe subscribe(Function(String message, Sender sender) callback) {
    final channelId = DateTime.now().microsecondsSinceEpoch;
    channelIdMapCallback[channelId] = callback;
    return Subscribe(
      unsubscribe: () {
        if (channelIdMapCallback.containsKey(channelId)) {
          channelIdMapCallback.remove(channelId);
        }
      },
      send: (String message) {
        if (channelIdMapCallback.containsKey(channelId)) {
          final data = Message(channelId: channelId, data: message);
          sendPort.send(jsonEncode(data));
        }
      },
    );
  }
}
