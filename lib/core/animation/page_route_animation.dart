import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Creates a CustomTransitionPage with slide up animation
CustomTransitionPage<T> slideUpTransitionPage<T>({
  required LocalKey key,
  required Widget child,
  Duration? transitionDuration,
  Duration? reverseTransitionDuration,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0); // Start from bottom
      const end = Offset.zero;
      const curve = Curves.easeInOut;

      var tween = Tween(begin: begin, end: end)
          .chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);

      return SlideTransition(position: offsetAnimation, child: child);
    },
    transitionDuration: transitionDuration ?? const Duration(milliseconds: 500),
    reverseTransitionDuration: reverseTransitionDuration ?? const Duration(milliseconds: 500),
  );
}

/// Creates a CustomTransitionPage with fade animation
CustomTransitionPage<T> fadeTransitionPage<T>({
  required LocalKey key,
  required Widget child,
  Duration? transitionDuration,
  Duration? reverseTransitionDuration,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: transitionDuration ?? const Duration(milliseconds: 300),
    reverseTransitionDuration: reverseTransitionDuration ?? const Duration(milliseconds: 300),
  );
}

/// Creates a CustomTransitionPage with slide from right animation
CustomTransitionPage<T> slideRightTransitionPage<T>({
  required LocalKey key,
  required Widget child,
  Duration? transitionDuration,
  Duration? reverseTransitionDuration,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0); // Start from right
      const end = Offset.zero;
      const curve = Curves.easeInOut;

      var tween = Tween(begin: begin, end: end)
          .chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);

      return SlideTransition(position: offsetAnimation, child: child);
    },
    transitionDuration: transitionDuration ?? const Duration(milliseconds: 300),
    reverseTransitionDuration: reverseTransitionDuration ?? const Duration(milliseconds: 300),
  );
}
