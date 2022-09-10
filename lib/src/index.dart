import 'dart:isolate';

import 'package:wuchuheng_hooks/wuchuheng_hooks.dart';

import 'dto/message/index.dart';
import 'service/channel/index.dart';
import 'service/channel/index_abstract.dart';
import 'service/task/index.dart';

typedef Sender = Function(String message);
typedef IsolateSubjectCallback = Future Function(String message, ChannelAbstract channel);

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
          sendPort: isolateSendPort,
          name: message.name,
          channelId: message.channelId,
          close: () {
            if (idMapChannel.containsKey(message.channelId)) idMapChannel.remove(message.channelId);
          },
        );
        channel.listen(callback);
        idMapChannel[message.channelId] = channel;
      }
      final Channel channel = idMapChannel[message.channelId]!;
      channel.onMessage(message);
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
      final Message message = value;
      if (task.idMapChannel.containsKey(message.channelId)) {
        task.idMapChannel[message.channelId]!.onMessage(message);
      }
    }
  });
  task.sendPort = await sendPortSubject.toFuture();
  return task;
}
