import 'dart:async';

import 'package:test/test.dart';
import 'package:wuchuheng_isolate_subject/src/dto/subscription/index.dart';
import 'package:wuchuheng_isolate_subject/src/util/subject_hook.dart';
import 'package:wuchuheng_isolate_subject/wuchuheng_isolate_subject.dart';
import 'package:wuchuheng_logger/wuchuheng_logger.dart';

void main() {
  group('A group of tests', () {
    test('Data transfer Test', () async {
      final Task task = await IsolateTask((message, Channel channel) {
        Logger.info('channel name: ${channel.name}');
        Logger.info('server: receive $message');
        channel.send('task data');
      });
      final channel = task.listen((message, channel) {
        expect(message, 'task data');
      }, 'task');
      channel.send('channelData');
      await Future.delayed(Duration(seconds: 1));
    }, timeout: Timeout(Duration(seconds: 100)));
    test('close event Test', () async {
      final Task task = await IsolateTask((message, channel) {
        Logger.info('server: receive $message');
        channel.close();
      });
      final channel = task.listen((message, channel) {});
      channel.send('channelData');
      final subject = SubjectHook<bool>();
      channel.onClose(() => subject.next(true));
      expect(await subject.toPromise(), true);
      await Future.delayed(Duration(seconds: 1));
    }, timeout: Timeout(Duration(seconds: 100)));
    test('Logic segregation Test', () async {
      final Task task = await IsolateTask(compute);
      final channel = task.listen((message, channel) {});
      channel.send('channelData');
      final subject = SubjectHook<bool>();
      channel.onClose(() => subject.next(true));
      expect(await subject.toPromise(), true);
      await Future.delayed(Duration(seconds: 1));
    }, timeout: Timeout(Duration(seconds: 100)));
  });
}

void compute(String message, Channel channel) {
  Logger.info('server: receive $message');
  channel.close();
}
