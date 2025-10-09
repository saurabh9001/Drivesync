import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:provider/provider.dart';
import '../models/advanced_models.dart';
import '../models/location.dart';
import '../data/demo_data.dart';
import '../viewmodels/map_viewmodel.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _isFullScreen = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<MapViewModel>(
      builder: (context, viewModel, child) {
        return _isFullScreen ? _buildFullScreenMap(viewModel) : _buildNormalMap(viewModel);
      },
    );
  }

  Widget _buildNormalMap(MapViewModel viewModel) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Map Controls
          _buildMapControls(viewModel),
          
          // Map View
          Expanded(
            child: _buildMap(viewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenMap(MapViewModel viewModel) {
    return Stack(
      children: [
        _buildMap(viewModel),
        Positioned(
          top: 16,
          right: 16,
          child: _buildFullScreenControls(viewModel),
        ),
      ],
    );
  }

  Widget _buildMap(MapViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            FlutterMap(
              mapController: viewModel.mapController,
              options: MapOptions(
                center: DemoData.maharashtraCenter.asLatLng,
                zoom: 12.0,
                minZoom: 5.0,
                maxZoom: 18.0,
                onTap: (tapPosition, point) => _onMapTap(viewModel, point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.safeway_ai',
                ),
                if (viewModel.showTraffic)
                  TileLayer(
                    urlTemplate: 'https://tile.thunderforest.com/transport/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.safeway_ai',
                  ),
                MarkerLayer(
                  markers: viewModel.markers,
                ),
              ],
            ),
            
            // Floating instruction overlay when no destination is set
            if (viewModel.destinationLocation == null)
              _buildFloatingMapHint(),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingMapHint() {
    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.touch_app,
                size: 16,
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tap anywhere on map to set destination',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControls(MapViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Show instruction banner when no destination is set
          if (viewModel.destinationLocation == null)
            _buildInstructionBanner(),
          
          _buildFilterButtons(viewModel),
          const SizedBox(height: 16),
          _buildMapButtons(viewModel),
        ],
      ),
    );
  }

  Widget _buildInstructionBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.touch_app,
            color: Colors.blue.shade600,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set Your Destination',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.blue.shade700,
                  ),
                ),
                Text(
                  'Tap anywhere on the map to set destination & get notified when you\'re 500m away',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons(MapViewModel viewModel) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterButton('All', null, viewModel),
        _buildFilterButton('Fatal', BlackspotSeverity.fatal, viewModel),
        _buildFilterButton('Serious', BlackspotSeverity.serious, viewModel),
        _buildFilterButton('Minor', BlackspotSeverity.minor, viewModel),
      ],
    );
  }

  Widget _buildFilterButton(String label, BlackspotSeverity? severity, MapViewModel viewModel) {
    final isSelected = severity == null ? viewModel.showAllSeverities
        : viewModel.visibleSeverities.contains(severity);
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => severity == null
          ? viewModel.toggleAllSeverities()
          : viewModel.toggleSeverityFilter(severity),
      backgroundColor: _getFilterColor(severity).withOpacity(0.1),
      selectedColor: _getFilterColor(severity).withOpacity(0.2),
      checkmarkColor: _getFilterColor(severity),
      labelStyle: TextStyle(
        color: isSelected ? _getFilterColor(severity) : Colors.grey,
      ),
    );
  }

  Color _getFilterColor(BlackspotSeverity? severity) {
    if (severity == null) return Colors.blue;
    switch (severity) {
      case BlackspotSeverity.fatal:
        return Colors.red;
      case BlackspotSeverity.serious:
        return Colors.orange;
      case BlackspotSeverity.minor:
        return Colors.green;
    }
  }

  Widget _buildMapButtons(MapViewModel viewModel) {
    return Column(
      children: [
        // Destination info
        if (viewModel.destinationLocation != null) 
          _buildDestinationInfo(viewModel),
        
        const SizedBox(height: 8),
        
        // Map buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMapButton(
              icon: Icons.layers,
              label: 'Traffic',
              isActive: viewModel.showTraffic,
              onPressed: viewModel.toggleTraffic,
            ),
            _buildMapButton(
              icon: Icons.my_location,
              label: 'My Location',
              onPressed: viewModel.centerOnCurrentLocation,
            ),
            if (viewModel.destinationLocation != null)
              _buildMapButton(
                icon: Icons.clear,
                label: 'Clear Dest',
                onPressed: () {
                  viewModel.clearDestination();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Destination cleared. Location tracking stopped.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
              ),
            _buildMapButton(
              icon: _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
              label: _isFullScreen ? 'Exit Fullscreen' : 'Fullscreen',
              onPressed: () => setState(() => _isFullScreen = !_isFullScreen),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDestinationInfo(MapViewModel viewModel) {
    final distance = viewModel.getDistanceToDestination();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Destination Set',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                if (distance != null)
                  Text(
                    'Distance: $distance',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
              ],
            ),
          ),
          if (viewModel.isTrackingLocation)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Tracking',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          color: isActive ? Theme.of(context).primaryColor : Colors.grey,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Theme.of(context).primaryColor : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildFullScreenControls(MapViewModel viewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.fullscreen_exit),
              onPressed: () => setState(() => _isFullScreen = false),
            ),
            const Divider(),
            IconButton(
              icon: const Icon(Icons.layers),
              onPressed: viewModel.toggleTraffic,
              color: viewModel.showTraffic ? Theme.of(context).primaryColor : Colors.grey,
            ),
            IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: viewModel.centerOnCurrentLocation,
            ),
          ],
        ),
      ),
    );
  }

  void _hideBottomSheet() {
    // Implementation for hiding bottom sheet if needed
  }

  Widget _buildLayerToggle(String label, IconData icon, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: value ? Colors.blue : Colors.grey),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: value ? Colors.blue : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        Switch(
          value: value,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          activeColor: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildWeatherInfo() {
    final weather = DemoData.getCurrentWeather();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(_getWeatherIcon(weather.condition), color: _getWeatherColor(weather.condition)),
          const SizedBox(width: 8),
          Text(
            '${weather.condition.toUpperCase()} • ${weather.temperature.toStringAsFixed(0)}°C',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            'Visibility: ${(weather.visibility / 1000).toStringAsFixed(1)}km',
            style: TextStyle(
              fontSize: 12,
              color: _getWeatherColor(weather.condition),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfo() {
    final routeSuggestions = DemoData.routeSuggestions;
    if (routeSuggestions.isEmpty) return const SizedBox.shrink();
    
    final route = routeSuggestions.first;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Route Analysis',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildRouteCard(
                  route['name'],
                  '${route['distance']} km • ${route['estimatedTime']}',
                  'Safety Score: ${route['safetyScore']}/10',
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRouteCard(
                  'Alternative Route',
                  '${(route['distance'] * 1.2).toStringAsFixed(1)} km • ${route['estimatedTime']}',
                  'Safer alternative route',
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(String title, String distance, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            distance,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF717182),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showSpotDetails(AdvancedBlackspot spot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _getSeverityColor(spot.severity),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.warning,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                spot.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${spot.type.name.toUpperCase()} • Risk Score: ${spot.riskScore.toStringAsFixed(1)}/10',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getSeverityColor(spot.severity),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    Text(
                      spot.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF717182),
                        height: 1.5,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    const Text(
                      'Accident Statistics',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('Fatal', spot.fatalAccidents.toString(), Colors.red)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStatCard('Serious', spot.seriousInjuries.toString(), Colors.orange)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStatCard('Minor', spot.minorIncidents.toString(), Colors.green)),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    const Text(
                      'Risk Factors',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Expanded(
                      child: ListView(
                        children: spot.riskFactors.map((factor) => 
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber, size: 16, color: Colors.orange[700]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    factor,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).toList(),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.alt_route),
                            label: const Text('Avoid Route'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.navigation),
                            label: const Text('Navigate'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E40AF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF717182),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(BlackspotSeverity severity) {
    switch (severity) {
      case BlackspotSeverity.fatal:
        return Colors.red;
      case BlackspotSeverity.serious:
        return Colors.orange;
      case BlackspotSeverity.minor:
        return Colors.green;
    }
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'rain':
        return Icons.umbrella;
      case 'fog':
        return Icons.foggy;
      case 'storm':
        return Icons.thunderstorm;
      default:
        return Icons.cloud;
    }
  }

  Color _getWeatherColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Colors.orange;
      case 'rain':
        return Colors.blue;
      case 'fog':
        return Colors.grey;
      case 'storm':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _onMapTap(MapViewModel viewModel, latlong.LatLng point) {
    _showDestinationDialog(viewModel, point);
  }

  void _showDestinationDialog(MapViewModel viewModel, latlong.LatLng point) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set Destination'),
          content: Text(
            'Set this location as your destination?\n\n'
            'Lat: ${point.latitude.toStringAsFixed(6)}\n'
            'Lng: ${point.longitude.toStringAsFixed(6)}\n\n'
            'You will be notified when you are within 500 meters.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                viewModel.setDestination(point.latitude, point.longitude);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Destination set! Location tracking started.'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Set Destination'),
            ),
          ],
        );
      },
    );
  }
}