import 'package:wuchuheng_isolate_subject/src/dto/listen/index.dart';
import 'package:wuchuheng_isolate_subject/src/dto/message/index.dart';

abstract class ChannelAbstract {
  /// close the channel.
  void close();

  String get name;

  /// send the message to isolate
  void send(String message);

  /// close channel event.
  void onClose(Function(String name) callback);

  /// listening the message from channel.
  Listen listen(Function(String message, ChannelAbstract channel) callback);

  /// Trigger listening events.
  void onMessage(Message message) {}
}
