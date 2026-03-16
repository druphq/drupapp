import 'package:drup/core/widgets/custom_button.dart';
import 'package:drup/di/notifiers.dart';
import 'package:drup/features/passenger/model/delivery_api_models.dart';
import 'package:drup/features/passenger/ui/bottomsheets/delivery_detail_bottomsheet.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:drup/utils/extension.dart';
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

  @override
  Widget build(BuildContext context) {
    final rideState = ref.watch(rideNotifierProvider);

    final pickUpAddress = rideState.pickupLocation?.name ?? '';
    final dropOffAddress = rideState.dropoffLocation?.name ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Fill Delivery Request',
          style: TextStyles.t1.copyWith(fontSize: FontSizes.s18),
        ),
        centerTitle: true,
        scrolledUnderElevation: 0.0,
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(left: 16, right: 16, bottom: 30),
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

              if (bookedDelivery == null) {
                return;
              }

              if (context.mounted) {
                Navigator.of(context).pop(); // Close the bottom sheet

                _showBookDetailBottomsheet(
                  context: context,
                  bookedDelivery: bookedDelivery,
                );
              }
            }
          },
        ),
      ),

      backgroundColor: context.colorScheme.surface,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Address',
              style: TextStyles.body1.copyWith(fontSize: FontSizes.s14),
            ),
            Gap(8.0),
            // Pickup & Dropoff
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Corners.lg),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pickup & Dropoff
                  if (pickUpAddress.isNotEmptyOrNull ||
                      dropOffAddress.isNotEmptyOrNull) ...[
                    _buildLocationRow(
                      Icons.circle,
                      'Pickup Address',
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
                      'Dropoff Address',
                      dropOffAddress,
                      AppColors.destinationMarker,
                    ),
                    const Gap(12),
                  ],
                ],
              ),
            ),

            Gap(20),

            Text(
              'Recipient',
              style: TextStyles.body1.copyWith(fontSize: FontSizes.s14),
            ),

            Gap(8.0),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Corners.lg),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recipient Name',
                    style: TextStyles.body1.copyWith(fontSize: FontSizes.s14),
                  ),
                  const Gap(8),
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
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Corners.lg),
                        borderSide: BorderSide(color: AppColors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Corners.lg),
                        borderSide: BorderSide(
                          color: AppColors.accent,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16.0,
                      ),
                      hintText: 'Recipient Name',
                      hintStyle: TextStyles.t2.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: FontSizes.s16,
                      ),
                    ),
                    style: TextStyles.t2.copyWith(
                      color: AppColors.onAccent,
                      fontSize: FontSizes.s16,
                    ),
                  ),
                  Gap(10.0),
                  Text(
                    'Phone Number',
                    style: TextStyles.body1.copyWith(fontSize: FontSizes.s14),
                  ),
                  const Gap(8),
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
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Corners.lg),
                        borderSide: BorderSide(color: AppColors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Corners.lg),
                        borderSide: BorderSide(
                          color: AppColors.accent,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16.0,
                      ),
                      hintText: 'Phone Number',
                      hintStyle: TextStyles.t2.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: FontSizes.s16,
                      ),
                    ),
                    style: TextStyles.t2.copyWith(
                      color: AppColors.onAccent,
                      fontSize: FontSizes.s16,
                    ),
                  ),
                ],
              ),
            ),

            Gap(16.0),

            Text(
              'Package',
              style: TextStyles.body1.copyWith(fontSize: FontSizes.s14),
            ),

            Gap(8.0),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Corners.lg),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Package Description',
                    style: TextStyles.t2.copyWith(fontSize: FontSizes.s16),
                  ),
                  const Gap(8),
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
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Corners.lg),
                        borderSide: BorderSide(color: AppColors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Corners.lg),
                        borderSide: BorderSide(
                          color: AppColors.accent,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16.0,
                      ),
                      hintText: 'Package Description',
                      hintStyle: TextStyles.t2.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: FontSizes.s16,
                      ),
                    ),
                    style: TextStyles.t2.copyWith(
                      color: AppColors.onAccent,
                      fontSize: FontSizes.s16,
                    ),
                  ),
                  Gap(16.0),

                  Text(
                    'Comment',
                    style: TextStyles.t2.copyWith(fontSize: FontSizes.s16),
                  ),
                  const Gap(8),
                  TextFormField(
                    controller: _commentController,
                    autocorrect: false,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: null,
                    minLines: 1,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Corners.lg),
                        borderSide: BorderSide(color: AppColors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Corners.lg),
                        borderSide: BorderSide(
                          color: AppColors.accent,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16.0,
                      ),
                      hintText: 'Leave a comment',
                      hintStyle: TextStyles.t2.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: FontSizes.s16,
                      ),
                    ),
                    style: TextStyles.t2.copyWith(
                      color: AppColors.onAccent,
                      fontSize: FontSizes.s16,
                    ),
                  ),
                ],
              ),
            ),

            Gap(32),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(
    IconData icon,
    String title,
    String address,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 24, color: color),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                address,
                style: TextStyles.t2.copyWith(fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // Gap(4.0),
              // Text(
              //   title,
              //   style: TextStyles.body2,
              //   maxLines: 1,
              //   overflow: TextOverflow.ellipsis,
              // ),
            ],
          ),
        ),
      ],
    );
  }

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
