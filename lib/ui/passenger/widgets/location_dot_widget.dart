import 'package:drup/theme/app_colors.dart';
import 'package:flutter/material.dart';

class LocationDotWidget extends StatelessWidget {
  const LocationDotWidget({
    super.key,
    required this.bgColor,
    this.isActive = false,
  });

  final Color bgColor;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: isActive ? bgColor : Colors.transparent,
        shape: BoxShape.circle,
        border: isActive
            ? null
            : Border.all(color: AppColors.greyStrong, width: 2),
      ),
      child: isActive ? Icon(Icons.circle, color: Colors.white, size: 10) : null,
    );
  }
}
