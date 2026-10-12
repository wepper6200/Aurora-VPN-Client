import 'dart:math';

final _rnd = Random.secure();

/// Short random identifier for locally created records (not a secret).
String newId() {
  final t = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final r = List.generate(6, (_) => _rnd.nextInt(36).toRadixString(36)).join();
  return '$t$r';
}
