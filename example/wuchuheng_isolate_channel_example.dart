import 'package:wuchuheng_isolate_channel/src/service/task/index.dart';
import 'package:wuchuheng_isolate_channel/wuchuheng_isolate_channel.dart';
import 'package:wuchuheng_logger/wuchuheng_logger.dart';

void main() async {
  /// Isolate logic code.
  final Task task = await IsolateTask((message, channel) async {
    Logger.info('isolate: receive $message');
    channel.send('task data');
    channel.onClose((name) => Logger.info('Channel is closed. channel: $name.'));
  });

  ///Main thread code.
  final channel = task.createChannel(name: 'channelName')
    ..listen((message, channel) async => Logger.info('Receiving isolate messages')).cancel();
  channel.send('Send data to isolate');
  await Future.delayed(Duration(seconds: 1));

  ///Turn off the channel
  channel.close();

  /// listen to future
  final task2 = await IsolateTask((message, channel) async {
    channel.send(message);
  });
  final channel2 = task2.createChannel();
  final result = channel2.listenToFuture();
  channel.send('OK');
  print(await result); // print 2
}
