import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import 'dart:async';

import '../../../core/theme/app_theme.dart';
import '../models/detector_model.dart';
import '../models/artifact_model.dart'; // NEW MODEL NEEDED
import '../services/zone_service.dart';

class DetectorScreen extends ConsumerStatefulWidget {
  final String zoneId;
  final Detector selectedDetector;

  const DetectorScreen({
    super.key,
    required this.zoneId,
    required this.selectedDetector,
  });

  @override
  ConsumerState<DetectorScreen> createState() => _DetectorScreenState();
}

class _DetectorScreenState extends ConsumerState<DetectorScreen>
    with TickerProviderStateMixin {
  // State
  List<DetectableItem> _artifacts = [];
  List<DetectableItem> _gear = [];
  List<DetectableItem> _allItems = [];
  List<DetectableItem> _detectableItems = [];
  Position? _currentPosition;
  bool _isScanning = false;
  bool _isLoading = true;
  String _status = 'Initializing detector...';
  
  late ZoneService _zoneService;

  // Animation
  late AnimationController _radarController;
  late AnimationController _pulseController;

  // Timers
  Timer? _locationTimer;
  Timer? _scanTimer;

  // Detection
  DetectableItem? _closestItem;
  double _signalStrength = 0.0;
  String _direction = '';

  @override
  void initState() {
    super.initState();
    _zoneService = ZoneService();
    _initializeAnimations();
    _loadArtifacts();
    _startLocationUpdates();
  }

  void _initializeAnimations() {
    _radarController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _radarController.repeat();
  }

  Future<void> _loadArtifacts() async {
    try {
      setState(() {
        _isLoading = true;
        _status = 'Loading artifacts from zone...';
      });

      // TODO: Replace with real API call
      final response = await _zoneService.getZoneArtifacts(widget.zoneId);

      setState(() {
        _artifacts = response['artifacts']
                ?.map<DetectableItem>((json) => DetectableItem.fromJson(json))
                ?.toList() ??
            [];
        _gear = response['gear']
                ?.map<DetectableItem>((json) => DetectableItem.fromJson(json))
                ?.toList() ??
            [];
        
        // Update combined lists
        _allItems = [..._artifacts, ..._gear];
        _detectableItems = [..._allItems]; // Start with all items as detectable
        
        _isLoading = false;
        _status =
            'Detector ready. ${_allItems.length} items detected.';
      });

      _startScanning();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Error loading artifacts: $e';
      });
    }
  }

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _currentPosition = position;
        });
        _updateDetection();
      } catch (e) {
        print('Location update error: $e');
      }
    });
  }

  void _startScanning() {
    setState(() => _isScanning = true);

    _scanTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (_currentPosition != null) {
        _updateDetection();
      }
    });

    _pulseController.repeat(reverse: true);
  }

  void _updateDetection() {
    if (_currentPosition == null) return;

    if (_detectableItems.isEmpty) return;

    // Find closest item
    DetectableItem? closest;
    double minDistance = double.infinity;

    for (final item in _detectableItems) {
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        item.latitude,
        item.longitude,
      );

      // Update isVeryClose property for 2m proximity check
      item.isVeryClose = distance <= 2.0;

      if (distance < minDistance) {
        minDistance = distance;
        closest = item;
      }
    }

    if (closest != null) {
      setState(() {
        _closestItem = closest;
        _signalStrength = _calculateSignalStrength(minDistance);
        _direction = _calculateDirection(closest!);
        _status = _getDetectorStatus(closest!, minDistance);
      });
    }
  }

  double _calculateSignalStrength(double distance) {
    // Signal strength based on detector type and distance
    final maxRange =
        widget.selectedDetector.range * 50.0; // 50m per range point
    final strength = math.max(0.0, 1.0 - (distance / maxRange));

    // Add detector precision influence
    final precision = widget.selectedDetector.precision / 5.0;
    return (strength * precision).clamp(0.0, 1.0);
  }

  String _calculateDirection(DetectableItem item) {
    if (_currentPosition == null) return '';

    final bearing = Geolocator.bearingBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      item.latitude,
      item.longitude,
    );

    return _bearingToCompass(bearing);
  }

  String _bearingToCompass(double bearing) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((bearing + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  String _getDetectorStatus(DetectableItem item, double distance) {
    if (distance < 2.0) {
      return '🎯 TARGET ACQUIRED! ${item.name} directly ahead!';
    } else if (distance < 5.0) {
      return '🔥 STRONG SIGNAL: ${item.name} very close!';
    } else if (distance < 15.0) {
      return '📡 Signal detected: ${item.rarity} ${item.type}';
    } else if (distance < 30.0) {
      return '📶 Weak signal: Something ${_direction}...';
    } else {
      return '🔍 Scanning... Move closer to targets.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: AppTheme.primaryColor,
        title: Text(
          widget.selectedDetector.name,
          style: GameTextStyles.clockTime.copyWith(
            color: AppTheme.primaryColor,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _showDetectorSettings,
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingScreen() : _buildDetectorInterface(),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryColor),
          SizedBox(height: 20),
          Text(
            _status,
            style: TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetectorInterface() {
    return Column(
      children: [
        // Status Bar
        _buildStatusBar(),

        // Main Radar Display
        Expanded(
          flex: 3,
          child: _buildRadarDisplay(),
        ),

        // Signal Strength & Direction
        _buildSignalInfo(),

        // Control Buttons
        _buildControlButtons(),
      ],
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.grey[900],
      child: Row(
        children: [
          // Battery indicator for detector
          Icon(Icons.battery_full, color: _getBatteryColor()),
          SizedBox(width: 8),

          // Signal strength bars
          ..._buildSignalBars(),

          Spacer(),

          // Items count
          Text(
            '${_detectableItems.length} targets',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarDisplay() {
    return Container(
      margin: EdgeInsets.all(20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radar Grid
          AnimatedBuilder(
            animation: _radarController,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: RadarPainter(
                  sweepAngle: _radarController.value * 2 * math.pi,
                  signalStrength: _signalStrength,
                  detectorType: widget.selectedDetector,
                ),
              );
            },
          ),

          // Target blips
          if (_closestItem != null) ..._buildTargetBlips(),

          // Center point (player)
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.5),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTargetBlips() {
    if (_closestItem == null || _signalStrength < 0.1) return [];

    // Calculate blip position based on direction and distance
    final angle = _getDirectionAngle(_direction) * math.pi / 180;
    final distance =
        (1.0 - _signalStrength) * 100; // Max 100 pixels from center

    final x = math.cos(angle) * distance;
    final y = math.sin(angle) * distance;

    return [
      Positioned(
        left: x + 150, // Center offset
        top: y + 150,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: 12 + (_pulseController.value * 8),
              height: 12 + (_pulseController.value * 8),
              decoration: BoxDecoration(
                color: _getItemColor(_closestItem!)
                    .withOpacity(0.8 - _pulseController.value * 0.3),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _getItemColor(_closestItem!).withOpacity(0.5),
                    blurRadius: 5 + (_pulseController.value * 10),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ];
  }

  Widget _buildSignalInfo() {
    return Container(
      padding: EdgeInsets.all(20),
      color: Colors.grey[900],
      child: Column(
        children: [
          // Direction Compass
          _buildCompass(),
          SizedBox(height: 16),

          // Status Text
          Text(
            _status,
            style: TextStyle(
              color: _getSignalColor(),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 12),

          // Signal Strength Bar
          LinearProgressIndicator(
            value: _signalStrength,
            backgroundColor: Colors.grey[700],
            valueColor: AlwaysStoppedAnimation<Color>(_getSignalColor()),
          ),

          SizedBox(height: 8),

          Text(
            'Signal: ${(_signalStrength * 100).toInt()}%',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCompass() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.primaryColor),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Compass directions
          Text('N', style: TextStyle(color: Colors.white, fontSize: 12)),
          Positioned(
              top: 5,
              child: Text('N',
                  style: TextStyle(color: Colors.white, fontSize: 10))),
          Positioned(
              bottom: 5,
              child: Text('S',
                  style: TextStyle(color: Colors.white, fontSize: 10))),
          Positioned(
              left: 5,
              child: Text('W',
                  style: TextStyle(color: Colors.white, fontSize: 10))),
          Positioned(
              right: 5,
              child: Text('E',
                  style: TextStyle(color: Colors.white, fontSize: 10))),

          // Direction arrow
          if (_direction.isNotEmpty)
            Transform.rotate(
              angle: _getDirectionAngle(_direction) * math.pi / 180,
              child: Icon(
                Icons.arrow_upward,
                color: _getSignalColor(),
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isScanning ? _stopScanning : _startScanning,
              icon: Icon(_isScanning ? Icons.stop : Icons.play_arrow),
              label: Text(_isScanning ? 'Stop Scanning' : 'Start Scanning'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isScanning ? Colors.red : AppTheme.primaryColor,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _closestItem != null && _closestItem!.isVeryClose
                ? () => _collectItem(_closestItem!)
                : null,
            icon: Icon(Icons.inventory),
            label: Text('Collect'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods...
  Color _getBatteryColor() {
    final battery = widget.selectedDetector.battery;
    if (battery >= 4) return Colors.green;
    if (battery >= 3) return Colors.yellow;
    return Colors.red;
  }

  List<Widget> _buildSignalBars() {
    return List.generate(5, (index) {
      final isActive = _signalStrength > (index / 5.0);
      return Container(
        width: 4,
        height: 12 + (index * 3),
        margin: EdgeInsets.only(right: 2),
        decoration: BoxDecoration(
          color: isActive ? _getSignalColor() : Colors.grey[600],
          borderRadius: BorderRadius.circular(1),
        ),
      );
    });
  }

  Color _getSignalColor() {
    if (_signalStrength > 0.7) return Colors.green;
    if (_signalStrength > 0.4) return Colors.orange;
    return Colors.red;
  }

  Color _getItemColor(DetectableItem item) {
    switch (item.rarity) {
      case 'legendary':
        return Colors.purple;
      case 'epic':
        return Colors.orange;
      case 'rare':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  double _getDirectionAngle(String direction) {
    const angles = {
      'N': 0,
      'NE': 45,
      'E': 90,
      'SE': 135,
      'S': 180,
      'SW': 225,
      'W': 270,
      'NW': 315
    };
    return angles[direction]?.toDouble() ?? 0;
  }

  void _stopScanning() {
    setState(() => _isScanning = false);
    _scanTimer?.cancel();
    _pulseController.stop();
  }

  Future<void> _collectItem(DetectableItem item) async {
    if (!item.isVeryClose) {
      _showMessage('Move closer to collect this item (within 2m)', isError: true);
      return;
    }

    try {
      setState(() => _isLoading = true);

      // ✅ Call the Collection API
      final response = await _zoneService.collectItem(widget.zoneId, item.type, item.id);
      
      // ✅ Item automatically added to DB inventory via backend
      
      // Remove from local lists
      setState(() {
        _allItems.removeWhere((i) => i.id == item.id);
        _detectableItems.removeWhere((i) => i.id == item.id);
        
        // Remove from specific type lists
        if (item.type == 'artifact') {
          _artifacts.removeWhere((i) => i.id == item.id);
        } else if (item.type == 'gear') {
          _gear.removeWhere((i) => i.id == item.id);
        }
        
        if (_closestItem?.id == item.id) {
          _closestItem = null;
        }
        _isLoading = false;
      });

      // ✅ Show success with XP info from backend
      _showCollectionSuccess(item, response);

      if (_isScanning) {
        _updateDetection();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('Failed to collect ${item.name}: $e', isError: true);
    }
  }

  void _showCollectionSuccess(DetectableItem item, Map<String, dynamic> response) {
    final xpGained = response['xp_gained'] ?? 0;
    final levelUp = response['level_up'] ?? false;
    final newLevel = response['current_level'] ?? 0;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ ${item.name} collected!', 
                 style: TextStyle(fontWeight: FontWeight.bold)),
            if (xpGained > 0)
              Text('🌟 +$xpGained XP gained'),
            if (levelUp)
              Text('🎉 Level Up! Now level $newLevel', 
                   style: TextStyle(color: Colors.orange)),
            Text('📦 Added to inventory'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: levelUp ? 6 : 3),
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showDetectorSettings() {
    // TODO: Show detector calibration settings
  }

  @override
  void dispose() {
    _radarController.dispose();
    _pulseController.dispose();
    _locationTimer?.cancel();
    _scanTimer?.cancel();
    super.dispose();
  }
}

// Radar painter for custom drawing
class RadarPainter extends CustomPainter {
  final double sweepAngle;
  final double signalStrength;
  final Detector detectorType;

  RadarPainter({
    required this.sweepAngle,
    required this.signalStrength,
    required this.detectorType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;

    // Draw radar grid circles
    final gridPaint = Paint()
      ..color = Colors.green.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, radius * i / 4, gridPaint);
    }

    // Draw radar cross lines
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      gridPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      gridPaint,
    );

    // Draw radar sweep
    final sweepPaint = Paint()
      ..color = Colors.green.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      sweepAngle - 0.3,
      0.6,
      true,
      sweepPaint,
    );

    // Draw signal strength ring
    if (signalStrength > 0.1) {
      final signalPaint = Paint()
        ..color = _getSignalColor().withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawCircle(center, radius * signalStrength, signalPaint);
    }
  }

  Color _getSignalColor() {
    if (signalStrength > 0.7) return Colors.green;
    if (signalStrength > 0.4) return Colors.orange;
    return Colors.red;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
