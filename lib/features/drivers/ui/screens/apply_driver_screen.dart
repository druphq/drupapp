import 'dart:io';
import 'package:drup/core/widgets/custom_button.dart';
import 'package:drup/features/drivers/provider/driver_notifier.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

/// Screen for submitting a driver application.
/// Collects personal info + optional vehicle details.
class ApplyDriverScreen extends ConsumerStatefulWidget {
  const ApplyDriverScreen({super.key});

  @override
  ConsumerState<ApplyDriverScreen> createState() => _ApplyDriverScreenState();
}

class _ApplyDriverScreenState extends ConsumerState<ApplyDriverScreen> {
  final _formKey = GlobalKey<FormState>();

  // Personal info controllers
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();

  // Vehicle controllers
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();

  String? _selectedVehicleType;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  /// Tracks picked files per document type
  final Map<String, File> _pickedDocuments = {};

  static const _documentTypes = [
    ('profile_photo', 'Profile Photo', Icons.person),
    ('drivers_license', "Driver's License", Icons.badge),
    ('national_id', 'National ID', Icons.credit_card),
    ('vehicle_registration', 'Vehicle Registration', Icons.description),
    (
      'vehicle_photo_external',
      'Vehicle Photo (External)',
      Icons.directions_car,
    ),
    (
      'vehicle_photo_internal',
      'Vehicle Photo (Internal)',
      Icons.airline_seat_recline_normal,
    ),
    ('insurance', 'Insurance', Icons.shield),
    ('vehicle_inspection', 'Vehicle Inspection', Icons.fact_check),
  ];

  static const _vehicleTypes = [
    ('sedan', 'Sedan'),
    ('suv', 'SUV'),
    ('van', 'Van'),
    ('luxury', 'Luxury'),
    ('motorcycle', 'Motorcycle'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefillFromProfile());
  }

  /// Prefill form fields from cached driver profile (if reapplying / editing).
  void _prefillFromProfile() {
    final appStatus = ref.read(driverNotifierProvider).applicationStatus;
    if (appStatus == null) return;

    final profile = appStatus['driverProfile'] as Map<String, dynamic>?;
    if (profile == null) return;

    final user = profile['user'] as Map<String, dynamic>? ?? profile;

    setState(() {
      _firstNameCtrl.text = (user['firstName'] as String?) ?? '';
      _lastNameCtrl.text = (user['lastName'] as String?) ?? '';
      _dobCtrl.text = _extractDateOnly(user['dateOfBirth'] as String?);

      // Vehicle data
      final vehicle = profile['vehicle'] as Map<String, dynamic>?;
      if (vehicle != null) {
        final vType = vehicle['type'] as String?;
        if (vType != null && _vehicleTypes.any((t) => t.$1 == vType)) {
          _selectedVehicleType = vType;
        }
        _makeCtrl.text = (vehicle['make'] as String?) ?? '';
        _modelCtrl.text = (vehicle['model'] as String?) ?? '';
        _yearCtrl.text = (vehicle['year']?.toString()) ?? '';
        _colorCtrl.text = (vehicle['color'] as String?) ?? '';
        _plateCtrl.text = (vehicle['licensePlate'] as String?) ?? '';
      }
    });
  }

  /// Extract "YYYY-MM-DD" from an ISO date string.
  String _extractDateOnly(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _dobCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _colorCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 18),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.accent,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _dobCtrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final vehicle = {
      'type': _selectedVehicleType,
      'make': _makeCtrl.text.trim(),
      'model': _modelCtrl.text.trim(),
      'year': int.tryParse(_yearCtrl.text.trim()),
      'color': _colorCtrl.text.trim(),
      'licensePlate': _plateCtrl.text.trim(),
    };

    final success = await ref
        .read(driverNotifierProvider.notifier)
        .applyAsDriver(
          firstName: _firstNameCtrl.text.trim().isEmpty
              ? null
              : _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim().isEmpty
              ? null
              : _lastNameCtrl.text.trim(),
          dateOfBirth: _dobCtrl.text.trim().isEmpty
              ? null
              : _dobCtrl.text.trim(),
          vehicle: vehicle,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      // Upload any picked documents after successful application
      if (_pickedDocuments.isNotEmpty) {
        final notifier = ref.read(driverNotifierProvider.notifier);
        for (final entry in _pickedDocuments.entries) {
          await notifier.uploadDocument(
            documentFile: entry.value,
            type: entry.key,
          );
        }
      }
      // Pop back to verify screen which will refresh and show pending status
      if (mounted) context.pop(true);
      return;
    } else {
      final error = ref.read(driverNotifierProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to submit application'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Apply as Driver',
          style: TextStyles.h2.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Personal Info Card ──
            _card(
              title: 'Personal Information',
              children: [
                _fieldLabel('First Name'),
                TextFormField(
                  controller: _firstNameCtrl,
                  decoration: _inputDecoration('e.g. Favour'),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) {
                    if (v != null &&
                        v.trim().isNotEmpty &&
                        v.trim().length < 2) {
                      return 'Min 2 characters';
                    }
                    return null;
                  },
                ),
                const Gap(14),
                _fieldLabel('Last Name'),
                TextFormField(
                  controller: _lastNameCtrl,
                  decoration: _inputDecoration('e.g. Ben'),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) {
                    if (v != null &&
                        v.trim().isNotEmpty &&
                        v.trim().length < 2) {
                      return 'Min 2 characters';
                    }
                    return null;
                  },
                ),
                const Gap(14),
                _fieldLabel('Date of Birth'),
                TextFormField(
                  controller: _dobCtrl,
                  decoration: _inputDecoration('YYYY-MM-DD').copyWith(
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.calendar_today_outlined,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: _pickDate,
                    ),
                  ),
                  readOnly: true,
                  onTap: _pickDate,
                ),
              ],
            ),

            // ── Vehicle Card ──
            const Gap(16),
            _card(
              title: 'Vehicle Details',
              children: [
                _fieldLabel('Vehicle Type'),
                DropdownButtonFormField<String>(
                  value: _selectedVehicleType,
                  decoration: _inputDecoration('Select type'),
                  items: _vehicleTypes
                      .map(
                        (t) => DropdownMenuItem(value: t.$1, child: Text(t.$2)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedVehicleType = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                const Gap(14),
                _fieldLabel('Make'),
                TextFormField(
                  controller: _makeCtrl,
                  decoration: _inputDecoration('e.g. Toyota'),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? 'Min 2 characters'
                      : null,
                ),
                const Gap(14),
                _fieldLabel('Model'),
                TextFormField(
                  controller: _modelCtrl,
                  decoration: _inputDecoration('e.g. Corolla'),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? 'Min 2 characters'
                      : null,
                ),
                const Gap(14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Year'),
                          TextFormField(
                            controller: _yearCtrl,
                            decoration: _inputDecoration('e.g. 2021'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            validator: (v) {
                              final year = int.tryParse(v ?? '');
                              if (year == null ||
                                  year < 2000 ||
                                  year > DateTime.now().year + 1) {
                                return 'Invalid year';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Color'),
                          TextFormField(
                            controller: _colorCtrl,
                            decoration: _inputDecoration('e.g. White'),
                            textCapitalization: TextCapitalization.words,
                            validator: (v) => (v == null || v.trim().length < 2)
                                ? 'Min 2 chars'
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Gap(14),
                _fieldLabel('License Plate'),
                TextFormField(
                  controller: _plateCtrl,
                  decoration: _inputDecoration('e.g. KJA-456-AB'),
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? 'Min 2 characters'
                      : null,
                ),
              ],
            ),

            // ── Documents Card ──
            const Gap(16),
            _card(
              title: 'Documents',
              children: [
                Text(
                  'Upload your documents to speed up verification.',
                  style: TextStyles.t2.copyWith(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Gap(12),
                ...List.generate(_documentTypes.length, (i) {
                  final (type, label, icon) = _documentTypes[i];
                  final picked = _pickedDocuments[type];
                  return Column(
                    children: [
                      if (i > 0)
                        const Divider(height: 1, color: AppColors.divider),
                      _buildDocumentPickTile(
                        type: type,
                        label: label,
                        icon: icon,
                        pickedFile: picked,
                      ),
                    ],
                  );
                }),
              ],
            ),

            const Gap(32),

            // ── Submit ──
            CustomButton(
              text: 'Submit Application',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),

            const Gap(16),

            Center(
              child: Text(
                'Your application will be reviewed by our team.\nThis typically takes 1–3 business days.',
                textAlign: TextAlign.center,
                style: TextStyles.t2.copyWith(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),

            const Gap(32),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──

  Widget _card({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Corners.c20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyles.t1.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Gap(4),
          const Divider(color: AppColors.divider),
          const Gap(8),
          ...children,
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyles.t2.copyWith(
          fontSize: 13,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyles.t2.copyWith(
        color: AppColors.textLight,
        fontSize: 14,
      ),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Corners.c20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Corners.c20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Corners.c20),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Corners.c20),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Corners.c20),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  // ── Document Pick Tile ──

  Widget _buildDocumentPickTile({
    required String type,
    required String label,
    required IconData icon,
    File? pickedFile,
  }) {
    final hasPicked = pickedFile != null;

    return InkWell(
      onTap: () => _pickDocumentImage(type),
      borderRadius: BorderRadius.circular(Corners.c8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (hasPicked ? AppColors.success : AppColors.accent)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Corners.c8),
              ),
              child: Icon(
                hasPicked ? Icons.check_circle : icon,
                color: hasPicked ? AppColors.success : AppColors.accent,
                size: 20,
              ),
            ),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyles.t1.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    hasPicked
                        ? pickedFile.path.split('/').last
                        : 'Tap to select',
                    style: TextStyles.t2.copyWith(
                      fontSize: 12,
                      color: hasPicked
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              hasPicked ? Icons.close : Icons.cloud_upload_outlined,
              color: hasPicked ? AppColors.textSecondary : AppColors.accent,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDocumentImage(String type) async {
    // If already picked, tapping removes it
    if (_pickedDocuments.containsKey(type)) {
      setState(() => _pickedDocuments.remove(type));
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Corners.c20)),
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
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _pickedDocuments[type] = File(picked.path));
  }
}
