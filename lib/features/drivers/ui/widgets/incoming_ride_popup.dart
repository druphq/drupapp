import 'package:drup/resources/app_dimen.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:drup/utils/extension.dart';
import 'package:drup/utils/util_functions.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// Shows up to 2 incoming ride request cards that slide in from the top.
///
/// Each card auto-dismisses after [autoDismissSeconds] and can be swiped away.
/// Tapping a card triggers [onTap] (which should open the detail sheet).
class IncomingRidePopups extends StatefulWidget {
  const IncomingRidePopups({
    super.key,
    required this.rides,
    required this.onTap,
    required this.onDismiss,
    this.autoDismissSeconds = 30,
  });

  final List<Map<String, dynamic>> rides;
  final void Function(Map<String, dynamic> ride) onTap;
  final void Function(Map<String, dynamic> ride) onDismiss;
  final int autoDismissSeconds;

  @override
  State<IncomingRidePopups> createState() => _IncomingRidePopupsState();
}

class _IncomingRidePopupsState extends State<IncomingRidePopups>
    with TickerProviderStateMixin {
  /// Rides currently being shown as pop-ups (max 2).
  final List<_PopupEntry> _entries = [];

  /// IDs of rides that have been dismissed (won't re-appear).
  final Set<String> _dismissedIds = {};

  @override
  void didUpdateWidget(covariant IncomingRidePopups oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncEntries();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncEntries());
  }

  /// Ensure up to 2 pop-ups are shown for the latest rides.
  void _syncEntries() {
    final currentIds = _entries.map((e) => e.id).toSet();

    // Remove entries whose rides are no longer in the list
    for (final entry in List.of(_entries)) {
      final stillExists = widget.rides.any((r) => _rideId(r) == entry.id);
      if (!stillExists) {
        _removeEntry(entry, dismissed: false);
      }
    }

    // Add new rides (newest first) up to 2 visible
    for (final ride in widget.rides) {
      if (_entries.length >= 2) break;
      final id = _rideId(ride);
      if (currentIds.contains(id) || _dismissedIds.contains(id)) continue;

      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
      final countdownController = AnimationController(
        vsync: this,
        duration: Duration(seconds: widget.autoDismissSeconds),
      );

      final entry = _PopupEntry(
        id: id,
        ride: ride,
        slideController: controller,
        countdownController: countdownController,
      );

      _entries.insert(0, entry);
      controller.forward();
      countdownController.forward();

      // Auto-dismiss after countdown
      countdownController.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _removeEntry(entry);
        }
      });
    }

    if (mounted) setState(() {});
  }

  void _removeEntry(_PopupEntry entry, {bool dismissed = true}) {
    if (dismissed) _dismissedIds.add(entry.id);

    entry.slideController.reverse().then((_) {
      entry.dispose();
      if (mounted) {
        setState(() => _entries.remove(entry));
      }
    });
  }

  void _handleDismiss(_PopupEntry entry) {
    widget.onDismiss(entry.ride);
    _removeEntry(entry);
  }

  String _rideId(Map<String, dynamic> ride) =>
      (ride['_id'] ?? ride['id'] ?? '').toString();

  @override
  void dispose() {
    for (final e in _entries) {
      e.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_entries.isEmpty) return const SizedBox.shrink();

    return Positioned(
      left: 16,
      right: 16,
      top: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 60), // below top bar
          child: Column(
            children: [
              for (int i = 0; i < _entries.length; i++) ...[
                if (i > 0) const Gap(8),
                _buildPopupCard(_entries[i]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopupCard(_PopupEntry entry) {
    final ride = entry.ride;
    final rideType = (ride['rideType'] ?? ride['ride_type'] ?? '').toString();
    final isDelivery = rideType.toLowerCase() == 'delivery';

    final fare = ride['fare'] is Map
        ? ride['fare'] as Map<String, dynamic>
        : null;
    final totalFare =
        fare?['totalFare'] ?? fare?['total_fare'] ?? ride['totalFare'] ?? 0;

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

    final distance =
        ride['estimatedDistance'] ??
        ride['estimated_distance'] ??
        ride['distance'] ??
        0;

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, -1.5), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: entry.slideController,
              curve: Curves.easeOutCubic,
            ),
          ),
      child: Dismissible(
        key: ValueKey(entry.id),
        direction: DismissDirection.horizontal,
        onDismissed: (_) => _handleDismiss(entry),
        child: GestureDetector(
          onTap: () => widget.onTap(ride),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(Corners.c20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Countdown bar ──
                AnimatedBuilder(
                  animation: entry.countdownController,
                  builder: (_, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: 1 - entry.countdownController.value,
                      minHeight: 3,
                      backgroundColor: AppColors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.accent,
                      ),
                    ),
                  ),
                ),
                const Gap(10),

                // ── Top row: type + fare ──
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDelivery
                            ? AppColors.orange50
                            : AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isDelivery
                                ? Icons.local_shipping_outlined
                                : Icons.drive_eta,
                            size: 13,
                            color: isDelivery
                                ? AppColors.orange400
                                : AppColors.accent,
                          ),
                          const Gap(4),
                          Text(
                            rideType.capitalizeFirstChar(),
                            style: TextStyles.t2.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDelivery
                                  ? AppColors.orange400
                                  : AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (distance is num && distance > 0) ...[
                      const Gap(8),
                      Icon(
                        Icons.call_split,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      const Gap(2),
                      Text(
                        formatDistance(distance.toDouble()),
                        style: TextStyles.t2.copyWith(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      '₦${formatThousand((totalFare is num ? totalFare.toDouble() : 0))}',
                      style: TextStyles.t1.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                const Gap(10),

                // ── Route preview ──
                Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          height: 10,
                          width: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.pickupMarker,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          height: 14,
                          width: 1.5,
                          color: AppColors.divider,
                        ),
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppColors.red400,
                        ),
                      ],
                    ),
                    const Gap(8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pickupName,
                            style: TextStyles.t2.copyWith(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Gap(6),
                          Text(
                            dropoffName,
                            style: TextStyles.t2.copyWith(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Gap(8),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: AppColors.accent,
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

/// Internal entry tracking each pop-up card's animation state.
class _PopupEntry {
  final String id;
  final Map<String, dynamic> ride;
  final AnimationController slideController;
  final AnimationController countdownController;

  _PopupEntry({
    required this.id,
    required this.ride,
    required this.slideController,
    required this.countdownController,
  });

  void dispose() {
    slideController.dispose();
    countdownController.dispose();
  }
}
