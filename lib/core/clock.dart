import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single time source for everything user-visible (session timer, log
/// timestamps). Uses `package:clock`, so widget tests get fake time for free;
/// golden tests override it with a fixed origin.
final nowProvider = Provider<DateTime Function()>((ref) => clock.now);
