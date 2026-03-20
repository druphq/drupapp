import 'package:drup/features/drivers/provider/driver_notifier.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/router/app_routes.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:drup/utils/convert_util.dart';
import 'package:drup/utils/extension.dart';
import 'package:drup/utils/util_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

enum _StatusFilter { upcoming, completed, cancelled }

class DriverRideHistoryScreen extends ConsumerStatefulWidget {
  const DriverRideHistoryScreen({super.key});

  @override
  ConsumerState<DriverRideHistoryScreen> createState() =>
      _DriverRideHistoryScreenState();
}

class _DriverRideHistoryScreenState
    extends ConsumerState<DriverRideHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  List<Map<String, dynamic>> _rides = [];

  _StatusFilter _ridesFilter = _StatusFilter.upcoming;
  _StatusFilter _deliveryFilter = _StatusFilter.upcoming;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    final notifier = ref.read(driverNotifierProvider.notifier);
    await notifier.fetchRideHistory();

    if (!mounted) return;

    final driverState = ref.read(driverNotifierProvider);
    setState(() {
      _rides = driverState.rideHistory;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool _isDelivery(Map<String, dynamic> r) =>
      (r['rideType'] ?? r['ride_type'] ?? '').toString().toLowerCase() ==
      'delivery';

  String _getStatus(Map<String, dynamic> r) =>
      (r['status'] ?? '').toString().toLowerCase();

  List<Map<String, dynamic>> _filterByStatus(
    _StatusFilter filter, {
    required bool delivery,
  }) {
    final byCategory = _rides
        .where((r) => delivery ? _isDelivery(r) : !_isDelivery(r))
        .toList();

    switch (filter) {
      case _StatusFilter.upcoming:
        return byCategory.where((r) {
          final s = _getStatus(r);
          return s != 'completed' && s != 'cancelled';
        }).toList();
      case _StatusFilter.completed:
        return byCategory.where((r) => _getStatus(r) == 'completed').toList();
      case _StatusFilter.cancelled:
        return byCategory.where((r) => _getStatus(r) == 'cancelled').toList();
    }
  }

  DateTime _parseDate(Map<String, dynamic> r) {
    final raw = r['createdAt'] ?? r['created_at'] ?? r['updatedAt'] ?? '';
    return DateTime.tryParse(raw.toString()) ?? DateTime.now();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
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
  // Category tab
  // ---------------------------------------------------------------------------

  Widget _buildCategoryTab({
    required _StatusFilter filter,
    required ValueChanged<_StatusFilter> onFilterChanged,
    required bool isDelivery,
  }) {
    final rides = _filterByStatus(filter, delivery: isDelivery);
    final label = isDelivery ? 'deliveries' : 'rides';

    final emptyConfig = {
      _StatusFilter.upcoming: (
        icon: Icons.schedule,
        title: 'No upcoming $label',
        subtitle: 'Upcoming $label will appear here',
      ),
      _StatusFilter.completed: (
        icon: Icons.history,
        title: 'No completed $label yet',
        subtitle: 'Your completed $label will appear here',
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
          child: _isLoading
              ? Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.2,
                  ),
                  child: const Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox.square(
                      dimension: 30,
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              : _buildRideList(
                  rides: rides,
                  emptyIcon: emptyConfig.icon,
                  emptyTitle: emptyConfig.title,
                  emptySubtitle: emptyConfig.subtitle,
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Ride list with monthly grouping
  // ---------------------------------------------------------------------------

  Widget _buildRideList({
    required List<Map<String, dynamic>> rides,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    if (rides.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.2),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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

    // Group by month
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final ride in rides) {
      final key = DateFormat('MMMM yyyy').format(_parseDate(ride));
      grouped.putIfAbsent(key, () => []).add(ride);
    }

    final List<dynamic> items = [];
    grouped.forEach((month, list) {
      items.add(month);
      items.addAll(list);
    });

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          if (item is String) {
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
          }
          return _buildRideCard(item as Map<String, dynamic>);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Ride card
  // ---------------------------------------------------------------------------

  Widget _buildRideCard(Map<String, dynamic> ride) {
    final status = _getStatus(ride);
    final isDelivery = _isDelivery(ride);
    final date = _parseDate(ride);
    final formattedDate = DateFormat('dd MMM yyyy  •  hh:mm a').format(date);

    // Fare extraction
    final fare = ride['fare'] is Map
        ? ride['fare'] as Map<String, dynamic>
        : null;
    final totalFare =
        fare?['totalFare'] ?? fare?['total_fare'] ?? ride['totalFare'] ?? 0;
    final formattedFare = '₦${formatThousand(totalFare)}';

    // Pickup/dropoff
    final pickup = ride['pickup'] is Map
        ? ride['pickup'] as Map<String, dynamic>
        : <String, dynamic>{};
    final dropoff = ride['dropoff'] is Map
        ? ride['dropoff'] as Map<String, dynamic>
        : <String, dynamic>{};
    final pickupName = (pickup['name'] ?? pickup['address'] ?? 'Pickup')
        .toString();
    final dropoffName = (dropoff['name'] ?? dropoff['address'] ?? 'Dropoff')
        .toString();

    // Vehicle type
    final vehicleType = (ride['vehicleType'] ?? ride['vehicle_type'] ?? '')
        .toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Corners.c20),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(Corners.c20),
        child: InkWell(
          borderRadius: BorderRadius.circular(Corners.c20),
          onTap: () {
            context.push(AppRoutes.driverRideDetailRoute, extra: ride);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top row: status chip + vehicle type + fare ──
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg(status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.replaceAll('_', ' ').capitalizeFirstChar(),
                        style: TextStyles.t2.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor(status),
                        ),
                      ),
                    ),
                    const Gap(8),
                    Icon(
                      isDelivery
                          ? Icons.local_shipping_outlined
                          : Icons.drive_eta,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const Gap(4),
                    if (vehicleType.isNotEmpty)
                      Text(
                        vehicleType.capitalizeFirstChar(),
                        style: TextStyles.t2.copyWith(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    const Spacer(),
                    Text(
                      formattedFare,
                      style: TextStyles.t1.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                const Gap(14),

                // ── Route: pickup → dropoff ──
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        children: [
                          Container(
                            height: 14,
                            width: 14,
                            decoration: const BoxDecoration(
                              color: AppColors.pickupMarker,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.circle,
                              color: Colors.white,
                              size: 6,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              width: 2,
                              color: AppColors.divider,
                            ),
                          ),
                          const Icon(
                            Icons.location_on,
                            size: 18,
                            color: AppColors.red400,
                          ),
                        ],
                      ),
                      const Gap(10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pickupName,
                              style: TextStyles.t2.copyWith(fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Gap(14),
                            Text(
                              dropoffName,
                              style: TextStyles.t2.copyWith(fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Gap(12),

                // ── Bottom row: date ──
                Row(
                  children: [
                    const Spacer(),
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
      ),
    );
  }
}
