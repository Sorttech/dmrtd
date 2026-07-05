//  Copyright © 2020 ZeroPass. All rights reserved.
import 'dart:math';
import 'dart:typed_data';

Uint8List randomBytes(int length) {
  final random = Random.secure();
  var intBytes = List<int>.generate(length, (i) => random.nextInt(256));
  return Uint8List.fromList(intBytes);
}

/// Compares byte lists [a] and [b] in constant time (no early exit on the
/// first differing byte) to avoid leaking information through timing side
/// channels. Returns true if both have the same length and content.
bool constantTimeEquals(final List<int> a, final List<int> b) {
  if (a.length != b.length) {
    return false;
  }
  var diff = 0;
  for (int i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
