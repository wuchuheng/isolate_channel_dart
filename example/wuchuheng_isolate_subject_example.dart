import 'package:wuchuheng_isolate_subject/wuchuheng_isolate_subject.dart';
import 'package:wuchuheng_logger/wuchuheng_logger.dart';

void main() async {
  /// Isolate logic code.
  final Task task = await IsolateTask((message, channel) {
    Logger.info('isolate: receive $message');
    channel.send('task data');
    channel.onClose(() {});
  });

  ///Main thread code.
  final channel = task.createChannel((message, channel) {
    Logger.info('The data from isolate logic: $message');
  });
  channel.send('Send data to isolate');

  ///

  await Future.delayed(Duration(seconds: 1));
}
