import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/zone_model.dart';
import '../services/location_tracking_service.dart';

// Zone Tracking State
class ZoneTrackingState {
  final Zone? currentZone;
  final List<ZoneWithDetails> nearbyZones;
  final bool isTracking;
  final String? lastMessage;
  final DateTime? lastUpdate;

  const ZoneTrackingState({
    this.currentZone,
    this.nearbyZones = const [],
    this.isTracking = false,
    this.lastMessage,
    this.lastUpdate,
  });

  ZoneTrackingState copyWith({
    Zone? currentZone,
    List<ZoneWithDetails>? nearbyZones,
    bool? isTracking,
    String? lastMessage,
    DateTime? lastUpdate,
    bool clearCurrentZone = false,
  }) {
    return ZoneTrackingState(
      currentZone: clearCurrentZone ? null : (currentZone ?? this.currentZone),
      nearbyZones: nearbyZones ?? this.nearbyZones,
      isTracking: isTracking ?? this.isTracking,
      lastMessage: lastMessage ?? this.lastMessage,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }

  @override
  String toString() {
    return 'ZoneTrackingState(currentZone: ${currentZone?.name}, '
        'nearbyZones: ${nearbyZones.length}, isTracking: $isTracking)';
  }
}

// Zone Tracking Notifier
class ZoneTrackingNotifier extends StateNotifier<ZoneTrackingState> {
  ZoneTrackingNotifier() : super(const ZoneTrackingState()) {
    _setupLocationTrackingCallbacks();
  }

  void _setupLocationTrackingCallbacks() {
    final service = LocationTrackingService.instance;

    service.onZoneEntered = (zone) {
      print('🎯 Zone entered callback: ${zone.name}');
      state = state.copyWith(
        currentZone: zone,
        lastMessage: 'Entered ${zone.name}',
        lastUpdate: DateTime.now(),
      );
    };

    service.onZoneExited = (zone) {
      print('🚪 Zone exited callback: ${zone.name}');
      state = state.copyWith(
        clearCurrentZone: true,
        lastMessage: 'Exited ${zone.name}',
        lastUpdate: DateTime.now(),
      );
    };

    service.onError = (error) {
      print('❌ Zone tracking error: $error');
      state = state.copyWith(
        lastMessage: 'Error: $error',
        lastUpdate: DateTime.now(),
      );
    };
  }

  void startTracking() {
    print('🎯 Starting zone tracking...');
    LocationTrackingService.instance.startTracking();
    state = state.copyWith(
      isTracking: true,
      lastMessage: 'Zone tracking started',
      lastUpdate: DateTime.now(),
    );
  }

  void stopTracking() {
    print('⏹️ Stopping zone tracking...');
    LocationTrackingService.instance.stopTracking();
    state = state.copyWith(
      isTracking: false,
      clearCurrentZone: true,
      lastMessage: 'Zone tracking stopped',
      lastUpdate: DateTime.now(),
    );
  }

  void updateNearbyZones(List<ZoneWithDetails> zones) {
    print('📍 Updating nearby zones: ${zones.length} zones');
    LocationTrackingService.instance.updateNearbyZones(zones);
    state = state.copyWith(
      nearbyZones: zones,
      lastMessage: 'Updated ${zones.length} nearby zones',
      lastUpdate: DateTime.now(),
    );
  }

  void clearMessage() {
    state = state.copyWith(lastMessage: null);
  }

  @override
  void dispose() {
    LocationTrackingService.instance.dispose();
    super.dispose();
  }
}

// Provider
final zoneTrackingProvider =
    StateNotifierProvider<ZoneTrackingNotifier, ZoneTrackingState>((ref) {
  return ZoneTrackingNotifier();
});

// Convenience providers
final currentZoneProvider = Provider<Zone?>((ref) {
  return ref.watch(zoneTrackingProvider).currentZone;
});

final isZoneTrackingProvider = Provider<bool>((ref) {
  return ref.watch(zoneTrackingProvider).isTracking;
});

final zoneTrackingMessageProvider = Provider<String?>((ref) {
  return ref.watch(zoneTrackingProvider).lastMessage;
});
