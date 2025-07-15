import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/zone_model.dart';

class ZoneInfoCard extends StatelessWidget {
  final Zone zone;
  final VoidCallback onEnterZone;
  final VoidCallback onNavigateToZone;

  const ZoneInfoCard({
    super.key,
    required this.zone,
    required this.onEnterZone,
    required this.onNavigateToZone,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Zone header
                  Row(
                    children: [
                      Text(
                        zone.biomeEmoji,
                        style: TextStyle(fontSize: 24),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          zone.name,
                          style: GameTextStyles.clockTime.copyWith(
                            fontSize: 22,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      Text(
                        zone.dangerLevelEmoji,
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Zone description
                  if (zone.description.isNotEmpty)
                    Text(
                      zone.description,
                      style: GameTextStyles.clockLabel.copyWith(
                        fontSize: 14,
                        color: Colors.grey[300],
                      ),
                    ),

                  SizedBox(height: 20),

                  // Zone info grid
                  _buildInfoGrid(),

                  SizedBox(height: 20),

                  // TTL info if expires
                  if (zone.expiresAt != null) _buildTTLInfo(),

                  SizedBox(height: 20),

                  // Action buttons
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoGrid() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child:
                    _buildInfoItem('Tier Required', zone.tierName, Icons.star),
              ),
              Expanded(
                child: _buildInfoItem('Biome', zone.biome, Icons.terrain),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child:
                    _buildInfoItem('Danger', zone.dangerLevel, Icons.warning),
              ),
              Expanded(
                child: _buildInfoItem(
                    'Radius', '${zone.radiusMeters}m', Icons.circle),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 24,
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: GameTextStyles.clockLabel.copyWith(fontSize: 12),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: GameTextStyles.clockTime.copyWith(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildTTLInfo() {
    if (zone.expiresAt == null) return SizedBox.shrink();

    final now = DateTime.now();
    final timeLeft = zone.expiresAt!.difference(now);
    final isExpiring = timeLeft.inHours < 1;

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isExpiring
            ? Colors.red.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isExpiring ? Colors.red : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            color: isExpiring ? Colors.red : Colors.orange,
            size: 16,
          ),
          SizedBox(width: 8),
          Text(
            isExpiring
                ? 'Expires in ${timeLeft.inMinutes}m ${timeLeft.inSeconds % 60}s'
                : 'Expires in ${timeLeft.inHours}h ${timeLeft.inMinutes % 60}m',
            style: TextStyle(
              color: isExpiring ? Colors.red : Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onNavigateToZone,
            icon: Icon(Icons.info_outline),
            label: Text('View Details'),
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
        SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onEnterZone,
            icon: Icon(Icons.login),
            label: Text('Enter Zone'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
