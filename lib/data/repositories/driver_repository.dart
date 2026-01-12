import 'dart:async';
import '../models/driver.dart';
import '../models/location_model.dart';
import '../../core/utils/location_helper.dart';

class DriverRepository {
  final List<Driver> _mockDrivers = [];
  final StreamController<List<Driver>> _driversController =
      StreamController<List<Driver>>.broadcast();

  DriverRepository() {
    _initializeMockDrivers();
  }

  /// Get stream of available drivers
  Stream<List<Driver>> get driversStream => _driversController.stream;

  /// Initialize mock drivers with random locations
  void _initializeMockDrivers() {
    // San Francisco coordinates as default center
    const centerLat = 37.7749;
    const centerLng = -122.4194;

    final driverNames = [
      'John Smith',
      'Sarah Johnson',
      'Michael Brown',
      'Emily Davis',
      'David Wilson',
    ];

    final vehicles = [
      {'model': 'Toyota Camry', 'number': 'ABC-1234'},
      {'model': 'Honda Accord', 'number': 'XYZ-5678'},
      {'model': 'Tesla Model 3', 'number': 'EV-9012'},
      {'model': 'Ford Fusion', 'number': 'DEF-3456'},
      {'model': 'Hyundai Sonata', 'number': 'GHI-7890'},
    ];

    for (int i = 0; i < driverNames.length; i++) {
      final location = LocationHelper.getRandomLocationNearby(
        centerLat,
        centerLng,
        5.0, // 5 km radius
      );

      final driver = Driver(
        id: 'driver_$i',
        name: driverNames[i],
        phone: '+1${1234567890 + i}',
        vehicleModel: vehicles[i]['model']!,
        vehicleNumber: vehicles[i]['number']!,
        rating: 4.5 + (i * 0.1),
        totalRides: 100 + (i * 50),
        isAvailable: true,
        currentLocation: LocationModel(
          latitude: location['latitude']!,
          longitude: location['longitude']!,
        ),
      );

      _mockDrivers.add(driver);
    }

    _driversController.add(List.from(_mockDrivers));
  }

  /// Get all available drivers
  List<Driver> getAvailableDrivers() {
    return _mockDrivers.where((d) => d.isAvailable).toList();
  }

  /// Get driver by ID
  Driver? getDriverById(String driverId) {
    try {
      return _mockDrivers.firstWhere((d) => d.id == driverId);
    } catch (e) {
      return null;
    }
  }

  /// Update driver location
  Future<Driver?> updateDriverLocation(
    String driverId,
    LocationModel location,
  ) async {
    try {
      final index = _mockDrivers.indexWhere((d) => d.id == driverId);
      if (index == -1) return null;

      final updatedDriver = _mockDrivers[index].copyWith(
        currentLocation: location,
      );

      _mockDrivers[index] = updatedDriver;
      _driversController.add(List.from(_mockDrivers));

      return updatedDriver;
    } catch (e) {
      print('Error updating driver location: $e');
      return null;
    }
  }

  /// Update driver availability
  Future<Driver?> updateDriverAvailability(
    String driverId,
    bool isAvailable,
  ) async {
    try {
      final index = _mockDrivers.indexWhere((d) => d.id == driverId);
      if (index == -1) return null;

      final updatedDriver = _mockDrivers[index].copyWith(
        isAvailable: isAvailable,
      );

      _mockDrivers[index] = updatedDriver;
      _driversController.add(List.from(_mockDrivers));

      return updatedDriver;
    } catch (e) {
      print('Error updating driver availability: $e');
      return null;
    }
  }

  /// Find nearby drivers
  List<Driver> findNearbyDrivers(LocationModel location, double radiusKm) {
    return _mockDrivers.where((driver) {
      if (!driver.isAvailable || driver.currentLocation == null) {
        return false;
      }

      final distance = LocationHelper.calculateDistance(
        location.latitude,
        location.longitude,
        driver.currentLocation!.latitude,
        driver.currentLocation!.longitude,
      );

      return distance <= radiusKm;
    }).toList();
  }

  void dispose() {
    _driversController.close();
  }
}
