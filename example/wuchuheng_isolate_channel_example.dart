import 'package:wuchuheng_isolate_channel/src/service/task/index.dart';
import 'package:wuchuheng_isolate_channel/wuchuheng_isolate_channel.dart';

void main() async {
  /// Isolate logic code.
  final Task task = await IsolateTask((message, channel) async {
    print("isolate: receive $message");
    channel.send('task data');
    channel.onClose((name) => print('Channel is closed. channel: $name.'));
  });

  ///Main thread code.
  final channel = task.createChannel(name: 'channelName')
    ..listen((message, channel) async => print('Receiving isolate messages')).cancel();
  channel.send('Send data to isolate');
  await Future.delayed(Duration(seconds: 1));

  ///Turn off the channel
  channel.close();

  /// listen to future
  final task2 = await IsolateTask((message, channel) async {
    print(message); //  print: Are you OK? Isolate task
    channel.send('Nice!');
  });
  final channel2 = task2.createChannel();
  final result = channel2.listenToFuture();
  channel2.send('Are you OK? Isolate task');
  print(await result); // print: Nice!
}
