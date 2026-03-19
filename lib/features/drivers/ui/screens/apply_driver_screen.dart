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
  bool _includeVehicle = false;
  bool _isSubmitting = false;

  static const _vehicleTypes = [
    ('sedan', 'Sedan'),
    ('suv', 'SUV'),
    ('van', 'Van'),
    ('luxury', 'Luxury'),
    ('motorcycle', 'Motorcycle'),
  ];

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

    Map<String, dynamic>? vehicle;
    if (_includeVehicle) {
      vehicle = {
        'type': _selectedVehicleType,
        'make': _makeCtrl.text.trim(),
        'model': _modelCtrl.text.trim(),
        'year': int.tryParse(_yearCtrl.text.trim()),
        'color': _colorCtrl.text.trim(),
        'licensePlate': _plateCtrl.text.trim(),
      };
    }

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
      // Pop back to verify screen which will refresh and show pending status
      context.pop(true);
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

            const Gap(16),

            // ── Vehicle Toggle ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Corners.c20),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.directions_car_outlined,
                    size: 20,
                    color: AppColors.accent,
                  ),
                  const Gap(10),
                  Expanded(
                    child: Text(
                      'Add vehicle details now',
                      style: TextStyles.t1.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: _includeVehicle,
                    activeColor: AppColors.accent,
                    onChanged: (v) => setState(() => _includeVehicle = v),
                  ),
                ],
              ),
            ),

            // ── Vehicle Card ──
            if (_includeVehicle) ...[
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
                          (t) =>
                              DropdownMenuItem(value: t.$1, child: Text(t.$2)),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedVehicleType = v),
                    validator: (v) =>
                        _includeVehicle && v == null ? 'Required' : null,
                  ),
                  const Gap(14),
                  _fieldLabel('Make'),
                  TextFormField(
                    controller: _makeCtrl,
                    decoration: _inputDecoration('e.g. Toyota'),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        _includeVehicle && (v == null || v.trim().length < 2)
                        ? 'Min 2 characters'
                        : null,
                  ),
                  const Gap(14),
                  _fieldLabel('Model'),
                  TextFormField(
                    controller: _modelCtrl,
                    decoration: _inputDecoration('e.g. Corolla'),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        _includeVehicle && (v == null || v.trim().length < 2)
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
                                if (!_includeVehicle) return null;
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
                              validator: (v) =>
                                  _includeVehicle &&
                                      (v == null || v.trim().length < 2)
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
                    validator: (v) =>
                        _includeVehicle && (v == null || v.trim().length < 2)
                        ? 'Min 2 characters'
                        : null,
                  ),
                ],
              ),
            ],

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
                'Your application will be reviewed by our team.\nYou can add vehicle details later if needed.',
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
}
