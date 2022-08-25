import 'package:test/test.dart';
import 'package:wuchuheng_isolate_subject/src/dto/subscription/index.dart';
import 'package:wuchuheng_isolate_subject/wuchuheng_isolate_subject.dart';
import 'package:wuchuheng_logger/wuchuheng_logger.dart';

void main() {
  group('A group of tests', () {
    test('First Test', () async {
      final Task task = await IsolateTask((message, sender) {
        Logger.info('server: receive $message');
        sender('from sever');
      });
      final Channel channel1 = task.listen((message, sender) {
        Logger.info('client: receive $message');
      });
      channel1.send('hello');

      await Future.delayed(Duration(seconds: 10));
    });
  });
}
