import 'package:flutter/material.dart';
import '../services/route_calculation_service.dart';

class RoutePreferenceSelector extends StatefulWidget {
  final RoutePreference selectedPreference;
  final Function(RoutePreference) onPreferenceChanged;
  final List<RouteResult>? availableRoutes;
  final bool isLoading;

  const RoutePreferenceSelector({
    super.key,
    required this.selectedPreference,
    required this.onPreferenceChanged,
    this.availableRoutes,
    this.isLoading = false,
  });

  @override
  State<RoutePreferenceSelector> createState() => _RoutePreferenceSelectorState();
}

class _RoutePreferenceSelectorState extends State<RoutePreferenceSelector> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.route, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Route Options',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (widget.isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.availableRoutes != null && widget.availableRoutes!.isNotEmpty)
            ...widget.availableRoutes!.map((route) => _buildRouteOption(route))
          else
            _buildPreferenceButtons(),
        ],
      ),
    );
  }

  Widget _buildRouteOption(RouteResult route) {
    final isSelected = route.preference == widget.selectedPreference;
    final color = isSelected ? Colors.blue : Colors.grey[600];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => widget.onPreferenceChanged(route.preference),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                _getIconForPreference(route.preference),
                color: color,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getPreferenceTitle(route.preference),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.straighten, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${route.distanceKm.toStringAsFixed(1)} km',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${route.duration.inMinutes} min',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Colors.blue,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferenceButtons() {
    return Row(
      children: RoutePreference.values.map((preference) {
        final isSelected = preference == widget.selectedPreference;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildPreferenceButton(preference, isSelected),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPreferenceButton(RoutePreference preference, bool isSelected) {
    return InkWell(
      onTap: () => widget.onPreferenceChanged(preference),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
          ),
        ),
        child: Column(
          children: [
            Icon(
              _getIconForPreference(preference),
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              _getPreferenceTitle(preference),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForPreference(RoutePreference preference) {
    switch (preference) {
      case RoutePreference.fastest:
        return Icons.speed;
      case RoutePreference.shortest:
        return Icons.straighten;
      case RoutePreference.balanced:
        return Icons.balance;
    }
  }

  String _getPreferenceTitle(RoutePreference preference) {
    switch (preference) {
      case RoutePreference.fastest:
        return 'Fastest';
      case RoutePreference.shortest:
        return 'Shortest';
      case RoutePreference.balanced:
        return 'Balanced';
    }
  }
}

/// Widget to display route information
class RouteInfoCard extends StatelessWidget {
  final RouteResult route;
  final bool showInstructions;

  const RouteInfoCard({
    super.key,
    required this.route,
    this.showInstructions = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIconForPreference(route.preference),
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  _getPreferenceTitle(route.preference),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoItem(
                  Icons.straighten,
                  'Distance',
                  '${route.distanceKm.toStringAsFixed(1)} km',
                ),
                const SizedBox(width: 24),
                _buildInfoItem(
                  Icons.access_time,
                  'Duration',
                  '${route.duration.inMinutes} min',
                ),
              ],
            ),
            if (route.metadata.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Route via: ${route.metadata['provider'] ?? 'Unknown'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
            if (showInstructions && route.instructions.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Directions:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...route.instructions.take(5).map((instruction) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            instruction,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )),
              if (route.instructions.length > 5)
                Text(
                  '... and ${route.instructions.length - 5} more steps',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  IconData _getIconForPreference(RoutePreference preference) {
    switch (preference) {
      case RoutePreference.fastest:
        return Icons.speed;
      case RoutePreference.shortest:
        return Icons.straighten;
      case RoutePreference.balanced:
        return Icons.balance;
    }
  }

  String _getPreferenceTitle(RoutePreference preference) {
    switch (preference) {
      case RoutePreference.fastest:
        return 'Fastest Route';
      case RoutePreference.shortest:
        return 'Shortest Route';
      case RoutePreference.balanced:
        return 'Balanced Route';
    }
  }
}
