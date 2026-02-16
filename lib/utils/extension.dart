import 'package:flutter/material.dart';

extension AppContext on BuildContext {
  //returns device width
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;
}

extension StringUtils on String {
  // Extracts the first name from a full name string
  String get takeFirst {
    if (isEmpty) return '';
    return split(' ').first;
  }

  String capitalizeFirstChar() {
    if (isEmpty) return '';
    return this[0].toUpperCase() + substring(1);
  }
}

extension NullableStringUtils on String? {
  // Check if not empty or null
  bool get isNotEmptyOrNull => this != null && this!.isNotEmpty;
}
