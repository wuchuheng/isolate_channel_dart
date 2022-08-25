// TODO: Put public facing types in this file.

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
      final Message message = messageJson;
      if (!idMapChannel.containsKey(message.channelId)) {
        final channel = Channel(
          name: message.name,
          channelId: message.channelId,
          close: () {
            if (idMapChannel.containsKey(message.channelId)) {
              isolateSendPort.send(Message(channelId: message.channelId, dataType: DataType.CLOSE, name: message.name));
              idMapChannel.remove(message.channelId);
            }
          },
          send: (String newMessage) {
            isolateSendPort.send(
              Message(channelId: message.channelId, dataType: DataType.DATA, data: newMessage, name: message.name),
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
      final message = value;
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

  Channel listen(Function(String message, Channel channel) callback, [String name = '']) {
    final channelId = DateTime.now().microsecondsSinceEpoch;
    channelIdMapCallback[channelId] = callback;
    final channel = Channel(
      name: name,
      channelId: channelId,
      close: () {
        if (channelIdMapCallback.containsKey(channelId)) {
          sendPort.send(Message(channelId: channelId, dataType: DataType.CLOSE, name: name));
          channelIdMapCallback.remove(channelId);
          idMapChannel.remove(channelId);
        }
      },
      send: (String message) {
        if (channelIdMapCallback.containsKey(channelId)) {
          final data = Message(channelId: channelId, data: message, dataType: DataType.DATA, name: name);
          sendPort.send(data);
        }
      },
    );
    idMapChannel[channelId] = channel;

    return idMapChannel[channelId]!;
  }
}
