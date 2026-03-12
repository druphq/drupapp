import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../core/cache/cache_manager.dart';
import '../core/constants/constants.dart';
import 'socket_events.dart';
import 'socket_models.dart';

/// Singleton Socket.IO client for real-time ride / delivery events.
///
/// Connects to the server's base URL (without the `/api/v1` suffix) and
/// authenticates with the stored JWT. The [userType] controls which namespace
/// (`/passenger` or `/driver`) the socket joins, so each side only receives
/// the events it cares about.
class SocketClient {
  static SocketClient? _instance;

  io.Socket? _socket;
  bool _isConnected = false;
  UserType? _userType;

  // ── Stream controllers (broadcast so multiple listeners are allowed) ──
  final _rideNewController = StreamController<RideNewEvent>.broadcast();
  final _rideMatchedController = StreamController<RideMatchedEvent>.broadcast();
  final _rideDriverArrivedController =
      StreamController<RideDriverArrivedEvent>.broadcast();
  final _rideCancelledController =
      StreamController<RideCancelledEvent>.broadcast();
  final _deliveryPickedUpController =
      StreamController<DeliveryPackagePickedUpEvent>.broadcast();
  final _deliveryCompletedController =
      StreamController<DeliveryCompletedEvent>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  // ── Public streams ─────────────────────────────────────────
  /// Emits new ride/delivery requests – only relevant for **drivers**.
  Stream<RideNewEvent> get onRideNew => _rideNewController.stream;

  /// Emits when a driver accepts the ride/delivery – only relevant for **passengers**.
  Stream<RideMatchedEvent> get onRideMatched => _rideMatchedController.stream;

  /// Emits when driver arrives at pickup – only relevant for **passengers**.
  Stream<RideDriverArrivedEvent> get onRideDriverArrived =>
      _rideDriverArrivedController.stream;

  /// Emits when a ride/delivery is cancelled – only relevant for **drivers**.
  Stream<RideCancelledEvent> get onRideCancelled =>
      _rideCancelledController.stream;

  /// Emits when driver picks up the package – only relevant for **passengers**.
  Stream<DeliveryPackagePickedUpEvent> get onDeliveryPackagePickedUp =>
      _deliveryPickedUpController.stream;

  /// Emits when package is delivered – only relevant for **passengers**.
  Stream<DeliveryCompletedEvent> get onDeliveryCompleted =>
      _deliveryCompletedController.stream;

  /// Emits `true` / `false` when the socket connects / disconnects.
  Stream<bool> get onConnectionChange => _connectionController.stream;

  bool get isConnected => _isConnected;
  UserType? get userType => _userType;

  // ── Singleton accessor ─────────────────────────────────────
  SocketClient._();

  static SocketClient get instance {
    _instance ??= SocketClient._();
    return _instance!;
  }

  // ── Derive the socket URL from the API base URL ────────────
  /// The .env `API_BASE_URL` usually looks like
  /// `https://apiv1.drupapp.com/api/v1`.
  /// Socket.IO should connect to the origin (`https://apiv1.drupapp.com`).
  static String get _baseSocketUrl {
    final apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
    final uri = Uri.parse(apiBaseUrl);
    return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
  }

  // ── Connect ────────────────────────────────────────────────
  /// Opens the socket connection for the given [userType].
  ///
  /// * **passenger** → connects to the `/passenger` namespace.
  /// * **driver**    → connects to the `/driver` namespace.
  ///
  /// The auth token is read from [CacheManager] (`accessToken`).
  Future<void> connect({required UserType userType}) async {
    // Avoid double-connecting to the same role.
    if (_isConnected && _userType == userType) {
      debugPrint('SocketClient: already connected as ${userType.name}');
      return;
    }

    // Disconnect any previous session first.
    await disconnect();

    _userType = userType;

    final token = await CacheManager.instance.getString('access_token');
    final namespace = userType == UserType.driver ? '/driver' : '/passenger';
    final url = '$_baseSocketUrl$namespace';

    debugPrint('SocketClient: connecting to $url');

    _socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token ?? ''})
          .setExtraHeaders({'Authorization': 'Bearer ${token ?? ''}'})
          .build(),
    );

    _registerCoreListeners();
    _registerEventListeners();

    _socket!.connect();
  }

  // ── Disconnect ─────────────────────────────────────────────
  Future<void> disconnect() async {
    if (_socket != null) {
      _socket!.clearListeners();
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    _isConnected = false;
    _userType = null;
    _connectionController.add(false);
    debugPrint('SocketClient: disconnected');
  }

  // ── Emit an event ──────────────────────────────────────────
  /// Generic helper to emit any event over the socket.
  void emit(String event, [dynamic data]) {
    if (_socket == null || !_isConnected) {
      debugPrint('SocketClient: cannot emit "$event" – not connected');
      return;
    }
    _socket!.emit(event, data);
  }

  // ── Core connection listeners ──────────────────────────────
  void _registerCoreListeners() {
    _socket!.onConnect((_) {
      _isConnected = true;
      _connectionController.add(true);
      debugPrint('SocketClient: connected (${_userType?.name})');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      _connectionController.add(false);
      debugPrint('SocketClient: disconnected');
    });

    _socket!.onConnectError((error) {
      _isConnected = false;
      _connectionController.add(false);
      debugPrint('SocketClient: connection error → $error');
    });

    _socket!.onReconnect((_) {
      _isConnected = true;
      _connectionController.add(true);
      debugPrint('SocketClient: reconnected');
    });
  }

  // ── Business event listeners ───────────────────────────────
  void _registerEventListeners() {
    // Driver-side: incoming ride / delivery requests
    _socket!.on(SocketEvents.rideNew, (data) {
      try {
        final event = RideNewEvent.fromJson(
          Map<String, dynamic>.from(data as Map),
        );
        debugPrint(
          'SocketClient: ride:new → ${event.rideNumber} (${event.rideType})',
        );
        _rideNewController.add(event);
      } catch (e, s) {
        debugPrint('SocketClient: error parsing ride:new → $e\n$s');
      }
    });

    // Passenger-side: ride matched with a driver
    _socket!.on(SocketEvents.rideMatched, (data) {
      try {
        final event = RideMatchedEvent.fromJson(
          Map<String, dynamic>.from(data as Map),
        );
        debugPrint(
          'SocketClient: ride:matched → ${event.rideNumber} '
          '(driver: ${event.driver.fullName})',
        );
        _rideMatchedController.add(event);
      } catch (e, s) {
        debugPrint('SocketClient: error parsing ride:matched → $e\n$s');
      }
    });

    // Passenger-side: driver arrived at pickup
    _socket!.on(SocketEvents.rideDriverArrived, (data) {
      try {
        final event = RideDriverArrivedEvent.fromJson(
          Map<String, dynamic>.from(data as Map),
        );
        debugPrint('SocketClient: ride:driver_arrived → ${event.rideNumber}');
        _rideDriverArrivedController.add(event);
      } catch (e, s) {
        debugPrint('SocketClient: error parsing ride:driver_arrived → $e\n$s');
      }
    });

    // Driver-side: user cancelled the ride/delivery
    _socket!.on(SocketEvents.rideCancelled, (data) {
      try {
        final event = RideCancelledEvent.fromJson(
          Map<String, dynamic>.from(data as Map),
        );
        debugPrint('SocketClient: ride:cancelled → ${event.rideNumber}');
        _rideCancelledController.add(event);
      } catch (e, s) {
        debugPrint('SocketClient: error parsing ride:cancelled → $e\n$s');
      }
    });

    // Passenger-side: driver picked up the package
    _socket!.on(SocketEvents.deliveryPackagePickedUp, (data) {
      try {
        final event = DeliveryPackagePickedUpEvent.fromJson(
          Map<String, dynamic>.from(data as Map),
        );
        debugPrint(
          'SocketClient: delivery:package_picked_up → ${event.rideNumber}',
        );
        _deliveryPickedUpController.add(event);
      } catch (e, s) {
        debugPrint(
          'SocketClient: error parsing delivery:package_picked_up → $e\n$s',
        );
      }
    });

    // Passenger-side: package delivered
    _socket!.on(SocketEvents.deliveryCompleted, (data) {
      try {
        final event = DeliveryCompletedEvent.fromJson(
          Map<String, dynamic>.from(data as Map),
        );
        debugPrint('SocketClient: delivery:completed → ${event.rideNumber}');
        _deliveryCompletedController.add(event);
      } catch (e, s) {
        debugPrint('SocketClient: error parsing delivery:completed → $e\n$s');
      }
    });
  }

  // ── Cleanup ────────────────────────────────────────────────
  /// Call when the app is terminating to release resources.
  void dispose() {
    disconnect();
    _rideNewController.close();
    _rideMatchedController.close();
    _rideDriverArrivedController.close();
    _rideCancelledController.close();
    _deliveryPickedUpController.close();
    _deliveryCompletedController.close();
    _connectionController.close();
    _instance = null;
  }
}
