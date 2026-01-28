import 'package:drup/core/widgets/custom_button.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../../providers/user_notifier.dart';

class LocationPermissionBottomSheet extends ConsumerStatefulWidget {
  const LocationPermissionBottomSheet({super.key});

  @override
  ConsumerState<LocationPermissionBottomSheet> createState() =>
      _LocationPermissionBottomSheetState();
}

class _LocationPermissionBottomSheetState
    extends ConsumerState<LocationPermissionBottomSheet> {
  bool _isLoading = false;

  Future<void> _requestLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(userNotifierProvider.notifier).updateUserLocation();

      if (!mounted) return;

      // Check if location was successfully obtained
      final userState = ref.read(userNotifierProvider);

      if (userState.currentLocation != null) {
        // Successfully got location, close the bottom sheet
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      } else {
        // Failed to get location
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Unable to access location. Please enable location services.',
              ),
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(24),

            // Location icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1),
              ),
              child: Icon(
                Icons.location_on,
                size: 40,
                color: AppColors.primary,
              ),
            ),

            const Gap(24),

            // Title
            Text(
              'Enable Location',
              style: TextStyles.h1.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Gap(12),

            // Description
            Text(
              'We need your location to show nearby drivers and provide accurate pickup services.',
              textAlign: TextAlign.center,
              style: TextStyles.t1.copyWith(
                color: AppColors.textSecondary,
                fontSize: 16,
                height: 1.5,
              ),
            ),

            const Gap(32),

            // Enable Location Button
            CustomButton(
              text: _isLoading ? 'Getting Location...' : 'Enable Location',
              onPressed: _isLoading ? () {} : _requestLocation,
            ),

            const Gap(12),

            // Skip button
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      Navigator.pop(context);
                    },
              child: Text(
                'Skip for now',
                style: TextStyles.t1.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
