import 'package:drup/core/widgets/app_phone_field.dart';
import 'package:drup/core/widgets/custom_text_field.dart';
import 'package:drup/di/providers.dart';
import 'package:drup/theme/app_style.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/resources/app_strings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:the_validator/the_validator.dart';
import '../provider/auth_notifier.dart';
import '../../../router/app_routes.dart';
import '../../../data/models/user.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEmailVerified = false;
  bool _isPhoneVerified = false;
  final formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  void _loadUserData() {
    if (_isDataLoaded) return;

    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user != null) {
      setState(() {
        _firstnameController.text = user.firstName ?? '';
        _lastnameController.text = user.lastName ?? '';
        _emailController.text = user.email ?? '';
        _isEmailVerified = user.isEmailVerified;
        _isPhoneVerified = user.isPhoneVerified;
        _isDataLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Complete  Profile',
          style: TextStyles.t1.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        scrolledUnderElevation: 0.0,
      ),
      body: SafeArea(
        bottom: false,
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(left: 16, right: 16, top: 10.0),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Text(
                    AppStrings.informationMsg,
                    style: TextStyles.caption,
                  ),
                ),
                const Gap(5.0),
                CustomTextField(
                  controller: _firstnameController,
                  hintText: AppStrings.firstNameTxt,
                  style: TextStyles.h4.copyWith(
                    color: Colors.black,
                    fontSize: FontSizes.s16,
                  ),
                  validator: FieldValidator.required(
                    message: AppStrings.firstNameErrorMsg,
                  ),
                ),
                const Gap(10.0),
                CustomTextField(
                  controller: _lastnameController,
                  hintText: AppStrings.lastNameTxt,
                  style: TextStyles.h4.copyWith(
                    color: Colors.black,
                    fontSize: FontSizes.s16,
                  ),
                  validator: FieldValidator.required(
                    message: AppStrings.lastNameErrorMsg,
                  ),
                ),
                const Gap(10.0),
                if (!_isEmailVerified)
                  CustomTextField(
                    controller: _emailController,
                    hintText: AppStrings.emailHintTXt,
                    style: TextStyles.h4.copyWith(
                      color: Colors.black,
                      fontSize: FontSizes.s16,
                    ),
                    validator: FieldValidator.required(
                      message: AppStrings.emailAddressErrorMsg,
                    ),
                  ),
                if (!_isPhoneVerified)
                  AppPhoneField(
                    hint: 'Phone Number',
                    borderRadius: Corners.mmd,
                    controller: _phoneController,
                    style: TextStyles.h3.copyWith(
                      color: Colors.black,
                      fontSize: FontSizes.s18,
                    ),
                    validator: FieldValidator.minLength(
                      11,
                      message: AppStrings.phoneErrorMessage,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.noticeErrorMsg,
              style: TextStyles.caption.copyWith(
                fontSize: FontSizes.s12,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
            const Gap(5.0),
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: Sizes.btnHeightMd,
                minWidth: Sizes.btnWidthMd,
              ),
              child: FilledButton(
                onPressed: _isLoading ? null : _handleSubmit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        AppStrings.continueTxt,
                        style: TextStyles.btnStyle.copyWith(
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = ref.read(authNotifierProvider).value;

      if (currentUser == null) {
        _showError('User not found. Please login again.');
        return;
      }

      // Determine if profile should be marked complete
      // Only complete if no pending verifications
      final needsEmailVerification =
          !_isEmailVerified && _emailController.text.trim().isNotEmpty;
      final needsPhoneVerification =
          !_isPhoneVerified && _phoneController.text.trim().isNotEmpty;
      final shouldMarkComplete =
          !needsEmailVerification && !needsPhoneVerification;

      // Update user with new profile data
      final updatedUser = currentUser.copyWith(
        firstName: _firstnameController.text.trim(),
        lastName: _lastnameController.text.trim(),
        email: _emailController.text.isNotEmpty
            ? _emailController.text.trim()
            : null,
        phone: _phoneController.text.isNotEmpty
            ? _phoneController.text.trim()
            : null,
        profileStatus: shouldMarkComplete
            ? ProfileCompletionStatus.complete
            : currentUser.profileStatus,
      );

      // Update profile via AuthNotifier
      await ref.read(authNotifierProvider.notifier).updateProfile(updatedUser);

      if (mounted) {
        // Check if user needs to verify email
        if (!_isEmailVerified && _emailController.text.trim().isNotEmpty) {
          // Send email verification OTP
          final authRepo = ref.read(authRepositoryProvider);
          final result = await authRepo.resendEmailVerification();

          if (result.success) {
            _showSuccess(
              'Verification code sent to ${_emailController.text.trim()}',
            );

            // Navigate to email verification screen
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) {
              context.push(
                AppRoutes.emailVerificationRoute,
                extra: {'email': _emailController.text.trim()},
              );
            }
          } else {
            _showError(result.message ?? 'Failed to send verification code');
          }
        } else if (!_isPhoneVerified &&
            _phoneController.text.trim().isNotEmpty) {
          // Navigate to phone verification (OTP) screen
          _showSuccess('Please verify your phone number');
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            context.push(
              AppRoutes.otpRoute,
              extra: {
                'phoneNumber': _phoneController.text.trim(),
                'isGoogleSignIn': false,
              },
            );
          }
        } else {
          // Profile complete and all verifications done
          _showSuccess('Profile completed successfully!');
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            final isDriver = updatedUser.userType == UserType.driver;
            context.go(
              isDriver ? AppRoutes.driverHomeRoute : AppRoutes.homeRoute,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to update profile: ${e.toString()}');
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

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }
}
