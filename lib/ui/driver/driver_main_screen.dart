import 'package:drup/core/animation/custom_transition.dart';
import 'package:flutter/material.dart';

class DriverMainScreen extends StatefulWidget {
  const DriverMainScreen({super.key, required this.child, this.currentRoute});
  final Widget child;
  final String? currentRoute;

  static Page page({
    LocalKey? key,
    required Widget child,
    String? currentRoute,
  }) {
    return CustomPageTransition(
      key: key,
      transitionStyle: PageTransitionStyle.fade,
      child: DriverMainScreen(currentRoute: currentRoute, child: child),
    );
  }

  @override
  State<DriverMainScreen> createState() => _DriverMainScreenState();
}

class _DriverMainScreenState extends State<DriverMainScreen> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
