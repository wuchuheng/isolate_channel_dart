import 'dart:isolate';

import 'package:wuchuheng_hooks/wuchuheng_hooks.dart';
import 'package:wuchuheng_isolate_channel/src/service/channel/isolate_channel.dart';

import 'dto/message/index.dart';
import 'service/channel/channel_abstract.dart';
import 'service/task/index.dart';

typedef Sender = Function(String message);
typedef IsolateSubjectCallback<T> = Future Function(dynamic message, ChannelAbstract<T> channel);

Future<Task<T>> IsolateTask<T extends Enum>(IsolateSubjectCallback<T> callback) async {
  ReceivePort receivePort = ReceivePort();
  Isolate.spawn<SendPort>((SendPort isolateSendPort) async {
    ReceivePort isolateReceivePort = ReceivePort();
    isolateSendPort.send(isolateReceivePort.sendPort);
    Map<String, IsolateChannel<T>> idMapChannel = {};
    await for (var messageJson in isolateReceivePort) {
      final Message message = messageJson;
      if (!idMapChannel.containsKey(message.channelId)) {
        final channel = IsolateChannel<T>(
          sendPort: isolateSendPort,
          name: message.name,
          channelId: message.channelId,
        );
        channel.listen(callback);
        idMapChannel[message.channelId] = channel;
      }
      final IsolateChannel<T> channel = idMapChannel[message.channelId]!;
      channel.onMessage(message);
      channel.onClose((name) {
        if (idMapChannel.containsKey(message.channelId)) idMapChannel.remove(message.channelId);
      });
    }
  }, receivePort.sendPort);

  final Task<T> task = Task<T>(receivePort);
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
