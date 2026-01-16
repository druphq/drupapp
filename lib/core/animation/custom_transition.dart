import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum PageTransitionStyle {
  fade,
  scale,
  rotate,
  slideRight,
  fromBottom,
  fromTop,
  none
}

class CustomPageTransition<T> extends CustomTransitionPage<T> {
  final Duration? duration;
  final PageTransitionStyle transitionStyle;

  CustomPageTransition({
    required super.key,
    required super.child,
    this.transitionStyle = PageTransitionStyle.none,
    this.duration,
  }) : super(
            transitionDuration: duration ?? const Duration(milliseconds: 300),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              if (transitionStyle == PageTransitionStyle.slideRight) {
                return SlideTransition(
                  position: animation.drive(
                    Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: const Offset(0.0, 0.0),
                    ).chain(CurveTween(curve: Curves.easeIn)),
                  ),
                  child: child,
                );
              } else if (transitionStyle == PageTransitionStyle.fade) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              } else if (transitionStyle == PageTransitionStyle.rotate) {
                return RotationTransition(
                  turns: ReverseAnimation(animation),
                  child: child,
                );
              } else if (transitionStyle == PageTransitionStyle.scale) {
                return ScaleTransition(scale: animation, child: child);
              } else {
                var xTranslation = 0.0, yTranslation = 0.0;

                if (transitionStyle == PageTransitionStyle.fade) {
                  return FadeTransition(
                    opacity: animation,
                    child: Transform(
                      transform: Matrix4.translationValues(
                          xTranslation, yTranslation, 0.0),
                      child: child,
                    ),
                  );
                } else if (transitionStyle == PageTransitionStyle.fromTop) {
                  // this will animate items from top with fade transition
                  yTranslation = -50 * (1.0 - animation.value);
                } else if (transitionStyle == PageTransitionStyle.fromBottom) {
                  // this will animate items from bottom with fade transition
                  yTranslation = 50 * (1.0 - animation.value);
                } else if (transitionStyle == PageTransitionStyle.slideRight) {
                  // this will animate items from right with fade transition
                  xTranslation = 400 * (1.0 - animation.value);
                }
                return child;
              }
            });
}
