//all available fonts
import 'package:flutter/material.dart';

class Fonts {
  static const String redHatDisplay = 'RedHatDisplay';
  static const String montserrat = 'Montserrat';
}

class TextStyles {
  static const TextStyle redHatDisplay = TextStyle(
    fontFamily: Fonts.redHatDisplay,
    fontWeight: FontWeight.w400,
    letterSpacing: .5,
  );

  static const TextStyle montserrat = TextStyle(
    fontFamily: Fonts.montserrat,
    fontWeight: FontWeight.w700,
    letterSpacing: .5,
  );

  static TextStyle get appTitle => _createTextStyle(
    style: redHatDisplay,
    weight: FontWeight.w900,
    fontSize: FontSizes.s36,
  );

  static TextStyle get appTitle1 => _createTextStyle(
    style: redHatDisplay,
    weight: FontWeight.bold,
    fontSize: FontSizes.s20,
    height: .5,
  );

  static TextStyle get t1 => _createTextStyle(
    style: redHatDisplay,
    fontSize: FontSizes.s20,
    weight: FontWeight.w600,
    letterSpacing: -.32,
  );

  static TextStyle get t2 => _createTextStyle(
    style: redHatDisplay,
    weight: FontWeight.w500,
    fontSize: FontSizes.s16,
    letterSpacing: -.32,
  );

  static TextStyle get t3 => _createTextStyle(
    style: redHatDisplay,
    fontSize: FontSizes.s14,
    weight: FontWeight.w500,
    letterSpacing: -.32,
  );

  static TextStyle get h1 => _createTextStyle(
    style: redHatDisplay,
    weight: FontWeight.w500,
    fontSize: FontSizes.s28,
  );

  static TextStyle get h2 =>
      _createTextStyle(style: redHatDisplay, fontSize: FontSizes.s24);

  static TextStyle get h3 =>
      _createTextStyle(style: redHatDisplay, fontSize: FontSizes.s18);

  static TextStyle get h4 => _createTextStyle(
    style: redHatDisplay,
    letterSpacing: -.5,
    fontSize: FontSizes.s16,
  );

  static TextStyle get body1 =>
      _createTextStyle(style: redHatDisplay, fontSize: FontSizes.s14);

  static TextStyle get body2 =>
      _createTextStyle(style: redHatDisplay, fontSize: FontSizes.s12);

  static TextStyle get body3 =>
      _createTextStyle(style: redHatDisplay, fontSize: FontSizes.s11);

  static TextStyle get callout => _createTextStyle(
    style: redHatDisplay,
    fontSize: FontSizes.s14,
    letterSpacing: 1.75,
  );

  static TextStyle get calloutFocus => _createTextStyle(
    style: callout,
    weight: FontWeight.bold,
    fontSize: FontSizes.s14,
  );

  static TextStyle get btnStyle => _createTextStyle(
    style: redHatDisplay,
    weight: FontWeight.w600,
    fontSize: FontSizes.s16,
  );

  static TextStyle get caption => _createTextStyle(
    style: redHatDisplay,
    fontSize: FontSizes.s14,
    weight: FontWeight.w300,
    letterSpacing: .3,
  );

  static TextStyle _createTextStyle({
    required TextStyle style,
    required double fontSize,
    FontWeight? weight,
    double? letterSpacing,
    double? height,
  }) {
    return style.copyWith(
      fontSize: fontSize,
      fontWeight: weight ?? style.fontWeight,
      letterSpacing: letterSpacing ?? style.letterSpacing,
      height: height ?? style.height,
    );
  }
}

class FontSizes {
  static double s8 = 8;

  static double s10 = 10;

  static double s11 = 11;

  static double s12 = 12;

  static double s13 = 13;

  static double s14 = 14;

  static double s15 = 15;

  static double s17 = 17;

  static double s16 = 16;

  static double s18 = 18;

  static double s20 = 20;

  static double s22 = 22;

  static double s24 = 24;

  static double s28 = 28;

  static double s30 = 30;

  static double s36 = 36;

  static double s40 = 40;

  static double s48 = 48;
}
