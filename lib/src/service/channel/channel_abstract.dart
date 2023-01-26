import 'package:wuchuheng_isolate_channel/src/main.dart';

import '../../dto/listen/listen.dart';
import '../../dto/message/index.dart';

abstract class ChannelAbstract<T> {
  /// close the channel.
  void close();

  T get name;

  String get channelId;

  /// send the message to isolate
  void send(dynamic message);

  /// close channel event.
  void onClose(Function(T name) callback);

  /// listening the message from channel.
  Listen listen(IsolateSubjectCallback<T> callback);

  /// Trigger listening events.
  void onMessage(Message message);

  /// Listening for exceptions.
  void onError(Function(Exception e) callback);

  /// messages to Future.
  Future<String> listenToFuture();
}
