import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../services/location_service.dart';
import '../services/zone_service.dart';
import '../models/location_model.dart';
import '../models/zone_model.dart';
import '../models/scan_result_model.dart';
import '../widgets/zone_info_card.dart';
import '../widgets/scan_button.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LocationModel? _currentLocation;
  Set<Marker> _markers = {};
  List<Zone> _zones = [];
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
      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(location.latitude, location.longitude),
          ),
        );
      }

      // Auto-scan area on first load
      await _scanArea();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error getting location: $e');
    }
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

      _showSuccessSnackBar(
          'Found ${scanResult.zones.length} zones! (${scanResult.zonesCreated} new)');
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      _showErrorSnackBar('Error scanning area: $e');
    }
  }

  Set<Marker> _createZoneMarkers(List<Zone> zones) {
    return zones.map((zone) {
      return Marker(
        markerId: MarkerId(zone.id),
        position: LatLng(zone.location.latitude, zone.location.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _getMarkerColor(zone.tierRequired),
        ),
        infoWindow: InfoWindow(
          title: zone.name,
          snippet:
              '${zone.biomeEmoji} ${zone.dangerLevelEmoji} Tier ${zone.tierRequired}',
        ),
        onTap: () => _showZoneDetails(zone),
      );
    }).toSet();
  }

  double _getMarkerColor(int tier) {
    switch (tier) {
      case 0:
        return BitmapDescriptor.hueGreen; // Free - Green
      case 1:
        return BitmapDescriptor.hueBlue; // Basic - Blue
      case 2:
        return BitmapDescriptor.hueYellow; // Standard - Yellow
      case 3:
        return BitmapDescriptor.hueOrange; // Premium - Orange
      case 4:
        return BitmapDescriptor.hueRed; // Elite - Red
      default:
        return BitmapDescriptor.hueBlue;
    }
  }

  void _showZoneDetails(Zone zone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ZoneInfoCard(
        zone: zone,
        onEnterZone: () => _enterZone(zone),
        onNavigateToZone: () => _navigateToZone(zone),
      ),
    );
  }

  Future<void> _enterZone(Zone zone) async {
    try {
      Navigator.pop(context); // Close bottom sheet

      setState(() {
        _isLoading = true;
      });

      await _zoneService.enterZone(zone.id);

      setState(() {
        _isLoading = false;
      });

      _showSuccessSnackBar('Successfully entered ${zone.name}!');

      // Navigate to zone detail screen
      context.go('/zone/${zone.id}');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error entering zone: $e');
    }
  }

  void _navigateToZone(Zone zone) {
    Navigator.pop(context); // Close bottom sheet
    context.go('/zone/${zone.id}');
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          IconButton(
            icon: Icon(Icons.person, color: Colors.white),
            onPressed: () => context.go('/profile'),
          ),
          IconButton(
            icon: Icon(Icons.inventory_2, color: Colors.white),
            onPressed: () => context.go('/inventory'),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Maps
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation != null
                  ? LatLng(
                      _currentLocation!.latitude, _currentLocation!.longitude)
                  : LatLng(48.1486, 17.1077), // Fallback to Bratislava
              zoom: 15,
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // We'll use custom button
            compassEnabled: true,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
            onTap: (LatLng latLng) {
              // Hide any open bottom sheets
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
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
              onPressed: () async {
                try {
                  final location = await LocationService.getCurrentLocation();
                  setState(() {
                    _currentLocation = location;
                  });

                  await _mapController?.animateCamera(
                    CameraUpdate.newLatLng(
                      LatLng(location.latitude, location.longitude),
                    ),
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
              top: 20,
              left: 20,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_zones.length} zones found',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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
    _mapController?.dispose();
    super.dispose();
  }
}
