import 'package:drup/di/notifiers.dart';
import 'package:drup/resources/app_assets.dart';
import 'package:drup/router/app_routes.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:drup/utils/extension.dart';
import 'package:drup/utils/util_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../model/ride_api_models.dart';
import '../../../../di/providers.dart';

enum _StatusFilter { upcoming, completed, cancelled }

class RideHistoryScreen extends ConsumerStatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  ConsumerState<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends ConsumerState<RideHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoadingUpcoming = true;
  bool _isLoadingHistory = true;
  List<BookedRide> _upcomingRides = [];
  List<BookedRide> _historyRides = [];

  _StatusFilter _ridesFilter = _StatusFilter.upcoming;
  _StatusFilter _deliveryFilter = _StatusFilter.upcoming;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAllData();
    });
  }

  Future<void> _fetchAllData() async {
    await Future.wait([_fetchUpcomingRides(), _fetchRideHistory()]);
  }

  Future<void> _fetchUpcomingRides() async {
    setState(() => _isLoadingUpcoming = true);

    final rideRepo = ref.read(rideRepositoryProvider);
    final response = await rideRepo.getActiveRideFromApi();

    setState(() {
      _upcomingRides = response.success && response.data?.ride != null
          ? [response.data!.ride!]
          : [];
      _isLoadingUpcoming = false;
    });
  }

  Future<void> _fetchRideHistory() async {
    setState(() => _isLoadingHistory = true);

    await ref.read(rideNotifierProvider.notifier).fetchRideHistory();
    final rideState = ref.read(rideNotifierProvider);

    setState(() {
      _historyRides = rideState.rideHistory;
      _isLoadingHistory = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers to partition data by category (ride vs delivery) and status chip
  // ---------------------------------------------------------------------------

  bool _isDelivery(BookedRide r) => r.rideType == 'delivery';

  List<BookedRide> _filterByStatus(
    List<BookedRide> all,
    _StatusFilter filter, {
    required bool delivery,
  }) {
    final byCategory = all
        .where((r) => delivery ? _isDelivery(r) : !_isDelivery(r))
        .toList();

    switch (filter) {
      case _StatusFilter.upcoming:
        // Active / upcoming rides from the separate endpoint
        final upcoming = _upcomingRides
            .where((r) => delivery ? _isDelivery(r) : !_isDelivery(r))
            .toList();
        return upcoming;
      case _StatusFilter.completed:
        return byCategory.where((r) => r.status == 'completed').toList();
      case _StatusFilter.cancelled:
        return byCategory.where((r) => r.status == 'cancelled').toList();
    }
  }

  Future<void> Function() _refreshForFilter(_StatusFilter filter) {
    switch (filter) {
      case _StatusFilter.upcoming:
        return _fetchUpcomingRides;
      case _StatusFilter.completed:
      case _StatusFilter.cancelled:
        return _fetchRideHistory;
    }
  }

  bool _isLoadingForFilter(_StatusFilter filter) {
    switch (filter) {
      case _StatusFilter.upcoming:
        return _isLoadingUpcoming;
      case _StatusFilter.completed:
      case _StatusFilter.cancelled:
        return _isLoadingHistory;
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'My Rides',
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
            Tab(text: 'Rides'),
            Tab(text: 'Delivery'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryTab(
            filter: _ridesFilter,
            onFilterChanged: (f) => setState(() => _ridesFilter = f),
            isDelivery: false,
          ),
          _buildCategoryTab(
            filter: _deliveryFilter,
            onFilterChanged: (f) => setState(() => _deliveryFilter = f),
            isDelivery: true,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Category tab (Rides or Delivery) with status chips
  // ---------------------------------------------------------------------------

  Widget _buildCategoryTab({
    required _StatusFilter filter,
    required ValueChanged<_StatusFilter> onFilterChanged,
    required bool isDelivery,
  }) {
    final rides = _filterByStatus(_historyRides, filter, delivery: isDelivery);
    final loading = _isLoadingForFilter(filter);
    final onRefresh = _refreshForFilter(filter);

    final label = isDelivery ? 'deliveries' : 'rides';

    final emptyConfig = {
      _StatusFilter.upcoming: (
        icon: Icons.schedule,
        title: 'No upcoming $label',
        subtitle: 'Scheduled $label will appear here',
      ),
      _StatusFilter.completed: (
        icon: Icons.history,
        title: 'No completed $label yet',
        subtitle: 'Your $label history will appear here',
      ),
      _StatusFilter.cancelled: (
        icon: Icons.cancel_outlined,
        title: 'No cancelled $label',
        subtitle: 'Cancelled $label will appear here',
      ),
    }[filter]!;

    return Column(
      children: [
        // Status filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: _StatusFilter.values.map((f) {
              final selected = f == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f.name.capitalizeFirstChar()),
                  selected: selected,
                  onSelected: (_) => onFilterChanged(f),
                  selectedColor: AppColors.accent,
                  labelStyle: TextStyles.t2.copyWith(
                    fontSize: 13,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                  backgroundColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide.none,
                  ),
                  showCheckmark: false,
                ),
              );
            }).toList(),
          ),
        ),

        // Content
        Expanded(
          child: _buildTab(
            isLoading: loading,
            rides: rides,
            emptyIcon: emptyConfig.icon,
            emptyTitle: emptyConfig.title,
            emptySubtitle: emptyConfig.subtitle,
            onRefresh: onRefresh,
          ),
        ),
      ],
    );
  }

  Widget _buildTab({
    required bool isLoading,
    required List<BookedRide> rides,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptySubtitle,
    required Future<void> Function() onRefresh,
  }) {
    final height = MediaQuery.of(context).size.height;

    if (isLoading) {
      return Padding(
        padding: EdgeInsets.only(top: height * 0.2),
        child: const Align(
          alignment: Alignment.topCenter,
          child: SizedBox.square(
            dimension: 30,
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return _buildRideList(
      rides: rides,
      emptyIcon: emptyIcon,
      emptyTitle: emptyTitle,
      emptySubtitle: emptySubtitle,
      onRefresh: onRefresh,
    );
  }

  Widget _buildRideList({
    required List<BookedRide> rides,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptySubtitle,
    required Future<void> Function() onRefresh,
  }) {
    final height = MediaQuery.of(context).size.height;
    if (rides.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: height * 0.2),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(emptyIcon, size: 80, color: AppColors.textLight),
              const Gap(16),
              Text(
                emptyTitle,
                style: TextStyles.t2.copyWith(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const Gap(8),
              Text(
                emptySubtitle,
                style: TextStyles.t2.copyWith(
                  fontSize: 14,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Group rides by month/year
    Map<String, List<BookedRide>> grouped = {};
    for (final ride in rides) {
      final key = DateFormat('MMMM yyyy').format(ride.createdAt);
      grouped.putIfAbsent(key, () => []).add(ride);
    }

    // Flatten to a list of headers and rides
    final List<dynamic> items = [];
    grouped.forEach((month, rides) {
      items.add(month);
      items.addAll(rides);
    });

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          if (item is String) {
            // Section header
            return Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                item,
                style: TextStyles.t1.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            );
          } else if (item is BookedRide) {
            // Add divider below each ride except the last in the group
            final isLastInGroup =
                (index + 1 >= items.length) || (items[index + 1] is String);
            return Column(
              children: [
                _buildRideCard(item),
                if (!isLastInGroup) _buildDivider(),
              ],
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  Widget _buildRideCard(BookedRide ride) {
    final dateFormat = DateFormat('dd MMM  •  hh:mm a');
    final formattedDate = dateFormat.format(ride.createdAt);
    final scheduleDate = formatDate(ride.scheduledTime!);
    final pickupTime = formatTime(ride.pickupWindow!.start);
    final formattedFare = '₦${formatThousand(ride.fare.totalFare)}';

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.transparent,
      elevation: 0.0,
      child: InkWell(
        onTap: () {
          // Navigate to ride details
          context.push(AppRoutes.rideDetailsRoute, extra: ride);
          // _showBookDetailBottomsheet(ride);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ride.rideType.toUpperCase(),
                        style: TextStyles.t2.copyWith(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Gap(10.0),
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
                  Row(
                    children: [
                      ImageIcon(
                        AssetImage(AppAssets.scheduleIcon),
                        size: 18,
                        color: AppColors.accent,
                      ),
                      const Gap(4),
                      Text(
                        '$scheduleDate • $pickupTime',
                        style: TextStyles.t2.copyWith(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    formattedDate,
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
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: AppColors.divider);
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
