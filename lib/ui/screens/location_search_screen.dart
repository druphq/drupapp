import 'package:drup/resources/app_dimen.dart';
import 'package:drup/resources/app_strings.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class LocationSearchScreen extends StatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final _currentLocationController = TextEditingController();
  final _destinationController = TextEditingController();

  @override
  void dispose() {
    _currentLocationController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Color(0xff253B80),
              Color(0xff253B80),
              Color(0xff5490D0),
              Color(0xff5C9EDC),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header with back button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        AppStrings.scheduleYourRideTitleTxt,
                        textAlign: TextAlign.center,
                        style: TextStyles.t1.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),

              // Current Location TextField
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Corners.hMd),
                    color: AppColors.surface,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  height: 60,
                  alignment: Alignment.center,
                  child: TextField(
                    controller: _currentLocationController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      icon: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                      hintText: 'Current Location',
                      hintStyle: TextStyles.t2.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: FontSizes.s16,
                      ),
                    ),
                    style: TextStyles.t2.copyWith(
                      color: AppColors.onAccent,
                      fontSize: FontSizes.s16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const Gap(16),

              // Destination TextField
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Corners.hMd),
                    color: AppColors.surface,
                  ),
                  height: 60,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _destinationController,
                    autofocus: true,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      icon: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.fromBorderSide(
                            BorderSide(color: AppColors.greyStrong, width: 2),
                          ),
                        ),
                      ),
                      hintText: 'Where to?',
                      hintStyle: TextStyles.t2.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: FontSizes.s16,
                      ),
                    ),
                    style: TextStyles.t2.copyWith(
                      color: AppColors.onAccent,
                      fontSize: FontSizes.s16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const Gap(16),

              // Recent locations section
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16.0,
                          ),
                          itemCount: 5,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(Corners.md),
                                color: Colors.white.withOpacity(0.1),
                              ),
                              child: ListTile(
                                leading: RotatedBox(
                                  quarterTurns: 1,
                                  child: const Icon(
                                    Icons.flight,
                                    color: Colors.white70,
                                  ),
                                ),
                                title: Text(
                                  'Recent Location ${index + 1}',
                                  style: TextStyles.t2.copyWith(
                                    color: Colors.white,
                                    fontSize: FontSizes.s15,
                                  ),
                                ),
                                subtitle: Text(
                                  'Address details here',
                                  style: TextStyles.t2.copyWith(
                                    color: Colors.white70,
                                    fontSize: FontSizes.s13,
                                  ),
                                ),
                                onTap: () {
                                  // Handle location selection
                                  Navigator.pop(context);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
