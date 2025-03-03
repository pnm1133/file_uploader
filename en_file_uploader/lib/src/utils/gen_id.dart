import 'dart:math' as math;

/// now + a random int
String generateUniqueId() {
  final random = math.Random();
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final randomValue = random.nextInt(100000);
  return '$timestamp$randomValue';
}
