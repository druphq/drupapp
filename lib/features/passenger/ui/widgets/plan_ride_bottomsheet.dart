import 'package:drup/features/passenger/provider/ride_notifier.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/features/passenger/ui/bottomsheets/ride_confirmation_bottomsheet.dart';
import 'package:drup/features/passenger/ui/widgets/home_content_widget.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class PlanRideBottomsheet extends ConsumerStatefulWidget {
  final VoidCallback? onWhereToTap;
  final VoidCallback? onScheduleRide;
  final VoidCallback? onEditRide;
  const PlanRideBottomsheet({
    super.key,
    this.onWhereToTap,
    this.onScheduleRide,
    this.onEditRide,
  });

  @override
  ConsumerState<PlanRideBottomsheet> createState() => _BottomSheetWidgetState();
}

class _BottomSheetWidgetState extends ConsumerState<PlanRideBottomsheet> {
  @override
  Widget build(BuildContext context) {
    final rideState = ref.watch(rideNotifierProvider);

    final pickupLocation = rideState.pickupLocation;
    final destinationLocation = rideState.destinationLocation;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Corners.hMd)),
        color: AppColors.accent500,
      ),
      child: Column(
        children: [
          switch (rideState.hasActiveRoutes) {
            true => RideConfirmationBottomSheet(
              pickupLocation: pickupLocation!.name ?? '',
              destinationLocation: destinationLocation!.name ?? '',
              isLoading: rideState.isLoading,
              estimate: rideState.fareEstimates.isNotEmpty
                  ? rideState.fareEstimates[0]
                  : null,
              onScheduleRide: widget.onScheduleRide,
              onEditRide: () {
                widget.onEditRide?.call();
              },
            ),
            false => HomeContentWidget(onWhereToTap: widget.onWhereToTap),
          },
          Gap(MediaQuery.of(context).size.height * 0.06),
        ],
      ),
    );
  }
}
