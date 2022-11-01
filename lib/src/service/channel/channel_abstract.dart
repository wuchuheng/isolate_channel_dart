import 'package:wuchuheng_isolate_channel/src/main.dart';

import '../../dto/listen/listen.dart';
import '../../dto/message/index.dart';

abstract class ChannelAbstract {
  /// close the channel.
  void close();

  String get name;

  int get channelId;

  /// send the message to isolate
  void send(String message);

  /// close channel event.
  void onClose(Function(String name) callback);

  /// listening the message from channel.
  Listen listen(IsolateSubjectCallback callback);

  /// Trigger listening events.
  void onMessage(Message message);

  /// Listening for exceptions.
  void onError(Function(Exception e) callback);

  /// messages to Future.
  Future<String> listenToFuture();
}
