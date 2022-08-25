import 'package:test/test.dart';
import 'package:wuchuheng_isolate_subject/src/dto/subscription/index.dart';
import 'package:wuchuheng_isolate_subject/wuchuheng_isolate_subject.dart';
import 'package:wuchuheng_logger/wuchuheng_logger.dart';

void main() {
  group('A group of tests', () {
    test('First Test', () async {
      final channel1Data = 'channel1Data';
      final channel2Data = 'channel2Data';
      final Task task = await IsolateTask((message, channel) {
        Logger.info('server: receive $message');
        channel.send('task data');
      });
      final Channel channel1 = task.listen((message, sender) {
        Logger.info('channel1: receive $message');
      });
      final Channel channel2 = task.listen((message, sender) {
        Logger.info('client2: receive $message');
      });
      channel1.send(channel1Data);
      channel2.send(channel2Data);

      await Future.delayed(Duration(seconds: 2));
    });
  });
}
