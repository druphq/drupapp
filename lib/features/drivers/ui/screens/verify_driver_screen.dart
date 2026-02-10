import 'package:drup/core/widgets/custom_button.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class VerifyDriverScreen extends ConsumerWidget {
  const VerifyDriverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Gap(16),

              // Illustration
              Center(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: AppColors.accentLight.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Phone illustration
                      Container(
                        width: 100,
                        height: 160,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const Gap(12),
                            Container(
                              width: 60,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const Gap(6),
                            Container(
                              width: 40,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Checkmark badge
                      Positioned(
                        right: 40,
                        top: 50,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Gap(40),

              // Title
              Text(
                'Finish setting up your Drup Driver profile',
                style: TextStyles.h1.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),

              const Gap(32),

              // Verification steps
              _buildVerificationItem(
                icon: Icons.verified_user_outlined,
                title: 'Verify your identity',
                description: 'Keep Drup safe for everyone',
                isCompleted: false,
                onTap: () {
                  // TODO: Navigate to identity verification
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Identity verification coming soon!'),
                    ),
                  );
                },
              ),

              const Gap(16),

              _buildVerificationItem(
                icon: Icons.directions_car_outlined,
                title: 'Register your vehicle',
                description: 'Add your vehicle details and documents',
                isCompleted: false,
                onTap: () {
                  // TODO: Navigate to vehicle registration
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vehicle registration coming soon!'),
                    ),
                  );
                },
              ),

              const Gap(16),

              _buildVerificationItem(
                icon: Icons.credit_card_outlined,
                title: 'Set up payment',
                description: 'Add your bank details to receive earnings',
                isCompleted: false,
                onTap: () {
                  // TODO: Navigate to payment setup
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment setup coming soon!')),
                  );
                },
              ),

              const Gap(40),

              // Continue button
              CustomButton(
                text: 'Continue',
                onPressed: () {
                  // TODO: Navigate to first incomplete step
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Verification flow coming soon!'),
                    ),
                  );
                },
              ),

              const Gap(16),

              // Do this later text
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    'You can always do this later from your account',
                    textAlign: TextAlign.center,
                    style: TextStyles.t2.copyWith(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),

              const Gap(32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCompleted
              ? AppColors.success.withOpacity(0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? AppColors.success.withOpacity(0.3)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.success
                    : AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isCompleted ? Icons.check : icon,
                color: isCompleted ? Colors.white : AppColors.accent,
                size: 24,
              ),
            ),
            const Gap(16),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyles.t1.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    description,
                    style: TextStyles.t2.copyWith(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
