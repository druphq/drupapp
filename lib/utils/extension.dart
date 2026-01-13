import 'package:flutter/material.dart';

extension AppContext on BuildContext {
  //returns device width
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;
}