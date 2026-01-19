import 'package:drup/core/animation/searching_ripple.dart';
import 'package:drup/core/widgets/custom_button.dart';
import 'package:drup/providers/ride_notifier.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

enum RideSearchState { searching, availableRides, driverMatched }

class RideSearchBottomSheet extends ConsumerStatefulWidget {
  const RideSearchBottomSheet({super.key, this.onClose});
  final VoidCallback? onClose;

  @override
  ConsumerState<RideSearchBottomSheet> createState() =>
      _RideSearchBottomSheetState();
}

class _RideSearchBottomSheetState extends ConsumerState<RideSearchBottomSheet> {
  RideSearchState _currentState = RideSearchState.searching;
  String? _selectedRideType;

  // Ride details
  String pickupLocation = '';
  String destinationLocation = '';
  double rideAmount = 0.0;

  void _initialize() {
    final rideState = ref.read(rideNotifierProvider);
    pickupLocation = rideState.pickupLocation?.address ?? '';
    destinationLocation = rideState.destinationLocation?.address ?? '';
    rideAmount = rideState.estimatedFare ?? 0.0;
  }

  @override
  void initState() {
    super.initState();
    _initialize();
    // Simulate searching for drivers
    // _startSearching();
  }

  Future<void> _startSearching() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() {
        _currentState = RideSearchState.availableRides;
      });
    }
  }

  Future<void> _connectWithDriver(String rideType) async {
    setState(() {
      _selectedRideType = rideType;
      _currentState = RideSearchState.searching;
    });

    // Simulate connecting with driver
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _currentState = RideSearchState.driverMatched;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.4,
      maxChildSize: 1.0,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(Corners.lg),
              topRight: Radius.circular(Corners.lg),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar with close button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(width: 40),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.greyStrong,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.onAccent),
                      onPressed: widget.onClose,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ),

              Expanded(child: _buildContent(scrollController)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(ScrollController scrollController) {
    switch (_currentState) {
      case RideSearchState.searching:
        return _buildSearchingState();
      case RideSearchState.availableRides:
        return _buildAvailableRidesState(scrollController);
      case RideSearchState.driverMatched:
        return _buildDriverMatchedState(scrollController);
    }
  }

  Widget _buildSearchingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedRideType == null
                          ? 'Searching for available drivers...'
                          : 'Connecting with driver...',
                      style: TextStyles.t1.copyWith(
                        fontSize: FontSizes.s18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onAccent,
                      ),
                    ),
                    // Gap(4),
                    Text(
                      'Hold on lets search for available rides around you',
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      style: TextStyles.t2.copyWith(
                        fontSize: FontSizes.s14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.red400.withOpacity(0.1),
                  border: Border.all(color: AppColors.red400),
                ),
                padding: EdgeInsets.all(4),
                child: Icon(Icons.drive_eta, color: AppColors.red400, size: 24),
              ),
            ],
          ),

          Center(
            child: SearchingRipple(
              size: 180,
              primaryColor: AppColors.accent, // teal-ish outer rings
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableRidesState(ScrollController scrollController) {
    final rides = [
      {
        'type': 'Economy',
        'icon': Icons.directions_car,
        'seats': '4 seats',
        'time': '2 mins away',
        'price': rideAmount,
      },
      {
        'type': 'Premium',
        'icon': Icons.local_taxi,
        'seats': '4 seats',
        'time': '5 mins away',
        'price': rideAmount * 1.5,
      },
      {
        'type': 'SUV',
        'icon': Icons.airport_shuttle,
        'seats': '6 seats',
        'time': '8 mins away',
        'price': rideAmount * 2,
      },
    ];

    return ListView(
      controller: scrollController,
      padding: EdgeInsets.all(20),
      children: [
        Text(
          'Available Rides',
          style: TextStyles.t1.copyWith(
            fontSize: FontSizes.s20,
            fontWeight: FontWeight.w700,
            color: AppColors.onAccent,
          ),
        ),
        Gap(8),
        Text(
          'Choose your preferred ride type',
          style: TextStyles.t2.copyWith(
            fontSize: FontSizes.s14,
            color: AppColors.textSecondary,
          ),
        ),
        Gap(20),

        ...rides.map(
          (ride) => _buildRideCard(
            type: ride['type'] as String,
            icon: ride['icon'] as IconData,
            seats: ride['seats'] as String,
            time: ride['time'] as String,
            price: ride['price'] as double,
          ),
        ),
      ],
    );
  }

  Widget _buildRideCard({
    required String type,
    required IconData icon,
    required String seats,
    required String time,
    required double price,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _connectWithDriver(type),
          borderRadius: BorderRadius.circular(Corners.md),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.greyStrong),
              borderRadius: BorderRadius.circular(Corners.md),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(Corners.md),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 32),
                ),
                Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type,
                        style: TextStyles.t1.copyWith(
                          fontSize: FontSizes.s16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onAccent,
                        ),
                      ),
                      Gap(4),
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            color: AppColors.textSecondary,
                            size: 14,
                          ),
                          Gap(4),
                          Text(
                            seats,
                            style: TextStyles.t2.copyWith(
                              fontSize: FontSizes.s13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Gap(12),
                          Icon(
                            Icons.access_time,
                            color: AppColors.textSecondary,
                            size: 14,
                          ),
                          Gap(4),
                          Text(
                            time,
                            style: TextStyles.t2.copyWith(
                              fontSize: FontSizes.s13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  '₦${price.toStringAsFixed(2)}',
                  style: TextStyles.t1.copyWith(
                    fontSize: FontSizes.s18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDriverMatchedState(ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.all(20),
      children: [
        // Success icon
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.green400.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              color: AppColors.green400,
              size: 48,
            ),
          ),
        ),
        Gap(16),
        Text(
          'Driver Found!',
          textAlign: TextAlign.center,
          style: TextStyles.t1.copyWith(
            fontSize: FontSizes.s24,
            fontWeight: FontWeight.w700,
            color: AppColors.onAccent,
          ),
        ),
        Gap(8),
        Text(
          'Your driver is on the way',
          textAlign: TextAlign.center,
          style: TextStyles.t2.copyWith(
            fontSize: FontSizes.s14,
            color: AppColors.textSecondary,
          ),
        ),
        Gap(32),

        // Driver Card
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(Corners.md),
            border: Border.all(color: AppColors.greyStrong),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 35,
                    ),
                  ),
                  Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'John Doe',
                          style: TextStyles.t1.copyWith(
                            fontSize: FontSizes.s18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onAccent,
                          ),
                        ),
                        Gap(4),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            Gap(4),
                            Text(
                              '4.9',
                              style: TextStyles.t2.copyWith(
                                fontSize: FontSizes.s14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onAccent,
                              ),
                            ),
                            Gap(4),
                            Text(
                              '(234 trips)',
                              style: TextStyles.t2.copyWith(
                                fontSize: FontSizes.s13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.phone, color: AppColors.primary),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.message, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
              Gap(16),
              Divider(color: AppColors.greyStrong),
              Gap(12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vehicle',
                        style: TextStyles.t2.copyWith(
                          fontSize: FontSizes.s12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Gap(4),
                      Text(
                        'Toyota Camry',
                        style: TextStyles.t2.copyWith(
                          fontSize: FontSizes.s15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onAccent,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plate Number',
                        style: TextStyles.t2.copyWith(
                          fontSize: FontSizes.s12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Gap(4),
                      Text(
                        'ABC-123-XY',
                        style: TextStyles.t2.copyWith(
                          fontSize: FontSizes.s15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onAccent,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Color',
                        style: TextStyles.t2.copyWith(
                          fontSize: FontSizes.s12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Gap(4),
                      Text(
                        'Silver',
                        style: TextStyles.t2.copyWith(
                          fontSize: FontSizes.s15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        Gap(24),

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
              Gap(12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, color: AppColors.green400, size: 12),
                  Gap(12),
                  Expanded(
                    child: Text(
                      pickupLocation,
                      style: TextStyles.t2.copyWith(
                        fontSize: FontSizes.s14,
                        color: AppColors.onAccent,
                      ),
                    ),
                  ),
                ],
              ),
              Gap(8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, color: AppColors.accent, size: 12),
                  Gap(12),
                  Expanded(
                    child: Text(
                      destinationLocation,
                      style: TextStyles.t2.copyWith(
                        fontSize: FontSizes.s14,
                        color: AppColors.onAccent,
                      ),
                    ),
                  ),
                ],
              ),
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
                    '₦${rideAmount.toStringAsFixed(2)}',
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
        Gap(24),

        // Make Payment Button
        CustomButton(
          text: 'Make Payment',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment screen coming soon...')),
            );
          },
        ),
      ],
    );
  }
}
