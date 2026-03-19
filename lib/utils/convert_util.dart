import 'package:drup/theme/app_colors.dart';
import 'package:flutter/material.dart';

Color statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
      return AppColors.green400;
    case 'cancelled' || 'expired':
      return AppColors.red400;
    case 'in_progress' || 'matched' || 'picked_up':
      return AppColors.accent;
    case 'confirmed':
      return AppColors.accent;
    default:
      return AppColors.orange400;
  }
}

Color statusBg(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
      return AppColors.green50;
    case 'cancelled' || 'expired':
      return AppColors.red50;
    case 'in_progress' || 'matched' || 'picked_up':
      return AppColors.accent.withValues(alpha: 0.1);
    case 'confirmed':
      return AppColors.accent.withValues(alpha: 0.1);
    default:
      return AppColors.orange50;
  }
}
