// TODO: Put public facing types in this file.

import 'dart:convert';
import 'dart:isolate';

import 'package:wuchuheng_isolate_subject/src/dto/message/index.dart';
import 'package:wuchuheng_isolate_subject/src/util/subject_hook.dart';

import 'dto/subscription/index.dart';

typedef Sender = Function(String message);
typedef IsolateSubjectCallback = Function(
  String message,
  Channel channel,
);

Future<Task> IsolateTask(IsolateSubjectCallback callback) async {
  ReceivePort receivePort = ReceivePort();
  Isolate.spawn<SendPort>((SendPort isolateSendPort) async {
    ReceivePort isolateReceivePort = ReceivePort();
    isolateSendPort.send(isolateReceivePort.sendPort);
    Map<int, Channel> idMapChannel = {};
    await for (var messageJson in isolateReceivePort) {
      final message = Message.fromJson(jsonDecode(messageJson));
      if (!idMapChannel.containsKey(message.channelId)) {
        final channel = Channel(
          channelId: message.channelId,
          close: () {
            if (idMapChannel.containsKey(message.channelId)) {
              isolateSendPort.send(jsonEncode(Message(channelId: message.channelId, dataType: DataType.CLOSE)));
              idMapChannel.remove(message.channelId);
            }
          },
          send: (String newMessage) {
            isolateSendPort.send(
              jsonEncode(
                Message(channelId: message.channelId, dataType: DataType.DATA, data: newMessage),
              ),
            );
          },
        );
        idMapChannel[message.channelId] = channel;
      }
      final Channel channel = idMapChannel[message.channelId]!;
      if (message.dataType == DataType.DATA) {
        callback(message.data, channel);
      } else {
        for (var callback in channel.onCloseCallbackList) {
          callback();
        }
        idMapChannel.remove(message.channelId);
      }
    }
  }, receivePort.sendPort);

  final Task task = Task(receivePort);
  bool isFirst = false;
  final sendPortSubject = SubjectHook<SendPort>();
  task.receivePort.listen((value) {
    if (!isFirst) {
      isFirst = true;
      sendPortSubject.next(value as SendPort);
    } else {
      final message = Message.fromJson(jsonDecode(value));
      if (task.channelIdMapCallback.containsKey(message.channelId)) {
        final channel = task.idMapChannel[message.channelId]!;
        switch (message.dataType) {
          case DataType.CLOSE:
            for (var callback in channel.onCloseCallbackList) {
              callback();
            }
            task.channelIdMapCallback.remove(message.channelId);
            break;
          case DataType.DATA:
            task.channelIdMapCallback[message.channelId]!(message.data, channel);
            break;
        }
      }
    }
  });
  task.sendPort = await sendPortSubject.toPromise();
  return task;
}

class Task {
  late SendPort sendPort;
  final ReceivePort receivePort;
  final Map<int, Function(String message, Channel channel)> channelIdMapCallback = {};
  final Map<int, Channel> idMapChannel = {};

  Task(this.receivePort);

  Channel listen(Function(String message, Channel channel) callback) {
    final channelId = DateTime.now().microsecondsSinceEpoch;
    channelIdMapCallback[channelId] = callback;
    final channel = Channel(
      channelId: channelId,
      close: () {
        if (channelIdMapCallback.containsKey(channelId)) {
          channelIdMapCallback.remove(channelId);
          final data = Message(
            channelId: channelId,
            dataType: DataType.CLOSE,
          );
          sendPort.send(jsonEncode(data));
          idMapChannel.remove(channelId);
        }
      },
      send: (String message) {
        if (channelIdMapCallback.containsKey(channelId)) {
          final data = Message(channelId: channelId, data: message, dataType: DataType.DATA);
          sendPort.send(jsonEncode(data));
        }
      },
    );
    idMapChannel[channelId] = channel;

    return idMapChannel[channelId]!;
  }
}
