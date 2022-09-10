import 'dart:async';
import 'package:test/test.dart';
import 'package:wuchuheng_hooks/wuchuheng_hooks.dart';
import 'package:wuchuheng_isolate_channel/src/service/task/index.dart';
import 'package:wuchuheng_isolate_channel/wuchuheng_isolate_channel.dart';
import 'package:wuchuheng_logger/wuchuheng_logger.dart';

void main() {
  group('A group of tests', () {
    test('Data transfer Test', () async {
      final Task task = await IsolateTask((message, channel) async {
        Logger.info('channel name: ${channel.name}');
        Logger.info('server: receive $message');
        channel.send('task data');
      });

      task.createChannel(name: 'channel1')
        ..listen((message, channel) async => expect(message, 'task data')).cancel()
        ..send('channelData');

      await Future.delayed(Duration(seconds: 1));
    }, timeout: Timeout(Duration(seconds: 100)));
    test('close event Test', () async {
      final Task task = await IsolateTask((message, channel) async {
        Logger.info('server: receive $message');
        channel.close();
      });
      final channel = task.createChannel()..listen((message, channel) async => Logger.info(message));
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
    test('Main thread listens for exceptions Test', () async {
      final Task task = await IsolateTask((message, channel) async {
        if (channel.name == 'channel1') {
          throw Exception('channel exception');
        }
      });
      final channel1 = task.createChannel(name: 'channel1');
      bool isThrowError = false;
      channel1.onError((e) {
        Logger.info(e.toString());
        isThrowError = true;
      });
      final channel2 = task.createChannel(name: 'channel2');
      channel2.send('channel2 data');
      channel1.send('channel1 data');
      await Future.delayed(Duration(seconds: 2));
      expect(isThrowError, true);
    }, timeout: Timeout(Duration(seconds: 3)));
    test('ToFuture test', () async {
      final task = await IsolateTask((message, channel) async {
        channel.send(message);
      });
      final channel = task.createChannel();
      final result = channel.listenToFuture();
      channel.send('OK');
      await Future.delayed(Duration(seconds: 3));
      expect(await result, 'OK');
    });
    test('Exception Test', () async {
      Exception? exception;

      final Task task = await IsolateTask((message, channel) {
        throw Exception('error');
      });
      task.createChannel()
        ..send('')
        ..onError((e) {
          exception = e;
        });
      await Future.delayed(Duration(seconds: 1));
      expect(exception != null, isTrue);
    });
  });
}

Future compute(String message, channel) async {
  Logger.info('server: receive $message');
  channel.close();
}
