// Created by Crt Vavros, copyright © 2022 ZeroPass. All rights reserved.
import 'dart:convert';
import 'dart:core';
import 'dart:typed_data';
import 'package:convert/convert.dart';

extension StringDecodeApis on String {
  Uint8List parseBase64() {
    return base64.decode(this);
  }

  Uint8List parseHex() {
    return hex.decoder.convert(this);
  }
}

extension StringYYMMDDateApi on String {
  DateTime parseDateYYMMDD({bool futureDate = false}) {
    if (length < 6) {
      throw FormatException("Invalid length of compact date string");
    }

    final yy = int.tryParse(substring(0, 2));
    final m = int.tryParse(substring(2, 4));
    final d = int.tryParse(substring(4, 6));
    if (yy == null || yy < 0 || m == null || d == null) {
      throw FormatException("Non-numeric characters in compact date string");
    }
    if (m < 1 || m > 12 || d < 1 || d > 31) {
      throw FormatException("Invalid calendar date in compact date string");
    }
    int y = yy + 2000;

    final now = DateTime.now();
    int maxYear = now.year;
    int maxMonth = now.month;
    if (futureDate) {
      maxYear += 20; // cut off year 20 years from now
      maxMonth += 5;
    }

    // If parsed year is greater than max wind back for 100 years
    if (y > maxYear || (y == maxYear && maxMonth < m)) {
      y -= 100;
    }

    // DateTime silently rolls over invalid dates (e.g. Feb 30 -> Mar 2),
    // verify constructed date round-trips.
    final date = DateTime(y, m, d);
    if (date.year != y || date.month != m || date.day != d) {
      throw FormatException("Invalid calendar date in compact date string");
    }
    return date;
  }

  DateTime parseDate({bool futureDate = false}) {
    if (length == 6) {
      return this.parseDateYYMMDD(futureDate: futureDate);
    } else {
      final date = DateTime.parse(this);
      // DateTime.parse silently rolls over invalid calendar dates
      // (e.g. 20230231 -> 20230303), verify yyyymmdd dates round-trip.
      if (RegExp(r'^\d{8}').hasMatch(this)) {
        final y = int.parse(substring(0, 4));
        final m = int.parse(substring(4, 6));
        final d = int.parse(substring(6, 8));
        if (date.year != y || date.month != m || date.day != d) {
          throw FormatException("Invalid calendar date string");
        }
      }
      return date;
    }
  }
}
