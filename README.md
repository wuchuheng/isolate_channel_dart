[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
<a href="https://github.com/wuchuheng/isolate_channel_dart/actions"><img src="https://github.com/wuchuheng/isolate_channel_dart/actions/workflows/tests.yaml/badge.svg" alt="Build Status"></a>


This a library to simplify islate thread communication. It abstracts the data transfer between islate and the main thread into a simple channel, and the channel only needs to listen for data changes and close the channel, thus simplifying the data communication of islate.

## Features

- channel abstraction.
- Data Listening.
- Message Channel Close event.

## Getting started

start using the package.

## Usage

```dart
import 'package:wuchuheng_isolate_channel/src/service/task/index.dart';
import 'package:wuchuheng_isolate_channel/wuchuheng_isolate_channel.dart';
import 'package:wuchuheng_logger/wuchuheng_logger.dart';

void main() async {
  /// Isolate logic code.
  final Task task = await IsolateTask((message, channel) {
    Logger.info('isolate: receive $message');
    channel.send('task data');
    channel.onClose((name) => Logger.info('Channel is closed. channel: $name.'));
  });

  ///Main thread code.
  final channel = task.createChannel(name: 'channelName')
    ..listen((message, channel) => Logger.info('Receiving isolate messages')).cancel();
  channel.send('Send data to isolate');
  await Future.delayed(Duration(seconds: 1));

  ///Turn off the channel
  channel.close();
}
```

## Additional information

contribute to the package, how to file issues, what response they can expect 
from the package authors, and more.
