import 'package:flutter/material.dart';

extension MediaExtension on BuildContext {
  Size screenSize() => MediaQuery.of(this).size;
}

extension IntSizedBoxExtension on num {
  SizedBox height() {
    return SizedBox(height: toDouble());
  }

  SizedBox width() {
    return SizedBox(width: toDouble());
  }
}

extension StringExtension on String {
  //to capitalize first letter of the string/sentence.
  String get capitalize =>
      (isNotEmpty) ? "${this[0].toUpperCase()}${substring(1)}" : "";

  //to capitalize every first letter of each word in string/sentence.
  String get cap =>
      split(" ").map((str) => (str.isNotEmpty) ? str.capitalize : "").join(" ");

  String ellipsis({int? max = 19}) {
    if (length > max!) {
      final getFirst14String = substring(0, max);
      return '$getFirst14String...';
    }
    return this;
  }
}
