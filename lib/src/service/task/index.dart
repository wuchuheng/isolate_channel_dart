import 'dart:isolate';

import 'package:wuchuheng_isolate_subject/src/service/task/index_abstract.dart';

import '../channel/index.dart';

class Task implements TaskAbstract {
  late SendPort sendPort;
  final ReceivePort receivePort;
  final Map<int, Channel> idMapChannel = {};

  Task(this.receivePort);

  @override
  Channel createChannel({String name = ''}) {
    final id = DateTime.now().microsecondsSinceEpoch;
    idMapChannel[id] = Channel(
        sendPort: sendPort,
        name: name,
        channelId: id,
        close: () {
          if (idMapChannel.containsKey(id)) idMapChannel.remove(id);
        });

    return idMapChannel[id]!;
  }
}
