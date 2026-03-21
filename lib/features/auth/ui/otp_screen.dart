import 'package:drup/core/widgets/custom_button.dart';
import 'package:drup/di/notifiers.dart';
import 'package:drup/di/providers.dart';
import 'package:drup/features/drivers/model/driver.dart';
import 'package:drup/features/drivers/provider/driver_notifier.dart';
import 'package:drup/features/passenger/model/user.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/resources/app_strings.dart';
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
  final _otpPinFieldController = GlobalKey<OtpPinFieldState>();
  String _otp = '';
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _verifyOTP([String? otpCode]) async {
    final otp = otpCode ?? _otp;

    if (otp.length != 6) {
      _showError('Please enter the complete 6-digit OTP');
      return;
    }

    setState(() => _isLoading = true);

    try {
      bool success;

      success = await ref
          .read(authNotifierProvider.notifier)
          .verifyOTP(widget.phoneNumber, otp);

      if (success && mounted) {
        // Get the authenticated user from state
        final user = ref.read(authNotifierProvider).value;

        if (user != null) {
          if (!user.isProfileComplete) {
            if (mounted) context.go(AppRoutes.completeProfileRoute);
            return;
          }

          // Fetch application status to determine driver/passenger
          await _navigateByRole(user);
        }
      } else if (mounted) {
        final error = ref.read(authNotifierProvider).error;
        _showError(error?.toString() ?? 'OTP verification failed');
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

  /// Navigate based on user role — mirrors splash screen logic.
  Future<void> _navigateByRole(User user) async {
    final driverNotifier = ref.read(driverNotifierProvider.notifier);
    final userRepo = ref.read(userRepositoryProvider);

    // Fetch driver application status
    await driverNotifier.fetchApplicationStatus();
    if (!mounted) return;

    final appStatus = ref.read(driverNotifierProvider).applicationStatus;
    final rawStatus = appStatus?['status'] as String?;
    final status = DriverApplicationStatus.fromString(rawStatus);

    // Check if user is a driver
    if (user.isDriver) {
      // Switch to driver role
      final switched = await driverNotifier.switchRole(AppStrings.driverRole);
      if (!mounted) return;

      if (switched) {
        userRepo.storeUserMode(AppStrings.driverMode);
        await driverNotifier.loadDriverProfile();
        if (!mounted) return;

        // If approved/active but hasn't seen approval screen
        if (status == DriverApplicationStatus.approved ||
            status == DriverApplicationStatus.active) {
          final hasSeenApproval = await userRepo.getDriverApprovalSeen();
          if (!hasSeenApproval) {
            if (mounted) context.go(AppRoutes.verifyDriverRoute);
            return;
          }
        }

        if (mounted) context.go(AppRoutes.driverHomeRoute);
      } else {
        // Driver switch failed — fallback to passenger
        if (mounted) context.go(AppRoutes.homeRoute);
      }
    } else {
      // Passenger flow
      final switched = await driverNotifier.switchRole(
        AppStrings.passengerRole,
      );
      if (!mounted) return;

      if (switched) {
        userRepo.storeUserMode(AppStrings.passengerMode);
        await ref.read(userNotifierProvider.notifier).loadUserProfile();
        if (mounted) context.go(AppRoutes.homeRoute);
      } else {
        if (mounted) context.go(AppRoutes.homeRoute);
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
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: Sizes.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(20),
                Text(
                  'Enter Code',
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
                        text: widget.phoneNumber,
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
                    _verifyOTP(text);
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
                    fieldBorderRadius: Corners.c8,
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
                      if (!_isResending)
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
      ),
    );
  }
}
