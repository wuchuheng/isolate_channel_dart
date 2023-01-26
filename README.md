<div align="center">
    <h1>wuchuheng_isolate_channel</h1>
    <a href="https://github.com/wuchuheng/isolate_channel_dart"><img src="https://badgen.net/badge/Licence/MIT/green" alt="wuchuheng_isolate_channel" /></a>
    <a href="https://github.com/wuchuheng/isolate_channel_dart"><img alt="wuchuheng_isolate_channel" src="https://badgen.net/github/stars/wuchuheng/isolate_channel_dart?icon=github&color=green"></a>
    <a href="https://github.com/wuchuheng/isolate_channel_dart/actions"><img src="https://github.com/wuchuheng/isolate_channel_dart/actions/workflows/tests.yaml/badge.svg" alt="Build Status"></a>
    <a href="https://pub.dev/packages/wuchuheng_isolate_channel"><img alt="wuchuheng_isolate_channel" src="https://badgen.net/pub/v/wuchuheng_isolate_channel?color=green" /></a>
    <a href="https://badgen.net/pub/likes/wuchuheng_isolate_channel"><img alt="wuchuheng_isolate_channel" src="https://badgen.net/pub/likes/wuchuheng_isolate_channel" /></a>
    <a href="https://badgen.net/pub/flutter-platform/wuchuheng_isolate_channel"><img alt="wuchuheng_isolate_channel" src="https://badgen.net/pub/flutter-platform/wuchuheng_isolate_channel"></a>
</div>


This a library to simplify isolate thread communication. It abstracts the data transfer between isolate and the main thread into a simple channel, and the channel only needs to listen for data changes and close the channel, thus simplifying the data communication of islate.

## Features

- channel abstraction.
- Data Listening.
- Message Channel Close event.

## Getting started
Depend on it
Run this command:
With Dart:
``` bash 
$ dart pub add wuchuheng_isolate_channel
```
With Flutter:
``` bash 
$ flutter pub add wuchuheng_isolate_channel
```

## Usage

```dart
import 'package:wuchuheng_isolate_channel/src/service/task/index.dart';
import 'package:wuchuheng_isolate_channel/wuchuheng_isolate_channel.dart';

enum ChannelName { channel1, channel2, channel3, channel4 }

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
  final task2 = await IsolateTask<ChannelName>((message, channel) async {
    print(message); //  print: Are you OK? Isolate task
    channel.send('Nice!');
  });
  final channel2 = task2.createChannel(name: ChannelName.channel1);
  final result = channel2.listenToFuture();
  channel2.send('Are you OK? Isolate task');
  print(await result); // print: Nice!
}
```

## Additional information

contribute to the package, how to file issues, what response they can expect 
from the package authors, and more.
