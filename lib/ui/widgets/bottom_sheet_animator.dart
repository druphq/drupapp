import 'package:flutter/material.dart';

class BottomWidgetAnimator extends StatefulWidget {
  const BottomWidgetAnimator({super.key, required this.child});
  final Widget child;

  @override
  BottomWidgetAnimatorState createState() => BottomWidgetAnimatorState();
}

class BottomWidgetAnimatorState extends State<BottomWidgetAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0, 1), // Start position (below screen)
                end: const Offset(0, 0), // End position (center of screen)
              ).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Curves.easeInOut,
                ),
              ),
          child: child,
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
