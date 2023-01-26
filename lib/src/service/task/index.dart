import 'dart:isolate';

import 'package:uuid/uuid.dart';
import 'package:wuchuheng_isolate_channel/src/service/channel/channel_abstract.dart';
import 'package:wuchuheng_isolate_channel/src/service/channel/isolate_channel.dart';
import 'package:wuchuheng_isolate_channel/src/service/task/index_abstract.dart';

class Task<T> implements TaskAbstract<T> {
  late SendPort sendPort;
  final ReceivePort receivePort;
  final Map<String, ChannelAbstract<T>> idMapChannel = {};

  Task(this.receivePort);

  @override
  ChannelAbstract<T> createChannel({required T name}) {
    final String id = Uuid().v4();
    idMapChannel[id] = IsolateChannel<T>(
      sendPort: sendPort,
      name: name,
      channelId: id,
    );
    idMapChannel[id]?.onClose((name) {
      if (idMapChannel.containsKey(id)) idMapChannel.remove(id);
    });

    return idMapChannel[id]!;
  }
}
