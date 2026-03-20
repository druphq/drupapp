import 'package:drup/core/widgets/custom_button.dart';
import 'package:drup/features/drivers/provider/driver_notifier.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class VehicleInfoScreen extends ConsumerStatefulWidget {
  const VehicleInfoScreen({super.key});

  @override
  ConsumerState<VehicleInfoScreen> createState() => _VehicleInfoScreenState();
}

class _VehicleInfoScreenState extends ConsumerState<VehicleInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;

  late TextEditingController _makeController;
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  late TextEditingController _colorController;
  late TextEditingController _licensePlateController;
  String _selectedType = 'sedan';

  final List<String> _vehicleTypes = [
    'sedan',
    'suv',
    'van',
    'luxury',
    'motorcycle',
  ];

  @override
  void initState() {
    super.initState();
    _makeController = TextEditingController();
    _modelController = TextEditingController();
    _yearController = TextEditingController();
    _colorController = TextEditingController();
    _licensePlateController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadVehicleInfo());
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _licensePlateController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicleInfo() async {
    setState(() => _isLoading = true);
    await ref.read(driverNotifierProvider.notifier).fetchVehicleInfo();
    final driver = ref.read(driverNotifierProvider).driver;
    final vehicle = driver?.vehicle;

    if (vehicle != null) {
      _makeController.text = vehicle.make ?? '';
      _modelController.text = vehicle.model ?? '';
      _yearController.text = vehicle.year?.toString() ?? '';
      _colorController.text = vehicle.color ?? '';
      _licensePlateController.text = vehicle.licensePlate ?? '';
      _selectedType = vehicle.type ?? 'sedan';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveVehicleInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final success = await ref
        .read(driverNotifierProvider.notifier)
        .updateVehicleInfo(
          type: _selectedType,
          make: _makeController.text.trim(),
          model: _modelController.text.trim(),
          year: int.tryParse(_yearController.text.trim()),
          color: _colorController.text.trim(),
          licensePlate: _licensePlateController.text.trim(),
        );

    setState(() {
      _isSaving = false;
      if (success) _isEditing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Vehicle info updated successfully!'
                : ref.read(driverNotifierProvider).errorMessage ??
                    'Failed to update',
          ),
          backgroundColor: success ? AppColors.success : AppColors.warning,
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
        centerTitle: true,
        scrolledUnderElevation: 0.0,
        backgroundColor: AppColors.surface,
        title: Text('Vehicle Info', style: TextStyles.t1),
        actions: [
          if (!_isEditing && !_isLoading)
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vehicle status card
                    _buildStatusCard(),
                    const Gap(16),

                    // Vehicle details card
                    _buildDetailsCard(),
                    const Gap(24),

                    // Save button
                    if (_isEditing)
                      CustomButton(
                        text: 'Save Changes',
                        onPressed: _saveVehicleInfo,
                        isLoading: _isSaving,
                      ),
                    const Gap(32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    final driver = ref.watch(driverNotifierProvider).driver;
    final vehicle = driver?.vehicle;
    final isVerified = vehicle?.isVerified ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Corners.c20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isVerified ? AppColors.success : AppColors.accent)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Corners.c8),
            ),
            child: Icon(
              isVerified ? Icons.verified : Icons.directions_car,
              color: isVerified ? AppColors.success : AppColors.accent,
              size: 28,
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle?.fullDisplayName ?? 'No Vehicle Added',
                  style: TextStyles.t1.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (isVerified ? AppColors.success : AppColors.accent)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(Corners.c4),
                      ),
                      child: Text(
                        isVerified ? 'Verified' : 'Pending Verification',
                        style: TextStyles.t2.copyWith(
                          fontSize: 12,
                          color: isVerified ? AppColors.success : AppColors.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (vehicle?.licensePlate != null) ...[
                      const Gap(8),
                      Text(
                        vehicle!.licensePlate!,
                        style: TextStyles.t2.copyWith(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Corners.c20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle Details',
            style: TextStyles.t1.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(20),

          // Vehicle Type
          _buildLabel('Vehicle Type'),
          const Gap(8),
          _isEditing
              ? DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: _inputDecoration(),
                  items: _vehicleTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(
                        type[0].toUpperCase() + type.substring(1),
                        style: TextStyles.t1.copyWith(fontSize: 16),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedType = val);
                  },
                )
              : _buildReadOnlyField(
                  _selectedType[0].toUpperCase() + _selectedType.substring(1),
                ),
          const Gap(16),

          // Make
          _buildLabel('Make'),
          const Gap(8),
          _isEditing
              ? TextFormField(
                  controller: _makeController,
                  style: TextStyles.t1.copyWith(fontSize: 16),
                  decoration: _inputDecoration(hint: 'e.g. Toyota'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                )
              : _buildReadOnlyField(_makeController.text),
          const Gap(16),

          // Model
          _buildLabel('Model'),
          const Gap(8),
          _isEditing
              ? TextFormField(
                  controller: _modelController,
                  style: TextStyles.t1.copyWith(fontSize: 16),
                  decoration: _inputDecoration(hint: 'e.g. Corolla'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                )
              : _buildReadOnlyField(_modelController.text),
          const Gap(16),

          // Year
          _buildLabel('Year'),
          const Gap(8),
          _isEditing
              ? TextFormField(
                  controller: _yearController,
                  style: TextStyles.t1.copyWith(fontSize: 16),
                  decoration: _inputDecoration(hint: 'e.g. 2021'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final year = int.tryParse(v);
                    if (year == null || year < 1990 || year > 2030) {
                      return 'Enter a valid year';
                    }
                    return null;
                  },
                )
              : _buildReadOnlyField(_yearController.text),
          const Gap(16),

          // Color
          _buildLabel('Color'),
          const Gap(8),
          _isEditing
              ? TextFormField(
                  controller: _colorController,
                  style: TextStyles.t1.copyWith(fontSize: 16),
                  decoration: _inputDecoration(hint: 'e.g. White'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                )
              : _buildReadOnlyField(_colorController.text),
          const Gap(16),

          // License Plate
          _buildLabel('License Plate'),
          const Gap(8),
          _isEditing
              ? TextFormField(
                  controller: _licensePlateController,
                  style: TextStyles.t1.copyWith(fontSize: 16),
                  decoration: _inputDecoration(hint: 'e.g. ABC-123-XY'),
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                )
              : _buildReadOnlyField(_licensePlateController.text),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyles.t2.copyWith(
        fontSize: 14,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildReadOnlyField(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        value.isNotEmpty ? value : '—',
        style: TextStyles.t1.copyWith(
          fontSize: 16,
          color: value.isNotEmpty ? AppColors.textPrimary : AppColors.textSecondary,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyles.t2.copyWith(
        fontSize: 14,
        color: AppColors.textSecondary.withValues(alpha: 0.5),
      ),
      filled: true,
      fillColor: AppColors.surface,
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
    );
  }
}
