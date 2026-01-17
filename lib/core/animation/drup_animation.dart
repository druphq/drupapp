import 'package:drup/resources/app_assets.dart';
import 'package:flutter/material.dart';

class DrupLogoAnimation extends StatefulWidget {
  const DrupLogoAnimation({super.key, this.isDriver = false});
  final bool isDriver;

  @override
  DrupLogoAnimationState createState() => DrupLogoAnimationState();
}

class DrupLogoAnimationState extends State<DrupLogoAnimation>
    with TickerProviderStateMixin {
  late AnimationController _logoController;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Adjust duration as needed
    );
    _logoController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ImageIcon(
          AssetImage(AppAssets.drupLogoIcon),
          size: 70,
          color: Colors.white,
        ),
        // Animated Drup text logo sliding out from the logo icon
        SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(-0.5, 0), // Start from logo position
                end: const Offset(0, 0), // End position (next to logo)
              ).animate(
                CurvedAnimation(
                  parent: _logoController,
                  curve: const Interval(
                    0.3,
                    0.8,
                    curve: Curves.easeOutBack,
                  ), // Animation curve with bounce
                ),
              ),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _logoController,
                curve: const Interval(0.3, 0.6, curve: Curves.easeIn),
              ),
            ),
            child: Image.asset(
              AppAssets.drupTextIcon,
              height: 50,
              width: 120,
              fit: BoxFit.fill,
              color: Colors.white,
            ),
          ),

          // ScaleTransition(
          //   scale:
          //       Tween<double>(
          //         begin: 0.0, // Start invisible/small
          //         end: 1.0, // Full size
          //       ).animate(
          //         CurvedAnimation(
          //           parent: _logoController,
          //           curve: const Interval(0.3, 0.8, curve: Curves.easeOutBack),
          //         ),
          //       ),
          //   child: FadeTransition(
          //     opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          //       CurvedAnimation(
          //         parent: _logoController,
          //         curve: const Interval(0.3, 0.6, curve: Curves.easeIn),
          //       ),
          //     ),
          //     child: Image.asset(
          //       AppAssets.drupTextIcon,
          //       height: 50,
          //       width: 120,
          //       fit: BoxFit.fill,
          //       color: Colors.white,
          //     ),
          //   ),
          // ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }
}
