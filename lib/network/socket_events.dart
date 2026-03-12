/// Socket event names used by the DRUP real-time system
class SocketEvents {
  SocketEvents._();

  // ── Connection ──────────────────────────────────────────────
  static const String connect = 'connect';
  static const String disconnect = 'disconnect';
  static const String connectError = 'connect_error';

  // ── Ride / Delivery matching ────────────────────────────────
  /// Driver receives – a new ride/delivery needs pickup
  static const String rideNew = 'ride:new';

  /// Passenger receives – a driver accepted the ride/delivery
  static const String rideMatched = 'ride:matched';

  /// Passenger receives – driver has arrived at pickup location
  static const String rideDriverArrived = 'ride:driver_arrived';

  /// Passenger receives – driver cancelled the ride/delivery
  static const String rideCancelled = 'ride:cancelled';

  // ── Delivery-specific ───────────────────────────────────────
  /// Passenger receives – driver picked up the package
  static const String deliveryPackagePickedUp = 'delivery:package_picked_up';

  /// Passenger receives – package has been delivered
  static const String deliveryCompleted = 'delivery:completed';
}
