import 'package:drup/core/widgets/custom_button.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/router/app_routes.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../repository/auth_repository.dart';
import '../model/auth.dart';
import '../../../providers/user_notifier.dart';
import '../../../theme/app_colors.dart';

class OTPScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final GoogleData? googleData;
  final bool isGoogleSignIn;

  const OTPScreen({
    super.key,
    required this.phoneNumber,
    this.googleData,
    this.isGoogleSignIn = false,
  });

  @override
  ConsumerState<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends ConsumerState<OTPScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otp => _otpControllers.map((c) => c.text).join();

  Future<void> _verifyOTP() async {
    if (_otp.length != 6) {
      _showError('Please enter the complete 6-digit OTP');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authRepo = AuthRepository();

      if (widget.isGoogleSignIn && widget.googleData != null) {
        // Google Sign-In completion flow
        final result = await authRepo.googleComplete(
          GoogleCompleteRequest(
            phoneNumber: widget.phoneNumber,
            otp: _otp,
            googleData: widget.googleData!,
          ),
        );

        if (result.success && mounted) {
          final user = result.data!.user;
          await ref
              .read(userNotifierProvider.notifier)
              .loadUserProfile(user.id);
          await ref.read(userNotifierProvider.notifier).updateUserLocation();

          if (user.isProfileComplete) {
            context.go(AppRoutes.homeRoute);
          } else {
            _showProfileIncompleteDialog();
          }
        } else if (mounted) {
          _showError(result.message ?? 'OTP verification failed');
        }
      } else {
        // Phone-only sign-in flow
        final result = await authRepo.verifyOtp(
          VerifyOtpRequest(phoneNumber: widget.phoneNumber, otp: _otp),
        );

        if (result.success && mounted) {
          final user = result.data!.user;
          await ref
              .read(userNotifierProvider.notifier)
              .loadUserProfile(user.id);
          await ref.read(userNotifierProvider.notifier).updateUserLocation();

          if (user.isProfileComplete) {
            context.go(AppRoutes.homeRoute);
          } else {
            _showProfileIncompleteDialog();
          }
        } else if (mounted) {
          _showError(result.message ?? 'OTP verification failed');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendOTP() async {
    setState(() => _isResending = true);

    try {
      final authRepo = AuthRepository();
      final result = await authRepo.signIn(
        SignInRequest(phoneNumber: widget.phoneNumber),
      );

      if (mounted) {
        if (result.success) {
          _showSuccess('OTP resent successfully');
          // Clear OTP fields
          for (var controller in _otpControllers) {
            controller.clear();
          }
          _focusNodes[0].requestFocus();
        } else {
          _showError(result.message ?? 'Failed to resend OTP');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  void _showProfileIncompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Complete Your Profile'),
        content: const Text(
          'Please complete your profile to continue using the app.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to profile completion screen
              // context.go(AppRoutes.profileSetupRoute);
              context.go(AppRoutes.homeRoute); // Temporary
            },
            child: const Text('Complete Profile'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: Sizes.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Gap(20),
              Text(
                'Enter OTP',
                style: TextStyles.t1.copyWith(fontSize: FontSizes.s24),
              ),
              const Gap(8),
              Text(
                'We sent a code to ${widget.phoneNumber}',
                style: TextStyles.body1,
                textAlign: TextAlign.center,
              ),
              const Gap(40),
              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  6,
                  (index) => SizedBox(
                    width: 50,
                    height: 60,
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: TextStyles.h1.copyWith(fontSize: FontSizes.s24),
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Corners.md),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Corners.md),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Corners.md),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }

                        // Auto-submit when all 6 digits are entered
                        if (index == 5 && value.isNotEmpty) {
                          _verifyOTP();
                        }
                      },
                    ),
                  ),
                ),
              ),
              const Gap(30),
              // Resend OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Didn't receive code? ", style: TextStyles.body2),
                  TextButton(
                    onPressed: _isResending ? null : _resendOTP,
                    child: _isResending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Resend',
                            style: TextStyles.h3.copyWith(
                              color: AppColors.primary,
                              fontSize: FontSizes.s14,
                            ),
                          ),
                  ),
                ],
              ),
              const Gap(40),
              // Verify Button
              CustomButton(
                text: 'Verify',
                onPressed: _verifyOTP,
                isLoading: _isLoading,
                textStyle: TextStyles.btnStyle.copyWith(
                  color: Colors.white,
                  fontSize: 16.0,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
