import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../services/location_service.dart';
import '../services/zone_service.dart';
import '../models/location_model.dart';
import '../../../core/models/zone_model.dart'; // ✅ Use core models
import '../models/scan_result_model.dart';
import '../widgets/zone_info_card.dart';
import '../widgets/scan_button.dart';
import '../providers/zone_tracking_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  LocationModel? _currentLocation;
  List<Marker> _markers = [];
  List<ZoneWithDetails> _zones = []; // ✅ Using core ZoneWithDetails
  ScanResultModel? _lastScanResult;
  bool _isLoading = false;
  bool _isScanning = false;

  final ZoneService _zoneService = ZoneService();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final location = await LocationService.getCurrentLocation();
      setState(() {
        _currentLocation = location;
        _isLoading = false;
      });

      // Move camera to current location
      _mapController.move(
        LatLng(location.latitude, location.longitude),
        15.0,
      );

      // ✅ START ZONE TRACKING AUTOMATICALLY
      _startZoneTracking();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error getting location: $e');
    }
  }

  void _startZoneTracking() {
    print('🎯 Starting zone tracking from MapScreen');
    ref.read(zoneTrackingProvider.notifier).startTracking();
  }

  Future<void> _scanArea() async {
    if (_currentLocation == null) {
      _showErrorSnackBar('Location not available');
      return;
    }

    // Check cooldown
    if (_lastScanResult != null && !_lastScanResult!.canScanAgain) {
      final remaining = _lastScanResult!.cooldownRemaining;
      _showErrorSnackBar(
          'Scan cooldown: ${remaining.inMinutes}m ${remaining.inSeconds % 60}s remaining');
      return;
    }

    setState(() {
      _isScanning = true;
    });

    try {
      final scanResult = await _zoneService.scanArea(_currentLocation!);

      setState(() {
        _lastScanResult = scanResult;
        _zones = scanResult.zones;
        _markers = _createZoneMarkers(scanResult.zones);
        _isScanning = false;
      });

      // ✅ UPDATE NEARBY ZONES FOR AUTOMATIC TRACKING
      ref
          .read(zoneTrackingProvider.notifier)
          .updateNearbyZones(scanResult.zones);

      _showSuccessSnackBar(
          'Found ${scanResult.zones.length} zones! (${scanResult.zonesCreated} new)');
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      _showErrorSnackBar('Error scanning area: $e');
    }
  }

  List<Marker> _createZoneMarkers(List<ZoneWithDetails> zones) {
    return zones.map((zoneWithDetails) {
      final zone = zoneWithDetails.zone;
      return Marker(
        point: LatLng(zone.location.latitude, zone.location.longitude),
        width: 50,
        height: 50,
        child: GestureDetector(
          onTap: () => _showZoneDetails(zoneWithDetails),
          child: Container(
            decoration: BoxDecoration(
              color: _getMarkerColor(zone.tierRequired),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getBiomeEmoji(zone.biome ?? 'unknown'),
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    'T${zone.tierRequired}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  // ✅ HELPER: Get biome emoji since it's not in Zone model
  String _getBiomeEmoji(String biome) {
    switch (biome.toLowerCase()) {
      case 'forest':
        return '🌲';
      case 'swamp':
        return '🐸';
      case 'desert':
        return '🏜️';
      case 'mountain':
        return '⛰️';
      case 'wasteland':
        return '☠️';
      case 'volcanic':
        return '🌋';
      default:
        return '🌍';
    }
  }

  Color _getMarkerColor(int tier) {
    switch (tier) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.yellow;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  void _showZoneDetails(ZoneWithDetails zoneWithDetails) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ZoneInfoCard(
        zone: zoneWithDetails.zone,
        zoneDetails: zoneWithDetails,
        onEnterZone: () => _enterZone(zoneWithDetails.zone),
        onNavigateToZone: () => _navigateToZone(zoneWithDetails.zone),
      ),
    );
  }

  Future<void> _enterZone(Zone zone) async {
    try {
      Navigator.pop(context);
      setState(() {
        _isLoading = true;
      });

      await _zoneService.enterZone(zone.id);

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        _showSuccessSnackBar('Successfully entered ${zone.name}!');
        context.go('/zone/${zone.id}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error entering zone: $e');
    }
  }

  void _navigateToZone(Zone zone) {
    Navigator.pop(context);
    context.go('/zone/${zone.id}');
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ WATCH ZONE TRACKING STATE
    final zoneTrackingState = ref.watch(zoneTrackingProvider);
    final currentZone = zoneTrackingState.currentZone;
    final trackingMessage = zoneTrackingState.lastMessage;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'GeoAnomaly',
          style: GameTextStyles.clockTime.copyWith(
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          // ✅ ZONE TRACKING STATUS INDICATOR
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color:
                      zoneTrackingState.isTracking ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () => context.go('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.inventory_2, color: Colors.white),
            onPressed: () => context.go('/inventory'),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 🗺️ Flutter Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation != null
                  ? LatLng(
                      _currentLocation!.latitude, _currentLocation!.longitude)
                  : const LatLng(48.1486, 17.1077),
              initialZoom: 15.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              onTap: (tapPosition, point) {
                // Hide any open bottom sheets
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            children: [
              // 🌍 OpenStreetMap tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.geoanomaly.app',
                maxNativeZoom: 18,
              ),

              // 📍 Zone markers
              MarkerLayer(
                markers: _markers,
              ),

              // 📍 Current location marker
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        _currentLocation!.latitude,
                        _currentLocation!.longitude,
                      ),
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ✅ CURRENT ZONE INDICATOR
          if (currentZone != null)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Currently in Zone:',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            currentZone.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _getBiomeEmoji(currentZone.biome ?? 'unknown'),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ],
                ),
              ),
            ),

          // ✅ ZONE TRACKING MESSAGE (temporary notifications)
          if (trackingMessage != null)
            Positioned(
              top: currentZone != null ? 100 : 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        trackingMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 16),
                      onPressed: () {
                        ref.read(zoneTrackingProvider.notifier).clearMessage();
                      },
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: const EdgeInsets.all(4),
                    ),
                  ],
                ),
              ),
            ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
              ),
            ),

          // Scan button
          Positioned(
            bottom: 100,
            right: 20,
            child: ScanButton(
              onPressed: _isScanning ? null : _scanArea,
              isScanning: _isScanning,
              cooldownRemaining: _lastScanResult?.cooldownRemaining,
            ),
          ),

          // Location button
          Positioned(
            bottom: 180,
            right: 20,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              heroTag: "location_button",
              onPressed: () async {
                try {
                  final location = await LocationService.getCurrentLocation();
                  setState(() {
                    _currentLocation = location;
                  });

                  _mapController.move(
                    LatLng(location.latitude, location.longitude),
                    15.0,
                  );
                } catch (e) {
                  _showErrorSnackBar('Error getting location: $e');
                }
              },
              child: Icon(
                Icons.my_location,
                color: AppTheme.primaryColor,
              ),
            ),
          ),

          // Zone count info
          if (_zones.isNotEmpty)
            Positioned(
              top: currentZone != null
                  ? (trackingMessage != null ? 180 : 100)
                  : 20,
              left: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_zones.length} zones found',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // ✅ STOP ZONE TRACKING
    ref.read(zoneTrackingProvider.notifier).stopTracking();
    _mapController.dispose();
    super.dispose();
  }
}