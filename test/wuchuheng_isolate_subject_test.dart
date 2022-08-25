import 'package:test/test.dart';
import 'package:wuchuheng_isolate_subject/wuchuheng_isolate_subject.dart';
import 'package:wuchuheng_logger/wuchuheng_logger.dart';

void main() {
  group('A group of tests', () {
    test('First Test', () async {
      final Subject subject = await isolateSubject((message, sender) {
        Logger.info('server: receive $message');
        sender('from sever');
      });
      final client1 = subject.subscribe((message, sender) {
        Logger.info('client: receive $message');
        // sender('from client !');
      });
      client1.send('hello');

      await Future.delayed(Duration(seconds: 10));
    });
  });
}
