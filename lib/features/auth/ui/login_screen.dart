import 'package:drup/core/widgets/app_phone_field.dart';
import 'package:drup/features/auth/repository/auth_repository.dart';
import 'package:drup/features/auth/model/auth.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/resources/app_strings.dart';
import 'package:drup/router/app_routes.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../provider/auth_notifier.dart';
import '../../../theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import 'package:gap/gap.dart';
import 'package:the_validator/the_validator.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool _isGoogleLoading = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);

    try {
      final result = await ref
          .read(authNotifierProvider.notifier)
          .loginWithGoogle();

      if (result != null && mounted) {
        // Now need to request phone OTP
        _showPhoneVerificationDialog(result);
      }
    } catch (e) {
      if (mounted) {
        _showError('Google Sign-In failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  Future<void> _showPhoneVerificationDialog(dynamic googleResult) async {
    final phoneController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Phone Verification Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, ${googleResult.firstName ?? 'User'}!'),
            const Gap(8),
            const Text(
              'Please enter your phone number to complete verification.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const Gap(16),
            AppPhoneField(
              hint: 'Phone Number',
              controller: phoneController,
              borderRadius: Corners.mmd,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (phoneController.text.length >= 10) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final phone = phoneController.text;

      // Request OTP for phone
      setState(() => _isGoogleLoading = true);
      try {
        final authRepo = AuthRepository();
        final otpResult = await authRepo.signIn(
          SignInRequest(phoneNumber: phone),
        );

        if (otpResult.success && mounted) {
          // Navigate to OTP screen with Google data
          context.push(
            AppRoutes.otpRoute,
            extra: {
              'phoneNumber': phone,
              'isGoogleSignIn': true,
              'googleData': {
                'googleId':
                    googleResult.idToken, // Using idToken as googleId for now
                'email': googleResult.email,
                'firstName': googleResult.firstName,
                'lastName': googleResult.lastName,
                'profileImage': googleResult.profileImage,
              },
            },
          );
        } else if (mounted) {
          _showError(otpResult.message ?? 'Failed to send OTP');
        }
      } catch (e) {
        if (mounted) {
          _showError('Error: ${e.toString()}');
        }
      } finally {
        if (mounted) {
          setState(() => _isGoogleLoading = false);
        }
      }
    }

    phoneController.dispose();
  }

  Future<void> _handleLogin() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final phone = _phoneController.text.trim();

    if (phone.length < 10) {
      _showError('Please enter a correct phone number');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Request OTP using AuthRepository
      final authRepo = AuthRepository();
      final result = await authRepo.signIn(SignInRequest(phoneNumber: '+234$phone'));

      if (result.success && mounted) {
        // Navigate to OTP screen
        context.push(
          AppRoutes.otpRoute,
          extra: {'phoneNumber': '+234$phone', 'isGoogleSignIn': false},
        );
      } else if (mounted) {
        _showError(result.message ?? 'Failed to send OTP');
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          bottom: false,
          top: false,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: Sizes.sm),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  Text(
                    AppStrings.enterYourNumberTxt,
                    style: TextStyles.t1.copyWith(fontSize: FontSizes.s18),
                  ),
                  Text(
                    AppStrings.enterPhoneNumberCaptionTxt,
                    style: TextStyles.body1,
                  ),
                  const Gap(20.0),
                  AppPhoneField(
                    hint: 'Phone Number',
                    borderRadius: Corners.mmd,
                    controller: _phoneController,
                    style: TextStyles.h3.copyWith(color: Colors.black),
                    validator: FieldValidator.minLength(
                      11,
                      message: AppStrings.phoneErrorMessage,
                    ),
                  ),
                  const Gap(40.0),
                  Row(
                    children: [
                      Expanded(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: Sizes.btnWidthMd,
                            minHeight: Sizes.btnHeightMd,
                          ),
                          child: CustomButton(
                            text: AppStrings.continueTxt,
                            onPressed: _handleLogin,
                            isLoading: _isLoading,
                            textStyle: TextStyles.btnStyle.copyWith(
                              color: Colors.white,
                              fontSize: 16.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(20.0),
                  // Divider with "or" text
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.grey.shade300,
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'or',
                          style: TextStyles.body2.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.grey.shade300,
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const Gap(20.0),
                  // Google Sign-In Button
                  Row(
                    children: [
                      Expanded(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: Sizes.btnWidthMd,
                            minHeight: Sizes.btnHeightMd,
                          ),
                          child: OutlinedButton(
                            onPressed: _isGoogleLoading
                                ? null
                                : _handleGoogleSignIn,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  Corners.mmd,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 14.0,
                              ),
                            ),
                            child: _isGoogleLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Continue with Google',
                                        style: TextStyles.btnStyle.copyWith(
                                          color: Colors.grey.shade800,
                                          fontSize: 16.0,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 1),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: Sizes.sm),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: AppStrings.termConditionMsgTxt,
                        style: TextStyles.body2.copyWith(
                          color: Colors.grey.shade800,
                          fontSize: FontSizes.s12,
                        ),
                        children: [
                          TextSpan(
                            text: AppStrings.termAndConditionTxt,
                            style: TextStyles.h2.copyWith(
                              color: AppColors.accent,
                              fontSize: FontSizes.s14,
                            ),
                            recognizer: TapGestureRecognizer()..onTap = () {},
                          ),
                          TextSpan(
                            text: AppStrings.privacyPolicyTxt,
                            style: TextStyles.h3.copyWith(
                              fontSize: FontSizes.s14,
                              color: AppColors.accent,
                            ),
                            recognizer: TapGestureRecognizer()..onTap = () {},
                          ),
                          TextSpan(
                            text: AppStrings.andTxt,
                            style: TextStyles.body2.copyWith(
                              fontSize: FontSizes.s12,
                            ),
                          ),
                          TextSpan(
                            text: AppStrings.over18txt,
                            style: TextStyles.body2.copyWith(
                              fontSize: FontSizes.s12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
