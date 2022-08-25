import '../channel/index.dart';

abstract class TaskAbstract {
  Channel createChannel({String name = ''});
}
