import 'package:drup/theme/app_colors.dart';
import 'package:flutter/material.dart';

class LocationDotWidget extends StatelessWidget {
  const LocationDotWidget({
    super.key,
    required this.bgColor,
    this.isActive = false,
    this.size = 16.0,
  });

  final Color bgColor;
  final bool isActive;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isActive ? bgColor : Colors.transparent,
        shape: BoxShape.circle,
        border: isActive
            ? null
            : Border.all(color: AppColors.greyStrong, width: 1.5),
      ),
      child: isActive
          ? Icon(Icons.circle, color: Colors.white, size: size / 1.6)
          : null,
    );
  }
}
