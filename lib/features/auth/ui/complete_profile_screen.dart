import 'package:drup/core/widgets/custom_text_field.dart';
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
  final formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = ref.read(authNotifierProvider).value;
    if (user != null) {
      _firstnameController.text = user.firstName ?? '';
      _lastnameController.text = user.lastName ?? '';
      _emailController.text = user.email ?? '';
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Complete  Profile',
          style: TextStyles.t1.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
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
                  style: TextStyles.h4.copyWith(color: Colors.black),
                  validator: FieldValidator.required(
                    message: AppStrings.firstNameErrorMsg,
                  ),
                ),
                const Gap(10.0),
                CustomTextField(
                  controller: _lastnameController,
                  hintText: AppStrings.lastNameTxt,
                  style: TextStyles.h4.copyWith(color: Colors.black),
                  validator: FieldValidator.required(
                    message: AppStrings.lastNameErrorMsg,
                  ),
                ),
                const Gap(10.0),
                CustomTextField(
                  controller: _emailController,
                  hintText: AppStrings.emailHintTXt,
                  style: TextStyles.h4.copyWith(color: Colors.black),
                  validator: FieldValidator.required(
                    message: AppStrings.emailAddressErrorMsg,
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

      // Update user with new profile data
      final updatedUser = currentUser.copyWith(
        firstName: _firstnameController.text.trim(),
        lastName: _lastnameController.text.trim(),
        email: _emailController.text.trim(),
        profileStatus: ProfileCompletionStatus.complete,
      );

      // Update profile via AuthNotifier
      await ref.read(authNotifierProvider.notifier).updateProfile(updatedUser);

      if (mounted) {
        _showSuccess('Profile completed successfully!');
        // Navigate to home after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          context.go(AppRoutes.homeRoute);
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
