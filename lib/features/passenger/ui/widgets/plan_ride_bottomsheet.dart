import 'package:drup/features/passenger/provider/ride_notifier.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/features/passenger/ui/bottomsheets/ride_details_bottom_sheet.dart';
import 'package:drup/features/passenger/ui/widgets/home_content_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class PlanRideBottomsheet extends ConsumerStatefulWidget {
  final VoidCallback? onWhereToTap;
  final VoidCallback? onScheduleRide;
  final VoidCallback? onCancelRide;
  const PlanRideBottomsheet({
    super.key,
    this.onWhereToTap,
    this.onScheduleRide,
    this.onCancelRide,
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

    final showRideDetails =
        pickupLocation != null && destinationLocation != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Corners.hMd)),
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color(0xff253B80),
            Color(0xff253B80),
            Color(0xff5490D0),
            Color(0xff5C9EDC),
          ],
        ),
      ),
      child: Column(
        children: [
          switch (showRideDetails) {
            true => RideDetailsBottomSheet(
              pickupLocation: pickupLocation!.name ?? '',
              destinationLocation: destinationLocation!.name ?? '',
              isLoading: rideState.isLoading,
              estimate: rideState.fareEstimates.isNotEmpty
                  ? rideState.fareEstimates[0]
                  : null,
              // onScheduleRide: widget.onScheduleRide,
              onScheduleRide: () {
                ref.read(rideNotifierProvider.notifier).calculateFare();
              },

              onCancelRide: () {
                widget.onCancelRide?.call();
                ref.read(rideNotifierProvider.notifier).clearRoute();
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
