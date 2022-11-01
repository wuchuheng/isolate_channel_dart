import 'dart:isolate';

import 'package:wuchuheng_isolate_channel/src/service/channel/channel_abstract.dart';
import 'package:wuchuheng_isolate_channel/src/service/channel/isolate_channel.dart';
import 'package:wuchuheng_isolate_channel/src/service/task/index_abstract.dart';

class Task implements TaskAbstract {
  late SendPort sendPort;
  final ReceivePort receivePort;
  final Map<int, ChannelAbstract> idMapChannel = {};

  Task(this.receivePort);

  @override
  ChannelAbstract createChannel({String name = ''}) {
    final id = DateTime.now().microsecondsSinceEpoch;
    idMapChannel[id] = IsolateChannel(
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
