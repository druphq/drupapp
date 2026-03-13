import 'package:drup/core/widgets/custom_button.dart';
import 'package:drup/di/notifiers.dart';
import 'package:drup/features/passenger/model/ride_api_models.dart';
import 'package:drup/features/passenger/provider/ride_notifier.dart';
import 'package:drup/features/passenger/ui/widgets/driver_info_card.dart';
import 'package:drup/features/passenger/ui/widgets/ride_map_widget.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/router/app_routes.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:drup/utils/extension.dart';
import 'package:drup/utils/util_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../di/providers.dart';

class RideDetailsScreen extends ConsumerStatefulWidget {
  const RideDetailsScreen({super.key, required this.ride});
  final BookedRide ride;

  @override
  ConsumerState<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends ConsumerState<RideDetailsScreen> {
  BookedRide? _ride;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRide();
  }

  Future<void> _fetchRide() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final repo = ref.read(rideRepositoryProvider);
    final response = await repo.getRideById(widget.ride.id);
    if (response.success && response.data != null) {
      setState(() {
        _ride = response.data;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = response.message ?? 'Failed to load ride details';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Ride Details',
            style: TextStyles.t1.copyWith(
              fontSize: FontSizes.s18,
              fontWeight: FontWeight.w700,
              color: AppColors.onAccent,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.close, color: AppColors.onAccent),
            onPressed: () => Navigator.of(context).pop(),
          ),
          scrolledUnderElevation: 0.0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Ride Details',
            style: TextStyles.t1.copyWith(
              fontSize: FontSizes.s18,
              fontWeight: FontWeight.w700,
              color: AppColors.onAccent,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.close, color: AppColors.onAccent),
            onPressed: () => Navigator.of(context).pop(),
          ),
          scrolledUnderElevation: 0.0,
        ),

        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: AppColors.textLight),
                const Gap(16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyles.t2.copyWith(color: AppColors.textSecondary),
                ),
                TextButton(
                  onPressed: _fetchRide,
                  child: Text(
                    'Retry',
                    style: TextStyles.btnStyle.copyWith(fontSize: 16.0),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final ride = _ride!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Ride Details',
          style: TextStyles.t1.copyWith(fontSize: FontSizes.s18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.onAccent),
          onPressed: () => Navigator.of(context).pop(),
        ),
        scrolledUnderElevation: 0.0,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(
          left: 20.0,
          right: 20.0,
          bottom: 30.0,
          top: 10,
        ),
        child: _buildStatusWidget(ride.paymentStatus),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Column(
              children: [
                if (ride.driver != null) DriverInfoCard(bookedRide: ride),

                Gap(10),

                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(Corners.md),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Driver\'s detail will appear once a driver is assigned to your ride.',
                    style: TextStyles.t2.copyWith(
                      fontSize: FontSizes.s14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Gap(10.0),

          SizedBox(
            height: 150,
            child: Stack(
              children: [
                GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      ride.pickup.coordinates.latitude,
                      ride.pickup.coordinates.longitude,
                    ),
                    zoom: 14,
                  ),
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),

                Positioned(
                  left: 16.0,
                  top: 8.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(Corners.lg),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.call_split,
                          size: 20,
                          color: AppColors.onAccent,
                        ),
                        Gap(4),
                        Text(
                          '${formatDistance(ride.estimatedDistance.toDouble())}, ${formatDuration(ride.estimatedDuration)}',
                          style: TextStyles.h1.copyWith(
                            fontSize: FontSizes.s14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Gap(16.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    RichText(
                      text: TextSpan(
                        text: 'Ride Type:',
                        style: TextStyles.h2.copyWith(
                          fontSize: FontSizes.s14,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(
                            text: ' ${ride.rideType.capitalizeFirstChar()}',
                            style: TextStyles.t2.copyWith(
                              fontSize: FontSizes.s18,
                              color: AppColors.onAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    Icon(
                      Icons.drive_eta,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    Gap(4.0),
                    Text(
                      ride.vehicleType.capitalizeFirstChar(),
                      style: TextStyles.t2.copyWith(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),

                Gap(16.0),
                RideMapWidget(ride: ride),

                Gap(16.0),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: ride.rideNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                  child: Row(
                    children: [
                      Text(
                        'Ref: ${ride.rideNumber}',
                        style: TextStyles.t2.copyWith(
                          fontSize: FontSizes.s14,
                          color: AppColors.onAccent,
                        ),
                      ),
                      Gap(4.0),
                      Icon(
                        Icons.copy,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
                Gap(20),

                CustomButton(
                  text: 'Get help with ride',
                  onPressed: () {},
                  backgroundColor: AppColors.grey50,
                  textStyle: TextStyles.t2.copyWith(
                    fontSize: FontSizes.s16,
                    color: AppColors.onAccent,
                  ),
                ),
                Gap(16),
                if (ride.paymentStatus.toLowerCase() == 'pending')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      Text(
                        'Payment',
                        style: TextStyles.t1.copyWith(
                          fontSize: FontSizes.s16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onAccent,
                        ),
                      ),

                      Gap(12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Booking Fees',
                            style: TextStyles.body1.copyWith(
                              fontSize: FontSizes.s16,
                              color: AppColors.onAccent,
                            ),
                          ),
                          Text(
                            '₦${formatThousand(ride.fare.serviceFee)}',
                            style: TextStyles.t1.copyWith(
                              fontSize: FontSizes.s18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ride Fees',
                            style: TextStyles.body1.copyWith(
                              fontSize: FontSizes.s16,
                              color: AppColors.onAccent,
                            ),
                          ),
                          Text(
                            '₦${formatThousand(ride.fare.totalBeforeDiscount)}',
                            style: TextStyles.t1.copyWith(
                              fontSize: FontSizes.s18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Fare',
                            style: TextStyles.body1.copyWith(
                              fontSize: FontSizes.s16,
                              color: AppColors.onAccent,
                            ),
                          ),
                          Text(
                            '₦${formatThousand(ride.fare.totalFare)}',
                            style: TextStyles.t1.copyWith(
                              fontSize: FontSizes.s18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      Gap(10.0),

                      if (_ride?.paymentStatus.toLowerCase() == 'pending')
                        Text(
                          'Kindly make payment before ${formatDateTime(ride.paymentDeadline ?? DateTime.now())} to avoid cancellation.',
                          style: TextStyles.t2.copyWith(
                            fontSize: FontSizes.s14,
                            color: AppColors.orange400,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          Gap(24),
        ],
      ),
    );
  }

  Widget _buildStatusWidget(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'pending':
        bgColor = AppColors.orange50;
        textColor = AppColors.orange400;
        break;
      case 'completed':
        bgColor = AppColors.green50;
        textColor = AppColors.green400;
        break;
      case 'cancelled':
        bgColor = AppColors.red50;
        textColor = AppColors.red400;
        break;
      default:
        bgColor = AppColors.grey50;
        textColor = AppColors.textSecondary;
    }

    return status.toLowerCase() == 'pending'
        ? CustomButton(
            text: 'Make Payment',
            onPressed: () async {
              final result = await ref
                  .read(rideNotifierProvider.notifier)
                  .initializePayment(rideId: _ride!.id, paymentMethod: 'card');

              if (result?.authorizationUrl != null && mounted) {
                context.push(
                  AppRoutes.paymentWebViewRoute,
                  extra: {
                    'authorizationUrl': result!.authorizationUrl!,
                    'onPaymentComplete': () async {
                      // refresh ride details after payment completion
                      await _fetchRide();
                    },
                  },
                );
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to initialize payment. Please try again.',
                      ),
                    ),
                  );
                }
              }
            },
          )
        : Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(Corners.sm),
            ),
            child: Text(
              status,
              style: TextStyles.t2.copyWith(
                fontSize: FontSizes.s12,
                color: textColor,
              ),
            ),
          );
  }
}
