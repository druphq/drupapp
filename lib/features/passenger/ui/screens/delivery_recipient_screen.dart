import 'package:drup/core/widgets/custom_button.dart';
import 'package:drup/di/notifiers.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:drup/utils/extension.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeliveryRecipientScreen extends ConsumerStatefulWidget {
  const DeliveryRecipientScreen({super.key});

  @override
  ConsumerState<DeliveryRecipientScreen> createState() =>
      _DeliveryRecipientScreenState();
}

class _DeliveryRecipientScreenState
    extends ConsumerState<DeliveryRecipientScreen> {
  final _contactController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final rideState = ref.watch(rideNotifierProvider);

    final pickUpAddress = rideState.pickupLocation?.name ?? '';
    final dropOffAddress = rideState.dropoffLocation?.name ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Enter Recipient\'s Contact',
          style: TextStyles.t1.copyWith(fontSize: FontSizes.s18),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pickup & Dropoff
              if (pickUpAddress.isNotEmptyOrNull ||
                  dropOffAddress.isNotEmptyOrNull) ...[
                _buildLocationRow(
                  Icons.circle,
                  pickUpAddress,
                  AppColors.pickupMarker,
                ),
                Container(
                  margin: const EdgeInsets.only(left: 11),
                  height: 20,
                  width: 2,
                  color: AppColors.divider,
                ),
                _buildLocationRow(
                  Icons.location_on,
                  dropOffAddress,
                  AppColors.destinationMarker,
                ),
                const Gap(12),
              ],
            ],
          ),

          Gap(20),
          TextField(
            controller: _contactController,
            autofocus: true,
            autocorrect: false,
            keyboardType: TextInputType.streetAddress,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Corners.lg),
                borderSide: BorderSide(color: AppColors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Corners.lg),
                borderSide: BorderSide(color: AppColors.accent, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              hintText: 'Phone number',
              hintStyle: TextStyles.t2.copyWith(
                color: AppColors.textSecondary,
                fontSize: FontSizes.s16,
              ),
            ),
            style: TextStyles.t2.copyWith(
              color: AppColors.onAccent,
              fontSize: FontSizes.s16,
              fontWeight: FontWeight.w600,
            ),
          ),

          Gap(32),
          CustomButton(text: 'Continue ', onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String address, Color color) {
    return Row(
      children: [
        Icon(icon, size: 24, color: color),
        const Gap(12),
        Expanded(
          child: Text(
            address,
            style: TextStyles.t2.copyWith(fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
