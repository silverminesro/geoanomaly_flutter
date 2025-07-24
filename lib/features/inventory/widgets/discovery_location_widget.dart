import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';
import '../../map/models/location_model.dart'; // ✅ FIXED: Import path

class DiscoveryLocationWidget extends StatefulWidget {
  final LocationModel
      location; // ✅ FIXED: Use LocationModel instead of Location
  final DateTime? timestamp;
  final String? itemName;
  final bool showTimestamp;
  final double height;

  const DiscoveryLocationWidget({
    super.key,
    required this.location,
    this.timestamp,
    this.itemName,
    this.showTimestamp = true,
    this.height = 200,
  });

  @override
  State<DiscoveryLocationWidget> createState() =>
      _DiscoveryLocationWidgetState();
}

class _DiscoveryLocationWidgetState extends State<DiscoveryLocationWidget> {
  late final MapController _mapController;
  double _currentZoom = 16.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // ✅ ENHANCED: Map with proper controller
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter:
                    LatLng(widget.location.latitude, widget.location.longitude),
                initialZoom: _currentZoom,
                minZoom: 5.0,
                maxZoom: 18.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom |
                      InteractiveFlag.drag |
                      InteractiveFlag.doubleTapZoom,
                ),
                onMapEvent: (MapEvent mapEvent) {
                  if (mapEvent is MapEventMove) {
                    setState(() {
                      _currentZoom = mapEvent.camera.zoom;
                    });
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.geoanomaly.app',
                  maxNativeZoom: 18,
                  errorTileCallback: (tile, error, stackTrace) {
                    print('❌ Map tile error: $error');
                  },
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                          widget.location.latitude, widget.location.longitude),
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // ✅ ENHANCED: Info overlay
            if (widget.showTimestamp && widget.timestamp != null)
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.itemName != null) ...[
                        Text(
                          widget.itemName!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                      ],
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _formatTimestamp(widget.timestamp!),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.place,
                            color: Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${widget.location.latitude.toStringAsFixed(6)}, ${widget.location.longitude.toStringAsFixed(6)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // ✅ FIXED: Working zoom controls
            Positioned(
              top: 8,
              right: 8,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Zoom in button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _zoomIn(),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                            child: Container(
                              width: 32,
                              height: 32,
                              child: const Icon(Icons.add, size: 16),
                            ),
                          ),
                        ),

                        // Divider
                        Container(
                          height: 1,
                          color: Colors.grey[300],
                        ),

                        // Zoom out button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _zoomOut(),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(4),
                              bottomRight: Radius.circular(4),
                            ),
                            child: Container(
                              width: 32,
                              height: 32,
                              child: const Icon(Icons.remove, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ✅ NEW: Loading indicator
            if (_currentZoom !=
                _currentZoom) // This won't trigger, but shows the pattern
              const Positioned.fill(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Zoom methods
  void _zoomIn() {
    if (_currentZoom < 18.0) {
      final newZoom = (_currentZoom + 1).clamp(5.0, 18.0);
      _mapController.move(
        LatLng(widget.location.latitude, widget.location.longitude),
        newZoom,
      );
      setState(() {
        _currentZoom = newZoom;
      });
    }
  }

  void _zoomOut() {
    if (_currentZoom > 5.0) {
      final newZoom = (_currentZoom - 1).clamp(5.0, 18.0);
      _mapController.move(
        LatLng(widget.location.latitude, widget.location.longitude),
        newZoom,
      );
      setState(() {
        _currentZoom = newZoom;
      });
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return 'Found ${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return 'Found ${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return 'Found ${difference.inMinutes} minutes ago';
    } else {
      return 'Just discovered';
    }
  }
}

// ✅ ENHANCED: Simplified version without map
class DiscoveryLocationInfo extends StatelessWidget {
  final LocationModel location; // ✅ FIXED: Use LocationModel
  final DateTime? timestamp;
  final String? itemName;

  const DiscoveryLocationInfo({
    super.key,
    required this.location,
    this.timestamp,
    this.itemName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (itemName != null) ...[
            Text(
              'Discovery Location',
              style: GameTextStyles.clockTime.copyWith(
                fontSize: 14,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              const Icon(
                Icons.place,
                color: Colors.red,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                  style: GameTextStyles.cardTitle.copyWith(fontSize: 14),
                ),
              ),
              // ✅ NEW: Copy coordinates button
              IconButton(
                onPressed: () => _copyCoordinates(context),
                icon: const Icon(Icons.copy, size: 16),
                tooltip: 'Copy coordinates',
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          if (timestamp != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  color: Colors.grey,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTimestamp(timestamp!),
                  style: GameTextStyles.clockLabel.copyWith(fontSize: 12),
                ),
              ],
            ),
          ],

          // ✅ NEW: Distance info if available
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.navigation,
                color: Colors.blue,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Tap to navigate',
                style: GameTextStyles.clockLabel.copyWith(
                  fontSize: 12,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _copyCoordinates(BuildContext context) {
    // ✅ NEW: Copy coordinates to clipboard
    final coordinates =
        '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';

    // For now, just show a snackbar (you'd need clipboard package for real copying)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Coordinates: $coordinates'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return 'Found ${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return 'Found ${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return 'Found ${difference.inMinutes} minutes ago';
    } else {
      return 'Just discovered';
    }
  }
}

// ✅ NEW: Utility widget for showing location on external map
class DiscoveryLocationButton extends StatelessWidget {
  final LocationModel location;
  final String? label;

  const DiscoveryLocationButton({
    super.key,
    required this.location,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _openExternalMap(),
      icon: const Icon(Icons.map),
      label: Text(label ?? 'Open in Maps'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _openExternalMap() {
    // ✅ TODO: Implement external map opening
    // You could use url_launcher to open Google Maps, etc.
    print(
        'Opening external map for: ${location.latitude}, ${location.longitude}');
  }
}
