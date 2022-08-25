import 'dart:async';

import 'package:test/test.dart';
import 'package:wuchuheng_hooks/wuchuheng_hooks.dart';
import 'package:wuchuheng_isolate_channel/src/service/task/index.dart';
import 'package:wuchuheng_isolate_channel/wuchuheng_isolate_channel.dart';
import 'package:wuchuheng_logger/wuchuheng_logger.dart';

void main() {
  group('A group of tests', () {
    test('Data transfer Test', () async {
      final Task task = await IsolateTask((message, channel) {
        Logger.info('channel name: ${channel.name}');
        Logger.info('server: receive $message');
        channel.send('task data');
      });

      task.createChannel(name: 'channel1')
        ..listen((message, channel) => expect(message, 'task data')).cancel()
        ..send('channelData');

      await Future.delayed(Duration(seconds: 1));
    }, timeout: Timeout(Duration(seconds: 100)));
    test('close event Test', () async {
      final Task task = await IsolateTask((message, channel) {
        Logger.info('server: receive $message');
        channel.close();
      });
      final channel = task.createChannel()..listen((message, channel) => Logger.info(message));
      channel.send('channelData');
      final subject = SubjectHook<bool>();
      channel.onClose((name) => subject.next(true));
      expect(await subject.toFuture(), true);
      await Future.delayed(Duration(seconds: 1));
    }, timeout: Timeout(Duration(seconds: 100)));
    test('Logic segregation Test', () async {
      final Task task = await IsolateTask(compute);
      final channel = task.createChannel()..send('channelData');
      final subject = SubjectHook<bool>();
      channel.onClose((name) => subject.next(true));
      expect(await subject.toFuture(), true);
      await Future.delayed(Duration(seconds: 1));
    }, timeout: Timeout(Duration(seconds: 100)));
  });
}

void compute(String message, channel) {
  Logger.info('server: receive $message');
  channel.close();
}
