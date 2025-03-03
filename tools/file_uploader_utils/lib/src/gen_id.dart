import 'dart:math' as math;

/// now + a random int
String generateUniqueId() {
  final random = math.Random();
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final randomValue = random.nextInt(100000);
  return '$timestamp$randomValue';
}

/// Generates a unique ID with customizable prefix and/or suffix
String generateCustomUniqueId({String prefix = '', String suffix = ''}) {
  final random = math.Random();
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final randomValue = random.nextInt(10000);
  return '$prefix$timestamp$randomValue$suffix';
}

/// Generates a shorter unique ID (useful for URLs or display)
String generateShortUniqueId({int length = 8}) {
  final random = math.Random();
  final chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ),
  );
}

/// Generates a unique ID with specified format
/// Use # for digits, @ for letters, and * for either
String generateFormattedUniqueId(String format) {
  final random = math.Random();
  final chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
  final digits = '0123456789';
  final alphanumeric = chars + digits;

  return format.splitMapJoin(
    RegExp(r'[#@*]'),
    onMatch: (match) {
      switch (match[0]) {
        case '#':
          return digits[random.nextInt(digits.length)];
        case '@':
          return chars[random.nextInt(chars.length)];
        case '*':
          return alphanumeric[random.nextInt(alphanumeric.length)];
        default:
          return '';
      }
    },
    onNonMatch: (s) => s,
  );
}
