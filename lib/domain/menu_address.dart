import 'dart:math';

abstract final class MenuAddress {
  static String generate(String name) {
    var base = name.trim().toLowerCase();
    const accents = {
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
    };
    for (final entry in accents.entries) {
      base = base.replaceAll(entry.key, entry.value);
    }
    base = base.replaceAll(RegExp('[^a-z0-9]+'), '-');
    base = base.replaceAll(RegExp(r'^-+|-+$'), '');
    if (base.length > 50) {
      base = base.substring(0, 50).replaceAll(RegExp(r'-+$'), '');
    }
    if (base.isEmpty) {
      base = 'restaurante';
    }
    final random = Random.secure();
    final suffix = List.generate(
      8,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    return '$base-$suffix';
  }
}
