import 'package:drup/data/cache/location_cache.dart';
import 'package:drup/resources/app_assets.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../providers/providers.dart';
import '../../../../providers/ride_notifier.dart';
import '../../../../data/models/location_model.dart';

class NigeriaAirportsScreen extends ConsumerStatefulWidget {
  final bool isPickupLocation;

  const NigeriaAirportsScreen({super.key, required this.isPickupLocation});

  @override
  ConsumerState<NigeriaAirportsScreen> createState() =>
      _NigeriaAirportsScreenState();
}

class _NigeriaAirportsScreenState extends ConsumerState<NigeriaAirportsScreen> {
  List<Map<String, dynamic>> _airports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAirports();
  }

  Future<void> _loadAirports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cachedAirports = await LocationCache.getCachedAirports();
      if (cachedAirports.isNotEmpty) {
        setState(() {
          _airports = cachedAirports;
          _isLoading = false;
        });
        return;
      }
      
      final mapsService = ref.read(googleMapsServiceProvider);
      final airports = await mapsService.loadNigerianAirports();
      await LocationCache.cachedAirports(airports);

      setState(() {
        _airports = airports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading airports: $e')));
      }
    }
  }

  void _selectAirport(Map<String, dynamic> airport) {
    final location = LocationModel(
      latitude: airport['latitude'],
      longitude: airport['longitude'],
      name: airport['name'],
      address: airport['address'],
    );

    // Update the corresponding location in ride state
    if (widget.isPickupLocation) {
      ref.read(rideNotifierProvider.notifier).setPickupLocation(location);
    } else {
      ref.read(rideNotifierProvider.notifier).setDestinationLocation(location);
    }

    // Go back with the selected airport
    context.pop(airport);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.isPickupLocation ? 'Select Pickup' : 'Select Destination',
          style: TextStyles.t1.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        scrolledUnderElevation: 0.0,
      ),
      body: Container(
        decoration: const BoxDecoration(
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
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Airports List
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : _airports.isEmpty
                      ? Center(
                          child: Text(
                            'No airports found',
                            style: TextStyles.t1.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _airports.length,
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (context, index) {
                            final airport = _airports[index];
                            return _buildAirportCard(airport);
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAirportCard(Map<String, dynamic> airport) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Corners.md),
        color: Colors.black.withValues(alpha: 0.2),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: ImageIcon(
          AssetImage(AppAssets.flightIcon),
          color: Colors.white70,
          size: 18,
        ),
        title: Text(
          airport['name'],
          style: TextStyles.t2.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          airport['address'] ?? '',
          style: TextStyles.h3.copyWith(fontSize: 14, color: Colors.white),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
        onTap: () => _selectAirport(airport),
      ),
    );
  }
}
