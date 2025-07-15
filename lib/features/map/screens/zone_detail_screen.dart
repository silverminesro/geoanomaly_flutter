import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../services/zone_service.dart';
import '../models/zone_model.dart';

class ZoneDetailScreen extends StatefulWidget {
  final String zoneId;

  const ZoneDetailScreen({
    super.key,
    required this.zoneId,
  });

  @override
  State<ZoneDetailScreen> createState() => _ZoneDetailScreenState();
}

class _ZoneDetailScreenState extends State<ZoneDetailScreen> {
  Zone? _zone;
  bool _isLoading = true;
  bool _isEntered = false;
  Map<String, dynamic>? _zoneData;

  final ZoneService _zoneService = ZoneService();

  @override
  void initState() {
    super.initState();
    _loadZoneDetails();
  }

  Future<void> _loadZoneDetails() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final zone = await _zoneService.getZoneDetails(widget.zoneId);
      setState(() {
        _zone = zone;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading zone details: $e');
    }
  }

  Future<void> _enterZone() async {
    if (_zone == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final result = await _zoneService.enterZone(widget.zoneId);
      setState(() {
        _isEntered = true;
        _zoneData = result;
        _isLoading = false;
      });

      _showSuccessSnackBar('Successfully entered ${_zone!.name}!');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error entering zone: $e');
    }
  }

  Future<void> _exitZone() async {
    if (_zone == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final result = await _zoneService.exitZone(widget.zoneId);
      setState(() {
        _isEntered = false;
        _zoneData = result;
        _isLoading = false;
      });

      _showSuccessSnackBar('Exited ${_zone!.name}');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error exiting zone: $e');
    }
  }

  Future<void> _scanZone() async {
    if (_zone == null || !_isEntered) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final result = await _zoneService.scanZone(widget.zoneId);
      setState(() {
        _zoneData = result;
        _isLoading = false;
      });

      final artifactsCount = result['total_artifacts'] ?? 0;
      final gearCount = result['total_gear'] ?? 0;
      _showSuccessSnackBar(
          'Found $artifactsCount artifacts and $gearCount gear items!');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error scanning zone: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _zone?.name ?? 'Zone Details',
          style: GameTextStyles.clockTime.copyWith(
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.map, color: Colors.white),
            onPressed: () => context.go('/map'),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            )
          : _zone == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Zone not found',
                        style: GameTextStyles.clockTime.copyWith(fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => context.go('/map'),
                        child: Text('Back to Map'),
                      ),
                    ],
                  ),
                )
              : _buildZoneContent(),
    );
  }

  Widget _buildZoneContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zone header
          _buildZoneHeader(),
          SizedBox(height: 20),

          // Zone info
          _buildZoneInfo(),
          SizedBox(height: 20),

          // Zone status
          _buildZoneStatus(),
          SizedBox(height: 20),

          // Action buttons
          _buildActionButtons(),
          SizedBox(height: 20),

          // Zone items (if scanned)
          if (_zoneData != null && _isEntered) _buildZoneItems(),
        ],
      ),
    );
  }

  Widget _buildZoneHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _zone!.biomeEmoji,
                style: TextStyle(fontSize: 32),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  _zone!.name,
                  style: GameTextStyles.clockTime.copyWith(
                    fontSize: 24,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              Text(
                _zone!.dangerLevelEmoji,
                style: TextStyle(fontSize: 24),
              ),
            ],
          ),
          SizedBox(height: 8),
          if (_zone!.description.isNotEmpty)
            Text(
              _zone!.description,
              style: GameTextStyles.clockLabel.copyWith(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildZoneInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Zone Information',
            style: GameTextStyles.clockTime.copyWith(
              fontSize: 18,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: 12),
          _buildInfoRow('Biome', _zone!.biome),
          _buildInfoRow('Danger Level', _zone!.dangerLevel),
          _buildInfoRow('Tier Required', _zone!.tierName),
          _buildInfoRow('Radius', '${_zone!.radiusMeters}m'),
          _buildInfoRow('Type', _zone!.zoneType),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GameTextStyles.clockLabel.copyWith(fontSize: 14),
          ),
          Text(
            value,
            style: GameTextStyles.clockTime.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneStatus() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isEntered
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isEntered ? Colors.green : Colors.grey,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isEntered ? Icons.check_circle : Icons.radio_button_unchecked,
            color: _isEntered ? Colors.green : Colors.grey,
            size: 24,
          ),
          SizedBox(width: 12),
          Text(
            _isEntered ? 'You are in this zone' : 'You are not in this zone',
            style: TextStyle(
              color: _isEntered ? Colors.green : Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isEntered ? _exitZone : _enterZone,
            icon: Icon(_isEntered ? Icons.exit_to_app : Icons.login),
            label: Text(_isEntered ? 'Exit Zone' : 'Enter Zone'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isEntered ? Colors.red : AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        if (_isEntered) ...[
          SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _scanZone,
              icon: Icon(Icons.search),
              label: Text('Scan Zone'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.cardColor,
                foregroundColor: AppTheme.primaryColor,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildZoneItems() {
    final artifacts = _zoneData?['artifacts'] as List? ?? [];
    final gear = _zoneData?['gear'] as List? ?? [];

    if (artifacts.isEmpty && gear.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              'No items found in this zone',
              style: GameTextStyles.clockTime.copyWith(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zone Items',
          style: GameTextStyles.clockTime.copyWith(
            fontSize: 18,
            color: AppTheme.primaryColor,
          ),
        ),
        SizedBox(height: 12),
        if (artifacts.isNotEmpty) ...[
          _buildItemSection('Artifacts', artifacts, Icons.diamond),
          SizedBox(height: 16),
        ],
        if (gear.isNotEmpty) ...[
          _buildItemSection('Gear', gear, Icons.construction),
        ],
      ],
    );
  }

  Widget _buildItemSection(String title, List items, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text(
                title,
                style: GameTextStyles.clockTime.copyWith(
                  fontSize: 16,
                  color: AppTheme.primaryColor,
                ),
              ),
              Spacer(),
              Text(
                '${items.length} items',
                style: GameTextStyles.clockLabel.copyWith(fontSize: 12),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...items.map((item) => _buildItemTile(item)),
        ],
      ),
    );
  }

  Widget _buildItemTile(Map<String, dynamic> item) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(
            item['type'] == 'artifact' ? Icons.diamond : Icons.construction,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? 'Unknown Item',
                  style: GameTextStyles.clockTime.copyWith(fontSize: 14),
                ),
                if (item['rarity'] != null)
                  Text(
                    item['rarity'],
                    style: GameTextStyles.clockLabel.copyWith(fontSize: 12),
                  ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement collect item
              _showSuccessSnackBar('Collecting ${item['name']}...');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size(0, 0),
            ),
            child: Text('Collect', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
