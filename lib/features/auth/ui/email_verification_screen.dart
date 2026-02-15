import 'package:drup/core/widgets/custom_button.dart';
import 'package:drup/features/passenger/model/user.dart';
import 'package:drup/di/providers.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/router/app_routes.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:otp_pin_field/otp_pin_field.dart';
import '../repository/auth_repository.dart';
import '../model/auth.dart';
import '../provider/auth_notifier.dart';
import '../../passenger/provider/user_notifier.dart';
import '../../../theme/app_colors.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  final _otpPinFieldController = GlobalKey<OtpPinFieldState>();
  String _otp = '';
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _verifyEmailOTP([String? otpCode]) async {
    final otp = otpCode ?? _otp;

    if (otp.length != 6) {
      _showError('Please enter the complete 6-digit OTP');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final request = VerifyEmailRequest(otp: otp);
      final result = await authRepo.verifyEmail(request);

      if (mounted) {
        if (result.success && result.data != null) {
          // Update auth state with verified user
          ref.read(authNotifierProvider.notifier).updateUser(result.data!);

          // Reload user profile
          await ref.read(userNotifierProvider.notifier).loadUserProfile();

          _showSuccess('Email verified successfully!');

          // Navigate to home after verification
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            final user = ref.read(authNotifierProvider).value;
            final isDriver = user?.userType == UserType.driver;
            context.go(
              isDriver ? AppRoutes.driverHomeRoute : AppRoutes.homeRoute,
            );
          }
        } else {
          _showError(result.message ?? 'Email verification failed');
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
      final result = await authRepo.resendEmailVerification();

      if (mounted) {
        if (result.success) {
          _showSuccess('OTP resent successfully to ${widget.email}');
          // Clear OTP field
          _otpPinFieldController.currentState?.clearOtp();
          setState(() {
            _otp = '';
          });
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
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: Sizes.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Gap(20),
              Text(
                'Verify Email',
                style: TextStyles.t1.copyWith(fontSize: FontSizes.s20),
              ),
              const Gap(8),
              Text.rich(
                TextSpan(
                  text: 'We sent a verification code to ',
                  style: TextStyles.body1.copyWith(
                    fontSize: FontSizes.s16,
                    color: AppColors.surface600,
                  ),
                  children: [
                    TextSpan(
                      text: widget.email,
                      style: TextStyles.body1.copyWith(
                        fontSize: FontSizes.s16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.surface600,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(40),
              // OTP Input Field
              OtpPinField(
                key: _otpPinFieldController,
                autoFillEnable: false,
                textInputAction: TextInputAction.done,
                onSubmit: (text) {
                  _otp = text;
                  _verifyEmailOTP(text);
                },
                onChange: (text) {
                  setState(() {
                    _otp = text;
                  });
                },
                maxLength: 6,
                showCursor: true,
                cursorColor: AppColors.primary,
                cursorWidth: 2,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                otpPinFieldStyle: OtpPinFieldStyle(
                  defaultFieldBorderColor: Colors.grey.shade300,
                  activeFieldBorderColor: AppColors.primary,
                  filledFieldBorderColor: AppColors.primary,
                  fieldBorderWidth: 1,
                  fieldBorderRadius: Corners.md,
                  fieldPadding: 8,
                ),
                otpPinFieldDecoration: OtpPinFieldDecoration.custom,
                fieldWidth: 50,
                fieldHeight: 60,
              ),
              const Gap(30),
              // Resend OTP
              Text.rich(
                TextSpan(
                  text: 'Didn\'t receive the code? ',
                  style: TextStyles.body2.copyWith(
                    fontSize: FontSizes.s16,
                    color: AppColors.surface700,
                  ),
                  children: [
                    TextSpan(
                      text: 'Resend',
                      style: TextStyles.t1.copyWith(
                        color: AppColors.primary,
                        fontSize: FontSizes.s16,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = _isResending ? null : _resendOTP,
                    ),
                    WidgetSpan(
                      child: _isResending
                          ? Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const Gap(40),
              // Verify Button
              CustomButton(
                text: 'Verify Email',
                onPressed: _verifyEmailOTP,
                isLoading: _isLoading,
                textStyle: TextStyles.btnStyle.copyWith(
                  color: Colors.white,
                  fontSize: 16.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
