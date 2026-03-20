import 'package:drup/core/widgets/custom_button.dart';
import 'package:drup/di/notifiers.dart';
import 'package:drup/features/passenger/model/delivery_api_models.dart';
import 'package:drup/features/passenger/ui/bottomsheets/delivery_detail_bottomsheet.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegisterDeliveryScreen extends ConsumerStatefulWidget {
  const RegisterDeliveryScreen({super.key});

  @override
  ConsumerState<RegisterDeliveryScreen> createState() =>
      _RegisterDeliveryScreenState();
}

class _RegisterDeliveryScreenState
    extends ConsumerState<RegisterDeliveryScreen> {
  final _recipientTextController = TextEditingController();
  final _phoneTextController = TextEditingController();
  final _packageDescriptionController = TextEditingController();
  final _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final rideState = ref.watch(rideNotifierProvider);

    final pickUpAddress = rideState.pickupLocation?.name ?? '';
    final dropOffAddress = rideState.dropoffLocation?.name ?? '';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.0,
        centerTitle: true,
        title: Text(
          'Fill delivery form',
          style: TextStyles.t1.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16,
            top: 8,
          ),
          child: CustomButton(
            text: 'Continue',
            isLoading: rideState.isLoading,
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                final bookedDelivery = await ref
                    .read(rideNotifierProvider.notifier)
                    .bookDelivery(
                      recipientName: _recipientTextController.text.trim(),
                      recipientPhone: _phoneTextController.text.trim(),
                      packageDescription: _packageDescriptionController.text
                          .trim(),
                      comment: _commentController.text.trim(),
                    );

                if (bookedDelivery == null) return;

                if (context.mounted) {
                  Navigator.of(context).pop();
                  _showBookDetailBottomsheet(
                    context: context,
                    bookedDelivery: bookedDelivery,
                  );
                }
              }
            },
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Route card ─────────────────────────────────────────────
            _buildRouteCard(pickUpAddress, dropOffAddress),
            const Gap(12),

            // ── Recipient card ─────────────────────────────────────────
            _buildRecipientCard(),
            const Gap(12),

            // ── Package card ───────────────────────────────────────────
            _buildPackageCard(),
            const Gap(32),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Route card – pickup & dropoff with dot-line
  // ---------------------------------------------------------------------------

  Widget _buildRouteCard(String pickup, String dropoff) {
    return _card(
      title: 'Route',
      icon: Icons.route_outlined,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dots + line
            Column(
              children: [
                Container(
                  height: 18,
                  width: 18,
                  decoration: const BoxDecoration(
                    color: AppColors.pickupMarker,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.circle, color: Colors.white, size: 8),
                ),
                Expanded(child: Container(width: 2, color: AppColors.divider)),
                const Icon(
                  Icons.location_on,
                  size: 22,
                  color: AppColors.red400,
                ),
              ],
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pickup',
                    style: TextStyles.t2.copyWith(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    pickup.isNotEmpty ? pickup : 'Pickup Address',
                    style: TextStyles.t2.copyWith(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(16),
                  Text(
                    'Dropoff',
                    style: TextStyles.t2.copyWith(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    dropoff.isNotEmpty ? dropoff : 'Dropoff Address',
                    style: TextStyles.t2.copyWith(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Recipient card
  // ---------------------------------------------------------------------------

  Widget _buildRecipientCard() {
    return _card(
      title: 'Recipient',
      icon: Icons.person_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Recipient Name'),
          const Gap(6),
          TextFormField(
            controller: _recipientTextController,
            autofocus: true,
            autocorrect: false,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Recipient name is required';
              }
              return null;
            },
            decoration: _inputDecoration('Enter recipient name'),
            style: _inputTextStyle,
          ),
          const Gap(14),
          _fieldLabel('Phone Number'),
          const Gap(6),
          TextFormField(
            controller: _phoneTextController,
            autocorrect: false,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Phone number is required';
              }
              if (value.trim().length < 10) {
                return 'Enter a valid phone number';
              }
              return null;
            },
            decoration: _inputDecoration('Enter phone number'),
            style: _inputTextStyle,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Package card
  // ---------------------------------------------------------------------------

  Widget _buildPackageCard() {
    return _card(
      title: 'Package',
      icon: Icons.inventory_2_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Description'),
          const Gap(6),
          TextFormField(
            controller: _packageDescriptionController,
            autocorrect: false,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.sentences,
            maxLines: null,
            minLines: 1,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Package description is required';
              }
              return null;
            },
            decoration: _inputDecoration('Describe your package'),
            style: _inputTextStyle,
          ),
          const Gap(14),
          _fieldLabel('Comment (optional)'),
          const Gap(6),
          TextFormField(
            controller: _commentController,
            autocorrect: false,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.sentences,
            maxLines: null,
            minLines: 1,
            decoration: _inputDecoration('Leave a comment'),
            style: _inputTextStyle,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Reusable helpers
  // ---------------------------------------------------------------------------

  Widget _card({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Gap(14),
          child,
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: TextStyles.t2.copyWith(
        fontSize: 13,
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Corners.c8),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Corners.c20),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Corners.c20),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Corners.c20),
        borderSide: const BorderSide(color: AppColors.red400),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Corners.c20),
        borderSide: const BorderSide(color: AppColors.red400, width: 1.5),
      ),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      hintText: hint,
      hintStyle: TextStyles.t2.copyWith(
        color: AppColors.textLight,
        fontSize: 14,
      ),
    );
  }

  TextStyle get _inputTextStyle =>
      TextStyles.t2.copyWith(color: AppColors.onAccent, fontSize: 14);

  void _showBookDetailBottomsheet({
    required BuildContext context,
    required BookedDelivery bookedDelivery,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          DeliveryDetailBottomsheet(bookedDelivery: bookedDelivery),
    );
  }
}
