import '../../dto/listen/index.dart';
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
  Listen listen(Function(String message, ChannelAbstract channel) callback);

  /// Trigger listening events.
  void onMessage(Message message);

  /// Listening for exceptions.
  void onError(Function(Exception e) callback);

  /// messages to Future.
  Future<String> listenToFuture();
}
