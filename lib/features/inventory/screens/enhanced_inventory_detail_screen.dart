import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/inventory_providers.dart';
import '../models/inventory_item_model.dart';
import '../models/artifact_item_model.dart';
import '../models/gear_item_model.dart';
import '../widgets/rarity_badge.dart';
import '../../map/models/location_model.dart';

class EnhancedInventoryDetailScreen extends ConsumerStatefulWidget {
  final InventoryItem item;

  const EnhancedInventoryDetailScreen({
    super.key,
    required this.item,
  });

  @override
  ConsumerState<EnhancedInventoryDetailScreen> createState() =>
      _EnhancedInventoryDetailScreenState();
}

class _EnhancedInventoryDetailScreenState
    extends ConsumerState<EnhancedInventoryDetailScreen> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.item.isFavorite;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildItemHeader(),
                _buildPropertiesSection(),
                _buildDiscoverySection(),
                _buildLocationSection(),
                // ✅ FIXED: Better detailed item loading with error handling
                _buildDetailedItemSection(),
                _buildActionsSection(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Improved detailed item section with error handling
  Widget _buildDetailedItemSection() {
    return Consumer(
      builder: (context, ref, child) {
        final detailsAsyncValue = ref.watch(itemDetailsProvider(widget.item));

        return detailsAsyncValue.when(
          data: (detailedItem) {
            if (detailedItem == null) return const SizedBox.shrink();

            return Column(
              children: [
                if (detailedItem is ArtifactItem)
                  _buildArtifactSpecificSection(detailedItem),
                if (detailedItem is GearItem)
                  _buildGearSpecificSection(detailedItem),
              ],
            );
          },
          loading: () => Container(
            padding: const EdgeInsets.all(20),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stackTrace) {
            print('❌ Error loading item details: $error');
            return Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Column(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(height: 8),
                  const Text(
                    'Unable to load detailed information',
                    style: TextStyle(
                        color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Using basic item data only',
                    style: GameTextStyles.clockLabel.copyWith(fontSize: 12),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? Colors.red : Colors.white,
          ),
          onPressed: _toggleFavorite,
        ),
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () => _shareItem(),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: _getItemGradient(),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(60),
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Icon(
                      _getItemIcon(),
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      widget.item.isArtifact ? 'ARTIFACT' : 'GEAR',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 100,
              right: 20,
              child: RarityBadge(
                rarity: widget.item.rarity,
                size: RarityBadgeSize.large,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.item.name,
                  style: GameTextStyles.header.copyWith(
                    color: _getItemColor(),
                    fontSize: 28,
                  ),
                ),
              ),
              if (widget.item.quantity > 1)
                Text(
                  '${widget.item.quantity}x',
                  style: GameTextStyles.clockTime.copyWith(fontSize: 20),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _getItemIcon(),
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _getItemTypeDisplay(),
                style: GameTextStyles.clockLabel.copyWith(fontSize: 14),
              ),
              const Spacer(),
              Text(
                widget.item.timeSinceAcquired,
                style: GameTextStyles.clockLabel,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Acquired ${widget.item.acquiredDateTimeFormatted}',
            style: GameTextStyles.cardSubtitle.copyWith(
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FIXED: Better properties section with null safety
  Widget _buildPropertiesSection() {
    if (widget.item.properties.isEmpty) return const SizedBox.shrink();

    // ✅ FIXED: Filter out null and system properties
    final displayProperties = widget.item.properties.entries
        .where((entry) => entry.value != null && !_isSystemProperty(entry.key))
        .toList();

    if (displayProperties.isEmpty) return const SizedBox.shrink();

    return _buildSection(
      title: 'Properties',
      icon: Icons.info_outline,
      child: Column(
        children: displayProperties.map((entry) {
          return _buildPropertyRow(entry.key, entry.value);
        }).toList(),
      ),
    );
  }

  // ✅ NEW: Helper to identify system properties
  bool _isSystemProperty(String key) {
    const systemKeys = {
      'manual_parse',
      'parsing_failed',
      'collected_at',
      'collected_from',
      'zone_name',
      'zone_biome'
    };
    return systemKeys.contains(key.toLowerCase());
  }

  Widget _buildDiscoverySection() {
    return _buildSection(
      title: 'Discovery Information',
      icon: Icons.explore,
      child: Column(
        children: [
          _buildInfoRow('Acquired', widget.item.timeSinceAcquired),
          _buildInfoRow('Date', widget.item.acquiredDateFormatted),
          _buildInfoRow('Biome',
              '${widget.item.biomeEmoji} ${widget.item.biomeDisplayName}'),
          _buildInfoRow('Item Type', widget.item.typeDisplayName),
          _buildInfoRow('Rarity', widget.item.displayRarity),
          // ✅ FIXED: Show zone name if available
          if (widget.item.hasProperty('zone_name'))
            _buildInfoRow('Found in',
                widget.item.getProperty<String>('zone_name') ?? 'Unknown Zone'),
          if (widget.item.hasProperty('danger_level'))
            _buildInfoRow('Danger Level', widget.item.dangerLevel),
        ],
      ),
    );
  }

  // ✅ FIXED: Better location section with null safety
  Widget _buildLocationSection() {
    if (!widget.item.hasDiscoveryLocation) {
      return const SizedBox.shrink();
    }

    final location = widget.item.discoveryLocation!;

    return _buildSection(
      title: 'Discovery Location',
      icon: Icons.map,
      child: Column(
        children: [
          _buildInfoRow(
            'Coordinates',
            '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
          ),
          const SizedBox(height: 16),
          // ✅ FIXED: Safe map widget with error handling
          _buildLocationMap(location),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToDiscoveryLocation(location),
              icon: const Icon(Icons.navigation),
              label: const Text('Go Back to Discovery Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Safe location map widget
  Widget _buildLocationMap(LocationModel location) {
    try {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(location.latitude, location.longitude),
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.geoanomaly.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(location.latitude, location.longitude),
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.location_on,
                      color: _getItemColor(),
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('❌ Error building map: $e');
      return Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
          color: Colors.grey[800],
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Map unavailable',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildArtifactSpecificSection(ArtifactItem artifact) {
    return _buildSection(
      title: 'Artifact Details',
      icon: Icons.diamond,
      child: Column(
        children: [
          _buildInfoRow(
              'Type', '${artifact.typeIcon} ${artifact.typeDisplayName}'),
          _buildInfoRow('Rarity',
              '${artifact.rarityEmoji} ${artifact.rarityDisplayName}'),
          if (artifact.power != null)
            _buildInfoRow('Power', artifact.power.toString()),
          if (artifact.value != null)
            _buildInfoRow(
                'Value', '${artifact.value!.toStringAsFixed(0)} coins'),
          if (artifact.description != null && artifact.description!.isNotEmpty)
            _buildInfoRow('Description', artifact.description!),
        ],
      ),
    );
  }

  Widget _buildGearSpecificSection(GearItem gear) {
    return Column(
      children: [
        _buildSection(
          title: 'Gear Details',
          icon: Icons.shield,
          child: Column(
            children: [
              _buildInfoRow('Type', '${gear.typeIcon} ${gear.typeDisplayName}'),
              _buildInfoRow('Level', '${gear.levelStars} Level ${gear.level}'),
              _buildInfoRow('Quality', gear.levelDisplayName),
              if (gear.weight != null)
                _buildInfoRow(
                    'Weight', '${gear.weight!.toStringAsFixed(1)} kg'),
              if (gear.value != null)
                _buildInfoRow(
                    'Value', '${gear.value!.toStringAsFixed(0)} coins'),
              if (gear.description != null && gear.description!.isNotEmpty)
                _buildInfoRow('Description', gear.description!),
            ],
          ),
        ),
        if (gear.attack > 0 || gear.defense > 0)
          _buildSection(
            title: 'Combat Stats',
            icon: Icons.bar_chart,
            child: Column(
              children: [
                if (gear.attack > 0) _buildStatBar('Attack', gear.attack, 100),
                if (gear.defense > 0)
                  _buildStatBar('Defense', gear.defense, 100),
              ],
            ),
          ),
        _buildSection(
          title: 'Condition',
          icon: Icons.health_and_safety,
          child: Column(
            children: [
              _buildInfoRow('Durability', gear.durabilityDisplay),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: gear.durabilityPercentage,
                backgroundColor: Colors.grey[700],
                valueColor: AlwaysStoppedAnimation<Color>(gear.durabilityColor),
              ),
              const SizedBox(height: 8),
              if (gear.needsRepair)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'This item needs repair',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _canUseItem() ? _useItem : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Use Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showRemoveConfirmation,
                  icon: const Icon(Icons.delete),
                  label: const Text('Remove'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _shareItem,
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods (same as before, but with better null safety)
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Card(
        color: AppTheme.cardColor,
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: GameTextStyles.clockTime.copyWith(
                      fontSize: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GameTextStyles.clockLabel,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GameTextStyles.cardTitle.copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FIXED: Better property row with null safety
  Widget _buildPropertyRow(String key, dynamic value) {
    if (value == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              _formatPropertyKey(key),
              style: GameTextStyles.clockLabel.copyWith(fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              _formatPropertyValue(value),
              style: GameTextStyles.cardTitle.copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Property formatting helpers
  String _formatPropertyKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty
            ? ''
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  String _formatPropertyValue(dynamic value) {
    if (value is bool) {
      return value ? 'Yes' : 'No';
    } else if (value is num) {
      return value.toString();
    } else {
      return value.toString();
    }
  }

  Widget _buildStatBar(String label, int value, int maxValue) {
    final percentage = (value / maxValue).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GameTextStyles.clockLabel),
              Text('$value / $maxValue',
                  style: GameTextStyles.clockTime.copyWith(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[700],
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  // Utility methods (same as before but with better error handling)
  LinearGradient _getItemGradient() {
    Color primaryColor;

    switch (widget.item.rarity.toLowerCase()) {
      case 'legendary':
        primaryColor = Colors.orange;
        break;
      case 'epic':
        primaryColor = Colors.purple;
        break;
      case 'rare':
        primaryColor = Colors.blue;
        break;
      case 'common':
        primaryColor = Colors.green;
        break;
      default:
        primaryColor = AppTheme.primaryColor;
    }

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        primaryColor.withOpacity(0.8),
        primaryColor.withOpacity(0.4),
        AppTheme.backgroundColor,
      ],
    );
  }

  // ✅ FIXED: Better icon selection with null safety
  IconData _getItemIcon() {
    if (widget.item.isArtifact) {
      final type =
          widget.item.getProperty<String>('type')?.toLowerCase() ?? 'unknown';
      switch (type) {
        case 'crystal':
          return Icons.diamond;
        case 'orb':
          return Icons.circle;
        case 'scroll':
          return Icons.description;
        case 'tablet':
          return Icons.tablet;
        case 'rune':
          return Icons.auto_awesome;
        default:
          return Icons.diamond;
      }
    } else {
      final type =
          widget.item.getProperty<String>('type')?.toLowerCase() ?? 'unknown';
      switch (type) {
        case 'helmet':
          return Icons.sports_motorsports;
        case 'shield':
          return Icons.shield;
        case 'armor':
          return Icons.security;
        case 'weapon':
          return Icons.gavel;
        case 'boots':
          return Icons.directions_walk;
        default:
          return Icons.shield;
      }
    }
  }

  Color _getItemColor() {
    switch (widget.item.rarity.toLowerCase()) {
      case 'legendary':
        return Colors.orange;
      case 'epic':
        return Colors.purple;
      case 'rare':
        return Colors.blue;
      case 'common':
        return Colors.green;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _getItemTypeDisplay() {
    return '${widget.item.typeDisplayName} • ${widget.item.displayRarity}';
  }

  bool _canUseItem() {
    return true; // Basic implementation
  }

  // Action methods (same as before)
  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    ref
        .read(inventoryProvider.notifier)
        .toggleFavorite(widget.item, _isFavorite);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(_isFavorite ? 'Added to favorites' : 'Removed from favorites'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _useItem() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Item used successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showRemoveConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text(
          'Remove Item',
          style: GameTextStyles.clockTime.copyWith(fontSize: 18),
        ),
        content: Text(
          'Are you sure you want to remove "${widget.item.displayName}" from your inventory?',
          style: GameTextStyles.cardSubtitle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeItem();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _removeItem() async {
    try {
      await ref.read(inventoryProvider.notifier).removeItem(widget.item);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareItem() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing feature coming soon!')),
    );
  }

  void _navigateToDiscoveryLocation(LocationModel location) {
    context.go('/map', extra: {
      'center_location': location,
      'show_discovery_marker': true,
      'discovery_item_name': widget.item.displayName,
    });
  }
}
