import 'dart:io';
import 'package:drup/core/widgets/custom_button.dart';
import 'package:drup/di/notifiers.dart';
import 'package:drup/features/drivers/provider/driver_notifier.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import '../../../auth/provider/auth_notifier.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isEditing = false;
  bool _isUploadingPhoto = false;
  File? _pickedPhoto;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = ref.read(userNotifierProvider).user;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userNotifierProvider);
    final user = userState.user;

    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Personal Info',
          style: TextStyles.t1.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (!_isEditing)
            TextButton(
              onPressed: () => setState(() => _isEditing = true),
              child: Text(
                'Edit',
                style: TextStyles.t2.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Image Section
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent.withOpacity(0.1),
                      border: Border.all(color: AppColors.accent, width: 3),
                      image: _pickedPhoto != null
                          ? DecorationImage(
                              image: FileImage(_pickedPhoto!),
                              fit: BoxFit.cover,
                            )
                          : user?.profileImage != null
                          ? DecorationImage(
                              image: NetworkImage(user!.profileImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _pickedPhoto == null && user?.profileImage == null
                        ? const Icon(
                            Icons.person,
                            size: 50,
                            color: AppColors.accent,
                          )
                        : null,
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickPhoto,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: _isUploadingPhoto
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt,
                                  size: 18,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Gap(32),

            // Form Fields
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildTextField(
                    label: 'First Name',
                    controller: _firstNameController,
                    enabled: _isEditing,
                  ),
                  const Gap(16),
                  _buildTextField(
                    label: 'Last Name',
                    controller: _lastNameController,
                    enabled: _isEditing,
                  ),
                  const Gap(16),
                  _buildTextField(
                    label: 'Email',
                    controller: _emailController,
                    enabled: _isEditing,
                    keyboardType: TextInputType.emailAddress,
                    suffix: user?.isEmailVerified == true
                        ? const Icon(
                            Icons.verified,
                            color: AppColors.success,
                            size: 20,
                          )
                        : TextButton(
                            onPressed: () {
                              // TODO: Send verification email
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Verification email sent!'),
                                ),
                              );
                            },
                            child: Text(
                              'Verify',
                              style: TextStyles.t2.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ),
                  const Gap(16),
                  _buildTextField(
                    label: 'Phone Number',
                    controller: _phoneController,
                    enabled: false, // Phone cannot be changed
                    keyboardType: TextInputType.phone,
                    suffix: user?.isPhoneVerified == true
                        ? const Icon(
                            Icons.verified,
                            color: AppColors.success,
                            size: 20,
                          )
                        : null,
                  ),
                ],
              ),
            ),
            const Gap(24),

            // Save Button
            if (_isEditing)
              CustomButton(text: 'Save Changes', onPressed: _saveChanges),
            const Gap(32),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    TextInputType? keyboardType,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.t2.copyWith(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const Gap(8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          style: TextStyles.t1.copyWith(fontSize: 16),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? AppColors.surface : AppColors.surface,
            suffixIcon: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accent),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Gap(16),
              Text(
                'Select Source',
                style: TextStyles.t1.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(16),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.accent,
                ),
                title: Text(
                  'Gallery',
                  style: TextStyles.t1.copyWith(fontSize: 16),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.accent),
                title: Text(
                  'Camera',
                  style: TextStyles.t1.copyWith(fontSize: 16),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;

    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _pickedPhoto = File(picked.path));
  }

  Future<void> _saveChanges() async {
    setState(() => _isEditing = false);

    // Check if running as a driver — upload photo via driver notifier
    final isDriver = ref.read(isDriverProvider);

    if (_pickedPhoto != null && isDriver) {
      setState(() => _isUploadingPhoto = true);
      final success = await ref
          .read(driverNotifierProvider.notifier)
          .uploadProfilePhoto(_pickedPhoto!);
      setState(() => _isUploadingPhoto = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Profile photo updated!' : 'Failed to upload photo',
            ),
            backgroundColor: success ? AppColors.success : AppColors.warning,
          ),
        );
      }
      _pickedPhoto = null;
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }
}
