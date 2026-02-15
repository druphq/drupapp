import 'package:drup/core/widgets/custom_button.dart';
import 'package:drup/features/passenger/model/ride_api_models.dart';
import 'package:drup/features/passenger/provider/ride_notifier.dart';
import 'package:drup/features/passenger/ui/bottomsheets/ride_detail_bottomsheet.dart';
import 'package:drup/features/passenger/ui/widgets/connect_driver_widget.dart';
import 'package:drup/features/passenger/ui/widgets/driver_matched_widget.dart';
import 'package:drup/features/passenger/ui/widgets/ride_card_widget.dart';
import 'package:drup/features/passenger/ui/widgets/search_ride_widget.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class RideBookingBottomsheet extends ConsumerStatefulWidget {
  const RideBookingBottomsheet({super.key, this.onClose});
  final VoidCallback? onClose;

  @override
  ConsumerState<RideBookingBottomsheet> createState() =>
      _RideBookingBottomsheetState();
}

class _RideBookingBottomsheetState
    extends ConsumerState<RideBookingBottomsheet> {
  final _sheetController = DraggableScrollableController();

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _expandSheet() {
    if (_sheetController.isAttached && _sheetController.size < 0.85) {
      _sheetController.animateTo(
        0.85,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _collapseSheet() {
    if (_sheetController.isAttached && _sheetController.size > 0.35) {
      _sheetController.animateTo(
        0.35,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.5,
      minChildSize: 0.45,
      maxChildSize: 1.0,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(Corners.lg),
              topRight: Radius.circular(Corners.lg),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              Gap(30.0),

              // Handle bar with close button
              // Padding(
              //   padding: EdgeInsets.symmetric(horizontal: 16),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.center,
              //     children: [
              //       Container(
              //         width: 40,
              //         height: 4,
              //         decoration: BoxDecoration(
              //           color: AppColors.greyStrong,
              //           borderRadius: BorderRadius.circular(2),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              // Gap(16.0),

              Expanded(child: _buildContent(scrollController)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(ScrollController scrollController) {
    final rideState = ref.watch(rideNotifierProvider);

    if (rideState.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => showErrorSnackbar(rideState.errorMessage!),
      );
    }

    switch (rideState.rideScheduleState) {
      case RideScheduleState.searching:
        WidgetsBinding.instance.addPostFrameCallback((_) => _collapseSheet());
        return SearchRideWidget(
          isSlotSelected: rideState.selectedRideSlot != null,
        );
      case RideScheduleState.availableRides:
        return _buildAvailableRidesState(
          ride: rideState,
          selectedRideSlot: rideState.selectedRideSlot,
          rideSlots: rideState.rideSlots,
        );
      case RideScheduleState.rideBooked:
        WidgetsBinding.instance.addPostFrameCallback((_) => _expandSheet());
        return RideDetailBottomsheet(bookedRide: rideState.bookedRide);
      case RideScheduleState
          .connectingDriver: // connectingDriver and driverMatched are not used
        return ConnectDriverWidget();
      case RideScheduleState.driverMatched:
        return DriverMatchedWidget();
      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildAvailableRidesState({
    required RideState ride,
    RideSlot? selectedRideSlot,
    List<RideSlot> rideSlots = const [],
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
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
          ),

          Gap(20.0),

          // Schedule Ride Button
          CustomButton(
            text: 'Continue',
            onPressed: () {
              if (selectedRideSlot == null) {
                showErrorSnackbar('Please select a ride');
                return;
              }

              ref
                  .read(rideNotifierProvider.notifier)
                  .bookRide(rideType: selectedRideSlot.rideType!);
            },
            isLoading: ride.isLoading,
            progressColor: AppColors.accent,
            backgroundColor: selectedRideSlot != null
                ? AppColors.accent
                : AppColors.accentLighter,
            textStyle: TextStyles.btnStyle.copyWith(color: AppColors.white),
          ),
          Gap(30.0),
        ],
      ),
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
