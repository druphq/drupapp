import 'package:drup/core/widgets/app_phone_field.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/resources/app_strings.dart';
import 'package:drup/router/app_routes.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_notifier.dart';
import '../../providers/user_notifier.dart';
import '../../theme/app_colors.dart';
import '../../core/constants/constants.dart';
import '../../core/widgets/custom_button.dart';
import 'package:gap/gap.dart';
import 'package:the_validator/the_validator.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool _isDriver = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final email = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (_phoneController.text.length < 10) {
      _showError('Please enter a correct phone number');
      return;
    }

    bool success;
    if (_isDriver) {
      success = await ref
          .read(authNotifierProvider.notifier)
          .loginWithPhone(email);
    } else {
      success = await ref
          .read(authNotifierProvider.notifier)
          .loginWithPhone(email);
    }

    if (success && mounted) {
      // Initialize user location
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        await ref
            .read(userNotifierProvider.notifier)
            .loadUserProfile(currentUser.id);
        await ref.read(userNotifierProvider.notifier).updateUserLocation();
      }

      // Navigate to appropriate screen
      if (mounted) {
        if (_isDriver) {
          context.go(AppRoutes.driverHomeRoute);
        } else {
          context.go(AppRoutes.homeRoute);
        }
      }
    } else if (mounted) {
      final error = ref.read(authNotifierProvider).error;
      _showError(error?.toString() ?? 'Login failed');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: SafeArea(
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
                          isLoading: isLoading,
                          textStyle: TextStyles.btnStyle.copyWith(
                            color: Colors.white,
                            fontSize: 16.0,
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
    );
  }
}
