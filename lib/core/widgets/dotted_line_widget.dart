import 'package:flutter/material.dart';

class DottedLinePainter extends CustomPainter {
  final Color color;

  const DottedLinePainter({required this.color});

  static const double _strokeWidth = 1.5;
  static const double _dashHeight = 4.0;
  static const double _dashGap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    double currentY = 0;

    while (currentY < size.height) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            centerX - _strokeWidth / 2,
            currentY,
            _strokeWidth,
            _dashHeight,
          ),
          Radius.circular(_strokeWidth / 2),
        ),
        paint,
      );
      currentY += _dashHeight + _dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant DottedLinePainter oldDelegate) =>
      color != oldDelegate.color;
}