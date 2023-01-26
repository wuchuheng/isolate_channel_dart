import 'package:wuchuheng_isolate_channel/src/service/channel/channel_abstract.dart';

abstract class TaskAbstract<T> {
  ChannelAbstract<T> createChannel({required T name});
}
