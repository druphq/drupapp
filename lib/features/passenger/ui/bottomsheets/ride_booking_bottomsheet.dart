import 'package:drup/core/widgets/custom_button.dart';
import 'package:drup/di/notifiers.dart';
import 'package:drup/features/passenger/model/ride_api_models.dart';
import 'package:drup/features/passenger/provider/ride_notifier.dart';
import 'package:drup/features/passenger/ui/bottomsheets/ride_confirmation_bottomsheet.dart';
import 'package:drup/features/passenger/ui/bottomsheets/ride_detail_bottomsheet.dart';
import 'package:drup/features/passenger/ui/widgets/connect_driver_widget.dart';
import 'package:drup/features/passenger/ui/widgets/driver_matched_widget.dart';
import 'package:drup/features/passenger/ui/widgets/home_content_widget.dart';
import 'package:drup/features/passenger/ui/widgets/ride_card_widget.dart';
import 'package:drup/features/passenger/ui/widgets/search_ride_widget.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/router/app_routes.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class RideBookingBottomsheet extends ConsumerStatefulWidget {
  const RideBookingBottomsheet({
    super.key,
    this.onClose,
    this.onWhereToTap,
    this.onScheduleRide,
    this.onEditRide,
  });
  final VoidCallback? onWhereToTap;
  final VoidCallback? onScheduleRide;
  final VoidCallback? onEditRide;
  final VoidCallback? onClose;

  @override
  ConsumerState<RideBookingBottomsheet> createState() =>
      _RideBookingBottomsheetState();
}

class _RideBookingBottomsheetState
    extends ConsumerState<RideBookingBottomsheet> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  Widget _buildContent() {
    final rideState = ref.watch(rideNotifierProvider);

    if (rideState.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => showErrorSnackbar(rideState.errorMessage!),
      );
    }

    switch (rideState.rideScheduleState) {
      case RideScheduleState.idle:
        return HomeContentWidget(
          onRideTapped: () {
            context.push(AppRoutes.pickRideLocationRoute);
          },
          onDeliveryTapped: () {
            context.push(AppRoutes.pickDeliveryLocationRoute);
          },
        );

      case RideScheduleState.showConfirmRoutes:
        return RideConfirmationBottomSheet(
          pickupLocation: rideState.pickupLocation?.name ?? '',
          destinationLocation: rideState.dropoffLocation?.name ?? '',
          isLoading: rideState.isLoading,
          estimate: rideState.fareEstimates.isNotEmpty
              ? rideState.fareEstimates[0]
              : null,
          onScheduleRide: widget.onScheduleRide,
          onEditRide: () {
            widget.onEditRide?.call();
          },
        );

      case RideScheduleState.showSearchingRide:
        return SearchRideWidget(
          isSlotSelected: rideState.selectedRideSlot != null,
        );

      case RideScheduleState.showAvailableRides:
        return _buildAvailableRidesState(
          ride: rideState,
          selectedRideSlot: rideState.selectedRideSlot,
          rideSlots: rideState.rideSlots,
        );

      case RideScheduleState
          .showConnectingDriver: // connectingDriver and driverMatched are not used
        return ConnectDriverWidget();

      case RideScheduleState.showDriverMatched:
        return DriverMatchedWidget();
    }
  }

  Widget _buildAvailableRidesState({
    required RideState ride,
    RideSlot? selectedRideSlot,
    List<RideSlot> rideSlots = const [],
  }) {
    return Container(
      alignment: Alignment.topCenter,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Corners.lg),
          topRight: Radius.circular(Corners.lg),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Gap(30.0),

          ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            primary: false,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final rideSlot = rideSlots[index];
              return RideCardWidget(
                isIndividual: index == 0,
                isSelected: selectedRideSlot?.rideType == rideSlot.rideType,
                rideSlot: rideSlot,
                onTap: () {
                  ref
                      .read(rideNotifierProvider.notifier)
                      .setSelectedRideSlot(rideSlot);
                },
              );
            },
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: AppColors.textSecondary.withValues(alpha: 0.2),
              thickness: 0.5,
            ),
            itemCount: rideSlots.length,
          ),

          Gap(20.0),

          // Schedule Ride Button
          CustomButton(
            text: 'Continue',
            onPressed: () async {
              if (selectedRideSlot == null) {
                showErrorSnackbar('Please select a ride');
                return;
              }

              final result = await ref
                  .read(rideNotifierProvider.notifier)
                  .bookRide(rideType: selectedRideSlot.rideType!);

              if (result != null) {
                _showBookDetailBottomsheet(result);
              }
            },
            isLoading: ride.isLoading,
            progressColor: AppColors.accent,
            backgroundColor: selectedRideSlot != null
                ? AppColors.accent
                : AppColors.accentLighter,
            textStyle: TextStyles.btnStyle.copyWith(color: AppColors.white),
          ),
          Gap(MediaQuery.of(context).size.height * 0.06),
        ],
      ),
    );
  }

  void _showBookDetailBottomsheet(BookedRide bookedRide) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RideDetailBottomsheet(bookedRide: bookedRide),
    );
  }

  // show action snackbar for errors
  void showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyles.body2.copyWith(fontSize: 14.0),
        ),
      ),
    );
  }
}
