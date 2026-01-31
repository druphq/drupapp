import 'package:drup/di/ride_notifier.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/features/passenger/ui/bottomsheets/ride_details_bottom_sheet.dart';
import 'package:drup/features/passenger/ui/widgets/home_actions_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class BottomSheetWidget extends ConsumerStatefulWidget {
  final VoidCallback? onWhereToTap;
  final VoidCallback? onScheduleRide;
  const BottomSheetWidget({super.key, this.onWhereToTap, this.onScheduleRide});

  @override
  ConsumerState<BottomSheetWidget> createState() => _BottomSheetWidgetState();
}

class _BottomSheetWidgetState extends ConsumerState<BottomSheetWidget> {
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
              rideAmount: rideState.currentRide?.actualFare,
              onScheduleRide: widget.onScheduleRide,
              onCancelRide: () {
                ref.read(rideNotifierProvider.notifier).clearRoute();
              },
            ),
            false => HomeActionsContent(onWhereToTap: widget.onWhereToTap),
          },
          Gap(MediaQuery.of(context).size.height * 0.06),
        ],
      ),
    );
  }
}
