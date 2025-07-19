import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../../core/theme/app_theme.dart';
import '../models/detector_model.dart';
import '../models/artifact_model.dart';
import '../services/zone_service.dart';
import '../services/location_service.dart';
import '../models/location_model.dart';

class DetectorScreen extends ConsumerStatefulWidget {
  final String zoneId;
  final Detector detector;

  const DetectorScreen({
    super.key,
    required this.zoneId,
    required this.detector,
  });

  @override
  ConsumerState<DetectorScreen> createState() => _DetectorScreenState();
}

class _DetectorScreenState extends ConsumerState<DetectorScreen>
    with TickerProviderStateMixin {
  // Core state
  bool _isScanning = false;
  bool _isLoading = true;
  bool _isCollecting = false; // ✅ NEW: Tracking collection state

  List<DetectableItem> _artifacts = [];
  List<DetectableItem> _gear = [];
  List<DetectableItem> _allItems = [];
  List<DetectableItem> _detectableItems = [];
  LocationModel? _currentLocation;
  DetectableItem? _closestItem;

  late ZoneService _zoneService;
  Timer? _locationTimer;
  Timer? _detectionTimer;

  // Animation controllers
  late AnimationController _scanAnimationController;
  late AnimationController _signalAnimationController;
  late Animation<double> _scanRotation;
  late Animation<double> _signalPulse;

  // Detection parameters
  double _signalStrength = 0.0;
  String _direction = 'N/A';
  double _distance = 0.0;

  // Status string
  String _status = 'Initializing detector...';

  @override
  void initState() {
    super.initState();
    _zoneService = ZoneService();
    _initializeAnimations();
    _loadArtifacts();
    _startLocationTracking();
  }

  void _initializeAnimations() {
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _signalAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scanRotation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _scanAnimationController,
      curve: Curves.linear,
    ));

    _signalPulse = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _signalAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _loadArtifacts() async {
    try {
      setState(() => _isLoading = true);

      final response = await _zoneService.getZoneArtifacts(widget.zoneId);

      setState(() {
        // ✅ IMPROVED: Better handling of API response
        _artifacts = [];
        _gear = [];

        if (response['artifacts'] != null) {
          _artifacts = (response['artifacts'] as List)
              .map<DetectableItem>((json) => DetectableItem.fromJson(json))
              .where((item) => item.canBeDetected) // Only detectable items
              .toList();
        }

        if (response['gear'] != null) {
          _gear = (response['gear'] as List)
              .map<DetectableItem>((json) => DetectableItem.fromJson(json))
              .where((item) => item.canBeDetected) // Only detectable items
              .toList();
        }

        // Update combined lists
        _allItems = [..._artifacts, ..._gear];
        _detectableItems = [..._allItems];
        _isLoading = false;
        _closestItem = null;
        _status = 'Detector ready. ${_allItems.length} items detected.';
      });

      if (_allItems.isEmpty) {
        _showMessage('No artifacts detected in this area', isError: false);
      } else {
        _showMessage('${_allItems.length} items detected in zone',
            isError: false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('Failed to load zone data: $e', isError: true);
    }
  }

  void _startLocationTracking() {
    _locationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateLocation();
    });
  }

  Future<void> _updateLocation() async {
    try {
      final location = await LocationService.getCurrentLocation();
      setState(() {
        _currentLocation = location;
      });

      // ✅ IMPROVED: Always update detection when location changes
      _updateDetection();
    } catch (e) {
      print('❌ Location update failed: $e');
    }
  }

  void _updateDetection() {
    if (_currentLocation == null) return;
    if (_detectableItems.isEmpty) return;

    // ✅ IMPROVED: Find closest item and update all items with distance info
    DetectableItem? closest;
    double minDistance = double.infinity;
    final List<DetectableItem> updatedItems = [];

    for (final item in _detectableItems) {
      final distance = _zoneService.calculateDistance(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        item.latitude,
        item.longitude,
      );

      final bearing = _zoneService.calculateBearing(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        item.latitude,
        item.longitude,
      );

      final compassDirection = _zoneService.bearingToSimpleCompass(bearing);

      // ✅ IMPROVED: Update item with calculated values
      final updatedItem = item.copyWith(
        distanceFromPlayer: distance,
        bearingFromPlayer: bearing,
        compassDirection: compassDirection,
      );

      updatedItems.add(updatedItem);

      if (distance < minDistance) {
        minDistance = distance;
        closest = updatedItem;
      }
    }

    setState(() {
      _detectableItems = updatedItems;
      _closestItem = closest;
      _distance = minDistance.isFinite ? minDistance : 0.0;
      _direction = _closestItem?.compassDirection ?? 'N/A';
      _signalStrength = _closestItem != null
          ? _zoneService.calculateSignalStrength(
              _distance,
              maxRangeMeters: widget.detector.maxRangeMeters,
              precisionFactor: widget.detector.precisionFactor,
              itemRarity: _closestItem!.rarity,
            )
          : 0.0;
    });

    // Update signal animation based on strength
    if (_signalStrength > 0 && _isScanning) {
      if (!_signalAnimationController.isAnimating) {
        _signalAnimationController.repeat(reverse: true);
      }
    } else {
      _signalAnimationController.stop();
    }
  }

  void _toggleScanning() {
    setState(() {
      _isScanning = !_isScanning;
    });

    if (_isScanning) {
      _scanAnimationController.repeat();
      _detectionTimer =
          Timer.periodic(const Duration(milliseconds: 500), (timer) {
        _updateDetection();
      });
      _showMessage('🔍 Scanning started with ${widget.detector.name}',
          isError: false);
    } else {
      _scanAnimationController.stop();
      _signalAnimationController.stop();
      _detectionTimer?.cancel();
      setState(() {
        _signalStrength = 0.0;
        _direction = 'N/A';
        _distance = 0.0;
        _closestItem = null;
      });
      _showMessage('⏹️ Scanning stopped', isError: false);
    }
  }

  // ✅ IMPROVED: Enhanced collection logic
  Future<void> _collectItem(DetectableItem item) async {
    if (_isCollecting) {
      _showMessage('Collection already in progress...', isError: true);
      return;
    }

    // ✅ Check distance requirement
    final currentDistance = _currentLocation != null
        ? _zoneService.calculateDistance(
            _currentLocation!.latitude,
            _currentLocation!.longitude,
            item.latitude,
            item.longitude,
          )
        : double.infinity;

    if (currentDistance > 2.0) {
      _showMessage(
          'Move closer to collect this item (within 2m)\nCurrent distance: ${_zoneService.formatDistance(currentDistance)}',
          isError: true);
      return;
    }

    // ✅ Check if item is still available
    if (!_detectableItems.any((i) => i.id == item.id)) {
      _showMessage('This item is no longer available', isError: true);
      return;
    }

    try {
      setState(() => _isCollecting = true);

      // ✅ Show collection progress
      _showMessage('🎯 Collecting ${item.name}...', isError: false);

      // ✅ Call the Collection API
      final response =
          await _zoneService.collectItem(widget.zoneId, item.type, item.id);

      // ✅ Remove from local lists
      setState(() {
        _allItems.removeWhere((i) => i.id == item.id);
        _detectableItems.removeWhere((i) => i.id == item.id);

        if (item.type == 'artifact') {
          _artifacts.removeWhere((i) => i.id == item.id);
        } else if (item.type == 'gear') {
          _gear.removeWhere((i) => i.id == item.id);
        }

        if (_closestItem?.id == item.id) {
          _closestItem = null;
          _signalStrength = 0.0;
          _distance = 0.0;
          _direction = 'N/A';
        }

        _isCollecting = false;
      });

      // ✅ Show success message with details
      _showCollectionSuccess(item, response);

      // ✅ Update detection after successful collection
      if (_isScanning) {
        _updateDetection();
      }

      // ✅ Update status
      setState(() {
        _status = 'Detector ready. ${_allItems.length} items remaining.';
      });
    } catch (e) {
      setState(() => _isCollecting = false);

      String errorMessage = 'Failed to collect ${item.name}';
      if (e.toString().contains('Not in zone')) {
        errorMessage = 'You must be in the zone to collect items';
      } else if (e.toString().contains('Too far')) {
        errorMessage = 'Move closer to the item';
      } else if (e.toString().contains('Already collected')) {
        errorMessage = 'This item has already been collected';
      } else {
        errorMessage =
            'Collection failed: ${e.toString().replaceAll('Exception: ', '')}';
      }

      _showMessage(errorMessage, isError: true);
    }
  }

  // ✅ IMPROVED: Enhanced success message with animations
  void _showCollectionSuccess(
      DetectableItem item, Map<String, dynamic> response) {
    final xpGained = response['xp_gained'] ?? 0;
    final levelUp = response['level_up'] ?? false;
    final newLevel = response['current_level'] ?? 0;
    final coinsGained = response['coins_gained'] ?? 0;

    // ✅ Show detailed success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_getItemIcon(item.type), color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '✅ ${item.name} collected!',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              if (item.value > 0) ...[
                const SizedBox(height: 4),
                Text('💰 Value: ${item.value} coins'),
              ],
              if (xpGained > 0) ...[
                const SizedBox(height: 4),
                Text('🌟 +$xpGained XP gained'),
              ],
              if (coinsGained > 0) ...[
                const SizedBox(height: 4),
                Text('💰 +$coinsGained coins earned'),
              ],
              if (levelUp) ...[
                const SizedBox(height: 4),
                Text(
                  '🎉 LEVEL UP! Now level $newLevel',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              const Text('📦 Added to inventory'),
            ],
          ),
        ),
        backgroundColor: Colors.green[700],
        duration: Duration(seconds: levelUp ? 8 : 5),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Navigate to inventory
            context.push('/inventory');
          },
        ),
      ),
    );

    // ✅ Play collection sound/haptic feedback
    // HapticFeedback.heavyImpact(); // Uncomment if you want haptic feedback
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.blue[700],
        duration: Duration(seconds: isError ? 4 : 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _allItems.isEmpty) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryColor),
              const SizedBox(height: 16),
              Text(
                'Loading detector data...',
                style: GameTextStyles.cardTitle,
              ),
              const SizedBox(height: 8),
              Text(
                'Scanning zone for artifacts...',
                style: GameTextStyles.cardSubtitle,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Detector info header
          _buildDetectorHeader(),

          // Detection display
          Expanded(
            child: _buildDetectionDisplay(),
          ),

          // Controls
          _buildControls(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text('🎯 ${widget.detector.name}'),
      backgroundColor: AppTheme.primaryColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      actions: [
        // ✅ NEW: Show collection progress
        if (_isCollecting)
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.white),
          onPressed: () => _showDetectorInfo(),
        ),
      ],
    );
  }

  Widget _buildDetectorHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: widget.detector.rarity.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.detector.icon,
              color: widget.detector.rarity.color,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.detector.name,
                  style: GameTextStyles.cardTitle.copyWith(fontSize: 16),
                ),
                Text(
                  '${widget.detector.rangeDisplay} • ${widget.detector.precisionDisplay}',
                  style: GameTextStyles.cardSubtitle.copyWith(fontSize: 12),
                ),
                // ✅ NEW: Show status
                Text(
                  _status,
                  style: GameTextStyles.cardSubtitle.copyWith(
                    fontSize: 10,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: widget.detector.rarity.color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              widget.detector.rarity.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionDisplay() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Radar display
          _buildRadarDisplay(),

          const SizedBox(height: 30),

          // Signal strength
          _buildSignalStrengthDisplay(),

          const SizedBox(height: 20),

          // Target info
          _buildTargetInfo(),

          const SizedBox(height: 20),

          // Items list
          if (_detectableItems.isNotEmpty) _buildItemsList(),
        ],
      ),
    );
  }

  Widget _buildRadarDisplay() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border:
            Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 2),
        color: Colors.black.withOpacity(0.1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radar grid
          ...List.generate(
              3,
              (index) => Container(
                    width: (index + 1) * 60.0,
                    height: (index + 1) * 60.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  )),

          // Scanning sweep (only when scanning)
          if (_isScanning)
            AnimatedBuilder(
              animation: _scanRotation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _scanRotation.value,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          Colors.transparent,
                          AppTheme.primaryColor.withOpacity(0.3),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.1, 0.2],
                      ),
                    ),
                  ),
                );
              },
            ),

          // Center point (player)
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),

          // ✅ IMPROVED: Better radar display of items
          ..._detectableItems.take(10).map((item) {
            final distance = item.distanceFromPlayer ?? 0.0;
            final maxRadius = widget.detector.maxRangeMeters;
            final normalizedDistance = (distance / maxRadius).clamp(0.0, 1.0);
            final radiusFromCenter = normalizedDistance * 90;

            final bearing = item.bearingFromPlayer ?? 0.0;
            final radians = (bearing - 90) * math.pi / 180;

            final x = radiusFromCenter * math.cos(radians);
            final y = radiusFromCenter * math.sin(radians);

            final isClosest = item.id == _closestItem?.id;
            final isVeryClose = distance <= 2.0;

            return Positioned(
              left: 100 + x - 4,
              top: 100 + y - 4,
              child: AnimatedBuilder(
                animation: _signalPulse,
                builder: (context, child) {
                  final pulseScale = isClosest ? _signalPulse.value : 1.0;

                  return Transform.scale(
                    scale: pulseScale,
                    child: Container(
                      width: isVeryClose ? 12 : 8,
                      height: isVeryClose ? 12 : 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isVeryClose
                            ? Colors.green
                            : _getRarityColor(item.rarity),
                        border: Border.all(
                          color: Colors.white,
                          width: isClosest ? 2 : 1,
                        ),
                        boxShadow: isVeryClose
                            ? [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: isVeryClose
                          ? const Icon(
                              Icons.star,
                              size: 8,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  );
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSignalStrengthDisplay() {
    return Column(
      children: [
        Text(
          'Signal Strength',
          style: GameTextStyles.cardSubtitle,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(10, (index) {
            final isActive = index < (_signalStrength * 10).round();
            return Container(
              width: 20,
              height: 8 + (index * 2.0),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? _getSignalColor(_signalStrength)
                    : Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          _getSignalStrengthText(),
          style: GameTextStyles.cardTitle.copyWith(
            color: _getSignalColor(_signalStrength),
          ),
        ),
      ],
    );
  }

  Widget _buildTargetInfo() {
    if (_closestItem == null) {
      return Column(
        children: [
          Text(
            'No targets detected',
            style: GameTextStyles.cardTitle.copyWith(color: Colors.grey),
          ),
          Text(
            _isScanning
                ? 'Scanning...'
                : _allItems.isEmpty
                    ? 'No items found in this zone'
                    : 'Start scanning to detect artifacts',
            style: GameTextStyles.cardSubtitle,
          ),
        ],
      );
    }

    final item = _closestItem!;
    final isCollectable = item.isVeryClose && !_isCollecting;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCollectable
              ? Colors.green
              : AppTheme.primaryColor.withOpacity(0.3),
          width: isCollectable ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Target Detected',
                style: GameTextStyles.cardSubtitle,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getRarityColor(item.rarity),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.rarityDisplayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.name,
            style: GameTextStyles.cardTitle.copyWith(
              color: isCollectable ? Colors.green : AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),

          // ✅ IMPROVED: Enhanced info display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Icon(Icons.near_me, color: AppTheme.primaryColor),
                  const SizedBox(height: 4),
                  Text('Distance', style: GameTextStyles.clockLabel),
                  Text(
                    _zoneService.formatDistance(_distance),
                    style: GameTextStyles.clockTime.copyWith(
                      fontSize: 14,
                      color: _distance <= 2.0 ? Colors.green : null,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Icon(Icons.navigation, color: AppTheme.primaryColor),
                  const SizedBox(height: 4),
                  Text('Direction', style: GameTextStyles.clockLabel),
                  Text(
                    _direction,
                    style: GameTextStyles.clockTime.copyWith(fontSize: 14),
                  ),
                ],
              ),
              Column(
                children: [
                  Icon(Icons.category, color: AppTheme.primaryColor),
                  const SizedBox(height: 4),
                  Text('Type', style: GameTextStyles.clockLabel),
                  Text(
                    item.materialDisplayName,
                    style: GameTextStyles.clockTime.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ✅ IMPROVED: Enhanced collect button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isCollectable ? () => _collectItem(item) : null,
              icon: _isCollecting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(isCollectable ? Icons.download : Icons.lock),
              label: Text(_isCollecting
                  ? 'Collecting...'
                  : isCollectable
                      ? 'Collect Item'
                      : 'Get Closer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCollectable ? Colors.green : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // ✅ IMPROVED: Better distance feedback
          if (!item.isVeryClose) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item.isClose
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.isClose ? Icons.directions_walk : Icons.directions,
                    color: item.isClose ? Colors.orange : Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.isClose
                        ? 'Move closer to collect (within 2m)'
                        : 'Follow the direction indicator',
                    style: GameTextStyles.cardSubtitle.copyWith(
                      color: item.isClose ? Colors.orange : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    // ✅ IMPROVED: Sort items by distance
    final sortedItems = List<DetectableItem>.from(_detectableItems);
    sortedItems.sort((a, b) {
      final distanceA = a.distanceFromPlayer ?? double.infinity;
      final distanceB = b.distanceFromPlayer ?? double.infinity;
      return distanceA.compareTo(distanceB);
    });

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detected Items (${_detectableItems.length})',
            style: GameTextStyles.cardTitle,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: sortedItems.length,
              itemBuilder: (context, index) {
                final item = sortedItems[index];
                final isClosest = item.id == _closestItem?.id;
                final isCollectable = item.isVeryClose;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isClosest
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: isClosest
                        ? Border.all(color: AppTheme.primaryColor, width: 1)
                        : isCollectable
                            ? Border.all(color: Colors.green, width: 1)
                            : null,
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getRarityColor(item.rarity).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        _getItemIcon(item.type),
                        color: _getRarityColor(item.rarity),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item.name,
                      style: GameTextStyles.cardTitle.copyWith(fontSize: 14),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.distanceDisplay} • ${item.compassDirection ?? 'N/A'}',
                          style: GameTextStyles.cardSubtitle
                              .copyWith(fontSize: 12),
                        ),
                        if (item.value > 0)
                          Text(
                            '💰 ${item.value} coins',
                            style: GameTextStyles.cardSubtitle.copyWith(
                              fontSize: 11,
                              color: Colors.amber,
                            ),
                          ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getRarityColor(item.rarity),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            item.rarityDisplayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (isClosest)
                          const Icon(Icons.my_location,
                              color: AppTheme.primaryColor, size: 16)
                        else if (isCollectable)
                          const Icon(Icons.star, color: Colors.green, size: 16),
                      ],
                    ),
                    onTap: isCollectable ? () => _collectItem(item) : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isCollecting ? null : _toggleScanning,
              icon: Icon(_isScanning ? Icons.stop : Icons.play_arrow),
              label: Text(_isScanning ? 'Stop Scanning' : 'Start Scanning'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isScanning ? Colors.red : AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _isCollecting ? null : () => context.pop(),
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
        return Colors.grey;
      case 'uncommon':
        return Colors.green;
      case 'rare':
        return Colors.blue;
      case 'epic':
        return Colors.purple;
      case 'legendary':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getItemIcon(String type) {
    switch (type.toLowerCase()) {
      case 'ancient_coin':
      case 'coin':
        return Icons.monetization_on;
      case 'sword':
      case 'weapon':
        return Icons.hardware;
      case 'crystal':
        return Icons.diamond;
      case 'scroll':
      case 'document':
        return Icons.description;
      case 'gear':
      case 'equipment':
        return Icons.settings;
      case 'artifact':
        return Icons.star;
      case 'relic':
        return Icons.auto_awesome;
      default:
        return Icons.category;
    }
  }

  Color _getSignalColor(double strength) {
    if (strength >= 0.8) return Colors.green;
    if (strength >= 0.6) return Colors.lightGreen;
    if (strength >= 0.4) return Colors.yellow;
    if (strength >= 0.2) return Colors.orange;
    return Colors.red;
  }

  String _getSignalStrengthText() {
    if (_signalStrength >= 0.8) return 'Very Strong';
    if (_signalStrength >= 0.6) return 'Strong';
    if (_signalStrength >= 0.4) return 'Medium';
    if (_signalStrength >= 0.2) return 'Weak';
    if (_signalStrength > 0) return 'Very Weak';
    return 'No Signal';
  }

  void _showDetectorInfo() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.detector.name, style: GameTextStyles.header),
            const SizedBox(height: 16),
            Text(
              widget.detector.description,
              style: GameTextStyles.cardSubtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('Range', style: GameTextStyles.clockLabel),
                    Text(widget.detector.rangeDisplay,
                        style: GameTextStyles.clockTime),
                  ],
                ),
                Column(
                  children: [
                    Text('Precision', style: GameTextStyles.clockLabel),
                    Text(widget.detector.precisionDisplay,
                        style: GameTextStyles.clockTime),
                  ],
                ),
                Column(
                  children: [
                    Text('Battery', style: GameTextStyles.clockLabel),
                    Text(widget.detector.batteryDisplay,
                        style: GameTextStyles.clockTime),
                  ],
                ),
              ],
            ),
            if (widget.detector.specialAbility != null) ...[
              const SizedBox(height: 16),
              Text('Special Ability:', style: GameTextStyles.cardTitle),
              const SizedBox(height: 4),
              Text(
                widget.detector.specialAbility!,
                style: GameTextStyles.cardSubtitle
                    .copyWith(color: AppTheme.primaryColor),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'Collection Tips:',
              style: GameTextStyles.cardTitle,
            ),
            const SizedBox(height: 8),
            const Text(
              '• Get within 2 meters of an item to collect it\n'
              '• Green items on radar are ready to collect\n'
              '• Higher rarity items give more XP and value\n'
              '• Use precision to find items more accurately',
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    _signalAnimationController.dispose();
    _locationTimer?.cancel();
    _detectionTimer?.cancel();
    super.dispose();
  }
}
