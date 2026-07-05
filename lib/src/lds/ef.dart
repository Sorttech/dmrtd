//  Created by Crt Vavros, copyright © 2022 ZeroPass. All rights reserved.
import 'dart:typed_data';
import 'package:meta/meta.dart';

import 'mrz.dart';
import 'tlv.dart';

class EfParseError implements Exception {
  final String message;
  EfParseError(this.message);
  @override
  String toString() => message;
}

abstract class ElementaryFile {
  int get fid; // file id
  int get sfi; // short file id
  final Uint8List _encoded;

  ElementaryFile.fromBytes(final Uint8List data) : _encoded = data {
    // Data comes from an untrusted chip so make sure that anything thrown
    // while parsing (e.g. RangeError, TypeError, FormatException) surfaces
    // as one of the library's typed exceptions.
    try {
      parse(data);
    } on EfParseError {
      rethrow;
    } on TLVError {
      rethrow;
    } on MRZParseError {
      rethrow;
    } catch (e) {
      throw EfParseError("Failed to parse file: $e");
    }
  }

  Uint8List toBytes() {
    return _encoded;
  }

  @protected
  void parse(final Uint8List content);
}
