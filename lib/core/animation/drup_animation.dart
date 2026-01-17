import 'package:drup/resources/app_assets.dart';
import 'package:flutter/material.dart';

class DrupLogoAnimation extends StatefulWidget {
  const DrupLogoAnimation({super.key});

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
      duration: const Duration(seconds: 4), // Adjust duration as needed
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
        // Animated Drup text logo  sliding in from left
        SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(-2, 0), // Start position (right screen)
                end: const Offset(0, 0), // End position (center of screen)
              ).animate(
                CurvedAnimation(
                  parent: _logoController,
                  curve: const Interval(
                    0,
                    0.5,
                    curve: Curves.linearToEaseOut,
                  ), // Animation curve
                ),
              ),
          child: Image.asset(
            AppAssets.drupTextIcon,
            height: 80,
            width: 120,
            fit: BoxFit.fill,
            color: Colors.white,
          ),
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
