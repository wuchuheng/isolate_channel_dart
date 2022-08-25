import 'package:test/test.dart';
import 'package:wuchuheng_isolate_subject/src/dto/subscription/index.dart';
import 'package:wuchuheng_isolate_subject/wuchuheng_isolate_subject.dart';
import 'package:wuchuheng_logger/wuchuheng_logger.dart';

void main() {
  group('A group of tests', () {
    test('First Test', () async {
      final Task task = await IsolateTask((message, sender) {
        Logger.info('server: receive $message');
        sender('task data');
      });
      final Channel channel1 = task.listen((message, sender) {
        Logger.info('channel1: receive $message');
      });
      final Channel channel2 = task.listen((message, sender) {
        Logger.info('client2: receive $message');
      });
      channel1.send('channel1 data');
      channel2.send('channel2 data');

      await Future.delayed(Duration(seconds: 2));
    });
  });
}
