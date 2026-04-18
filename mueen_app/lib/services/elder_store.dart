import '../models/elder.dart';

class ElderStore {
  static final List<Elder> _elders = [];

  static void addElder(Elder elder) {
    _elders.add(elder);
  }

  static List<Elder> getElders() {
    return List.unmodifiable(_elders);
  }

  static void clear() {
    _elders.clear();
  }
}
