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
}
