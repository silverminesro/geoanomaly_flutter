import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/zone_model.dart';
import '../services/zone_service.dart';
import '../models/detector_model.dart';

class ZoneDetailScreen extends ConsumerStatefulWidget {
  final String zoneId;

  const ZoneDetailScreen({
    super.key,
    required this.zoneId,
  });

  @override
  ConsumerState<ZoneDetailScreen> createState() => _ZoneDetailScreenState();
}

class _ZoneDetailScreenState extends ConsumerState<ZoneDetailScreen> {
  Zone? _zone;
  bool _isLoading = true;
  bool _isInZone = false;
  bool _isEntering = false;
  Detector? _selectedDetector;
  List<Detector> _availableDetectors = [];

  final ZoneService _zoneService = ZoneService();

  @override
  void initState() {
    super.initState();
    _loadZoneDetails();
    _loadPlayerDetectors();
  }

  Future<void> _loadZoneDetails() async {
    try {
      setState(() => _isLoading = true);

      // Load zone details (mock for now, replace with real API)
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      setState(() {
        _zone = Zone(
          id: widget.zoneId,
          name: 'Mysterious Forest Zone',
          description:
              'Ancient forest filled with mysterious artifacts and hidden treasures.',
          location: const Location(latitude: 48.1486, longitude: 17.1077),
          radiusMeters: 250,
          tierRequired: 1,
          zoneType: 'dynamic',
          biome: 'forest',
          dangerLevel: 'medium',
          isActive: true,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorMessage('Failed to load zone details: $e');
    }
  }

  Future<void> _loadPlayerDetectors() async {
    try {
      // ✅ FIX: Load from defaults and filter properly
      setState(() {
        _availableDetectors = Detector.defaultDetectors.where((detector) {
          // Show owned detectors and available ones
          return detector.isOwned || _canAcquireDetector(detector);
        }).toList();
      });
    } catch (e) {
      print('Failed to load detectors: $e');
    }
  }

  bool _canAcquireDetector(Detector detector) {
    // TODO: Check player tier and ownership
    // For now, show all detectors but disable locked ones
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading Zone...'),
          backgroundColor: AppTheme.primaryColor,
        ),
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    if (_zone == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Zone Not Found')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Zone not found', style: GameTextStyles.header),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_zone!.name),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map, color: Colors.white),
            onPressed: () => context.go('/map'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Zone Info Card
            _buildZoneInfoCard(),
            const SizedBox(height: 16),

            // Zone Status Card
            _buildZoneStatusCard(),
            const SizedBox(height: 16),

            // Detector Selection (only if in zone)
            if (_isInZone) ...[
              _buildDetectorSelection(),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _getBiomeEmoji(_zone!.biome ?? 'unknown'),
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _zone!.name,
                        style: GameTextStyles.clockTime.copyWith(
                          fontSize: 24,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        _zone!.description ?? 'No description available',
                        style: GameTextStyles.clockLabel.copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Text(
                  _getDangerEmoji(_zone!.dangerLevel ?? 'unknown'),
                  style: const TextStyle(fontSize: 24),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _buildInfoItem('Tier Required',
                        'T${_zone!.tierRequired}', Icons.star)),
                Expanded(
                    child: _buildInfoItem(
                        'Biome', _zone!.biome ?? 'Unknown', Icons.terrain)),
                Expanded(
                    child: _buildInfoItem('Danger',
                        _zone!.dangerLevel ?? 'Unknown', Icons.warning)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneStatusCard() {
    return Card(
      color: _isInZone
          ? Colors.green.withOpacity(0.1)
          : Colors.grey.withOpacity(0.1),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _isInZone ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                _isInZone ? Icons.location_on : Icons.location_off,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isInZone
                        ? 'You are in this zone'
                        : 'You are outside this zone',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isInZone ? Colors.green : Colors.grey,
                    ),
                  ),
                  Text(
                    _isInZone
                        ? 'Select a detector to start scanning for artifacts'
                        : 'Enter the zone to begin artifact detection',
                    style: TextStyle(
                      fontSize: 14,
                      color: _isInZone ? Colors.green[700] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectorSelection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.search, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Select Detection Equipment',
                  style: GameTextStyles.clockTime.copyWith(
                    fontSize: 18,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._availableDetectors.map(
              (detector) => _buildDetectorOption(detector),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectorOption(Detector detector) {
    final isSelected = _selectedDetector?.id == detector.id;
    final canUse = detector.isOwned;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        color: isSelected
            ? AppTheme.primaryColor.withOpacity(0.1)
            : canUse
                ? null
                : Colors.grey.withOpacity(0.1),
        child: ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: canUse
                  ? detector.rarity.color.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              detector.icon,
              color: canUse ? detector.rarity.color : Colors.grey,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  detector.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: canUse ? null : Colors.grey,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: detector.rarity.color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  detector.rarity.displayName,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detector.description,
                style: TextStyle(
                  fontSize: 12,
                  color: canUse ? Colors.grey[600] : Colors.grey[400],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStatBar('Range', detector.range, canUse),
                  const SizedBox(width: 12),
                  _buildStatBar('Precision', detector.precision, canUse),
                  const SizedBox(width: 12),
                  _buildStatBar('Battery', detector.battery, canUse),
                ],
              ),
              if (detector.specialAbility != null) ...[
                const SizedBox(height: 4),
                Text(
                  '🔮 ${detector.specialAbility}',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: canUse ? AppTheme.primaryColor : Colors.grey,
                  ),
                ),
              ],
            ],
          ),
          trailing: isSelected
              ? Icon(Icons.check_circle, color: AppTheme.primaryColor)
              : canUse
                  ? Icon(Icons.radio_button_unchecked, color: Colors.grey)
                  : Icon(Icons.lock, color: Colors.grey),
          enabled: canUse,
          onTap: canUse ? () => _selectDetector(detector) : null,
        ),
      ),
    );
  }

  Widget _buildStatBar(String label, int value, bool enabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: enabled ? Colors.grey[600] : Colors.grey[400],
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
              5,
              (index) => Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 2),
                    decoration: BoxDecoration(
                      color: index < value
                          ? (enabled ? AppTheme.primaryColor : Colors.grey)
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(1),
                    ),
                  )),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(label, style: GameTextStyles.clockLabel.copyWith(fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: GameTextStyles.clockTime.copyWith(fontSize: 13)),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (_isInZone) {
      return Column(
        children: [
          // Start Scanning Button (only if detector selected)
          if (_selectedDetector != null)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _startScanning,
                icon: const Icon(Icons.radar),
                label: Text('Start Scanning with ${_selectedDetector!.name}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Exit Zone Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _exitZone,
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Exit Zone'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: _isEntering ? null : _enterZone,
          icon: _isEntering
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.login),
          label: Text(_isEntering ? 'Entering Zone...' : 'Enter Zone'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }
  }

  void _selectDetector(Detector detector) {
    setState(() {
      _selectedDetector = detector;
    });
    _showSuccessMessage('Selected ${detector.name}');
  }

  Future<void> _enterZone() async {
    setState(() => _isEntering = true);

    try {
      // TODO: Replace with real API call
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isInZone = true;
        _isEntering = false;
      });

      _showSuccessMessage('Successfully entered ${_zone!.name}!');
    } catch (e) {
      setState(() => _isEntering = false);
      _showErrorMessage('Failed to enter zone: $e');
    }
  }

  Future<void> _exitZone() async {
    try {
      // TODO: Replace with real API call
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _isInZone = false;
        _selectedDetector = null;
      });

      _showSuccessMessage('Exited ${_zone!.name}');
    } catch (e) {
      _showErrorMessage('Failed to exit zone: $e');
    }
  }

  Future<void> _startScanning() async {
    if (_selectedDetector == null) return;

    _showSuccessMessage('Starting scan with ${_selectedDetector!.name}...');

    // ✅ FIX: Navigate to detector screen with proper parameters
    context.pushNamed(
      'detector',
      pathParameters: {'zoneId': widget.zoneId},
      extra: _selectedDetector,
    );
  }

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

  String _getDangerEmoji(String danger) {
    switch (danger.toLowerCase()) {
      case 'low':
        return '🟢';
      case 'medium':
        return '🟡';
      case 'high':
        return '🟠';
      case 'extreme':
        return '🔴';
      default:
        return '⚪';
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
