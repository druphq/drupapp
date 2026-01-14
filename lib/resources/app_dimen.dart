class PageBreaks {
  static double get largePhone => 550;
  static double get tabletPortrait => 800;
  static double get tabletLandscape => 1024;
  static double get desktop => 1440;
}

class BreakPoints {
  static const double start = 0;
  static const double mobile = 450;
  static const double tablet = 800;
  static const double desktop = 1920;
}

class Sizes {
  static double get sm => 16;
  static double get md => 20;
  static double get lg => 25;
  static double get vlg => 40;
  static double get tfieldHeight => 50;
  /////////////////////////////////
  static double get sideBarSm => 150;
  static double get sideBarMd => 200;
  static double get sideBarLg => 290;

  /////////////////////////////////
  static double get bottonNavHeight => 70;
  static double get bottomNavIconSize => 20;
  static double get toolBarHeigth => 70;
  static double get iconSizeMd => 24;
  static double get btnWidthMd => 350;
  static double get btnHeightMd => 60;

  static double get flexibleTopPadding => 80.0;

  static double get flexibleHeight => 250;
}

class DurationsConfig {
  static const Duration fastest = Duration(milliseconds: 150);
  static const Duration fast = Duration(milliseconds: 250);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 1000);
  static const Duration pageTransition = Duration(microseconds: 200);
  static const Duration verySlow = Duration(microseconds: 1200);
}

class Corners {
  static const double vsm = 3.0;
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double mmd = 10.0;
  static const double hMd = 20.0;
  static const double lg = 30.0;
  static const double vLg = 40.0;
  static const double vvLg = 60.0;
}
