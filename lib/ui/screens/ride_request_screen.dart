import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_notifier.dart';
import '../../providers/ride_notifier.dart';
import '../../theme/app_colors.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/location_helper.dart';
import '../../core/widgets/custom_button.dart';

class RideRequestScreen extends ConsumerWidget {
  const RideRequestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final rideState = ref.watch(rideNotifierProvider);

    final pickupLocation = rideState.pickupLocation;
    final destinationLocation = rideState.destinationLocation;
    final distance = rideState.estimatedDistance;
    final duration = rideState.estimatedDuration;
    final fare = rideState.estimatedFare;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Ride')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ride details card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trip Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLocationRow(
                      Icons.location_on,
                      'Pickup',
                      pickupLocation?.address ?? 'Selected on map',
                      AppColors.pickupMarker,
                    ),
                    const SizedBox(height: 12),
                    _buildLocationRow(
                      Icons.flag,
                      'Destination',
                      destinationLocation?.address ?? 'Selected on map',
                      AppColors.destinationMarker,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Fare breakdown card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fare Estimate',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (distance != null)
                      _buildInfoRow(
                        'Distance',
                        LocationHelper.formatDistance(distance),
                      ),
                    if (duration != null)
                      _buildInfoRow(
                        'Duration',
                        LocationHelper.formatDuration(duration),
                      ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      'Base Fare',
                      '\$${AppConstants.baseFare.toStringAsFixed(2)}',
                    ),
                    _buildInfoRow(
                      'Booking Fee',
                      '\$${AppConstants.bookingFee.toStringAsFixed(2)}',
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Fare',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${fare?.toStringAsFixed(2) ?? '0.00'}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Payment method card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.payment, color: AppColors.primary),
                    const SizedBox(width: 12),
                    const Text(
                      'Cash',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        // Change payment method
                      },
                      child: const Text('Change'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Request ride button
            CustomButton(
              text: 'Request Ride',
              onPressed: () async {
                if (currentUser == null) return;

                final success = await ref
                    .read(rideNotifierProvider.notifier)
                    .requestRide(
                      userId: currentUser.id,
                      userName: currentUser.name,
                      paymentMethod: 'cash',
                    );

                if (success && context.mounted) {
                  context.go(AppConstants.userTrackingRoute);
                }
              },
              icon: Icons.check_circle,
              isLoading: rideState.isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(
    IconData icon,
    String label,
    String address,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
