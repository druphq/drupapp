import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../model/ride_api_models.dart';
import '../../provider/ride_notifier.dart';

class RideHistoryScreen extends ConsumerStatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  ConsumerState<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends ConsumerState<RideHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Fetch ride history on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rideNotifierProvider.notifier).fetchRideHistory();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rideState = ref.watch(rideNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Ride History',
          style: TextStyles.t1.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accent,
          tabs: const [
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: rideState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRideList(
                  rides: rideState.rideHistory
                      .where((r) => r.status == 'completed')
                      .toList(),
                  isCompleted: true,
                ),
                _buildRideList(
                  rides: rideState.rideHistory
                      .where((r) => r.status == 'cancelled')
                      .toList(),
                  isCompleted: false,
                ),
              ],
            ),
    );
  }

  Widget _buildRideList({
    required List<BookedRide> rides,
    required bool isCompleted,
  }) {
    if (rides.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCompleted ? Icons.history : Icons.cancel_outlined,
              size: 80,
              color: AppColors.textLight,
            ),
            const Gap(16),
            Text(
              isCompleted ? 'No completed rides yet' : 'No cancelled rides',
              style: TextStyles.t2.copyWith(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const Gap(8),
            Text(
              isCompleted
                  ? 'Your ride history will appear here'
                  : 'Cancelled rides will appear here',
              style: TextStyles.t2.copyWith(
                fontSize: 14,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(rideNotifierProvider.notifier).fetchRideHistory();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rides.length,
        itemBuilder: (context, index) {
          final ride = rides[index];
          return _buildRideCard(ride);
        },
      ),
    );
  }

  Widget _buildRideCard(BookedRide ride) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final formattedDate = dateFormat.format(ride.createdAt);
    final formattedFare = '₦${ride.fare.totalFare.toStringAsFixed(0)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedDate,
                  style: TextStyles.t2.copyWith(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  formattedFare,
                  style: TextStyles.t1.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Gap(12),
            _buildLocationRow(
              Icons.circle,
              ride.pickup.name.isNotEmpty
                  ? ride.pickup.name
                  : ride.pickup.address,
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
              ride.dropoff.name.isNotEmpty
                  ? ride.dropoff.name
                  : ride.dropoff.address,
              AppColors.destinationMarker,
            ),
            const Gap(12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ride.vehicleType.toUpperCase(),
                  style: TextStyles.t2.copyWith(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${ride.distanceKm.toStringAsFixed(1)} km • ${ride.durationMinutes} min',
                  style: TextStyles.t2.copyWith(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
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
            style: TextStyles.t2.copyWith(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
