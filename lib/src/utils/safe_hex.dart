import 'dart:typed_data';

String _toHex(dynamic v) {
  if (v == null) return '';
  if (v is ByteBuffer) {
    return _toHex(v.asUint8List());
  }
  if (v is ByteData) {
    return _toHex(v.buffer.asUint8List(v.offsetInBytes, v.lengthInBytes));
  }
  if (v is Iterable<int>) {
    final sb = StringBuffer();
    for (final b in v) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }
  return v.toString();
}

String safeHex(Object? v) => _toHex(v);
