import 'package:drup/core/widgets/custom_button.dart';
import 'package:drup/features/passenger/model/ride_api_models.dart';
import 'package:drup/features/passenger/ui/widgets/driver_info_card.dart';
import 'package:drup/features/passenger/ui/widgets/ride_map_widget.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:drup/utils/util_functions.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                style: TextStyles.t2.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _fetchRide, child: const Text('Retry')),
            ],
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
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          Text(
            'Ride Booked',
            textAlign: TextAlign.center,
            style: TextStyles.t1.copyWith(
              fontSize: FontSizes.s24,
              fontWeight: FontWeight.w700,
              color: AppColors.onAccent,
            ),
          ),
          Gap(8),
          Text(
            'Driver will be arriving in ${formatRelativeDateTime(ride.scheduledTime ?? DateTime.now())}',
            textAlign: TextAlign.center,
            style: TextStyles.t2.copyWith(
              fontSize: FontSizes.s14,
              color: AppColors.textSecondary,
            ),
          ),
          Gap(32),

          // Trip Details
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(Corners.md),
              border: Border.all(color: AppColors.greyStrong),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trip Details',
                  style: TextStyles.t1.copyWith(
                    fontSize: FontSizes.s16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onAccent,
                  ),
                ),
                Gap(4.0),
                RichText(
                  text: TextSpan(
                    text: 'Scheduled for ',
                    style: TextStyles.t2.copyWith(
                      fontSize: FontSizes.s14,
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      TextSpan(
                        text: formatDate(ride.scheduledTime ?? DateTime.now()),
                        style: TextStyles.t2.copyWith(
                          fontSize: FontSizes.s14,
                          color: AppColors.onAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Gap(12),
                RideMapWidget(ride: ride),
                Gap(16),
                Divider(color: AppColors.greyStrong),
                Gap(12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Fare',
                      style: TextStyles.t2.copyWith(
                        fontSize: FontSizes.s16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onAccent,
                      ),
                    ),
                    Text(
                      '₦${formatThousand(ride.fare.totalFare)}',
                      style: TextStyles.t1.copyWith(
                        fontSize: FontSizes.s20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (ride.driver != null) ...[
            DriverInfoCard(driver: ride.driver!),
          ] else ...[
            Gap(16),
            Text(
              'Driver details will be available once a driver is assigned to your ride.',
              textAlign: TextAlign.center,
              style: TextStyles.t2.copyWith(
                fontSize: FontSizes.s14,
                color: AppColors.textSecondary,
              ),
            ),
          ],

          Gap(24),

          // Make Payment Button
          CustomButton(text: 'Make Payment', onPressed: () {}),
        ],
      ),
    );
  }
}
