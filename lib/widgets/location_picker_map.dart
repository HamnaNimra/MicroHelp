import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/geo_utils.dart';

class LocationPickerMap extends StatefulWidget {
  const LocationPickerMap({
    super.key,
    required this.initialLocation,
    required this.radiusKm,
    required this.onLocationChanged,
    this.actualGpsLocation,
  });

  final GeoPoint initialLocation;
  final double radiusKm;
  final ValueChanged<GeoPoint> onLocationChanged;
  final GeoPoint? actualGpsLocation;

  @override
  State<LocationPickerMap> createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends State<LocationPickerMap> {
  late final MapController _mapController;
  late LatLng _selectedPosition;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedPosition = LatLng(
      widget.initialLocation.latitude,
      widget.initialLocation.longitude,
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _onMapTap(TapPosition tapPosition, LatLng position) {
    setState(() => _selectedPosition = position);
    widget.onLocationChanged(
      GeoPoint(position.latitude, position.longitude),
    );
  }

  bool get _showGpsWarning {
    if (widget.actualGpsLocation == null) return false;
    final distance = distanceKm(
      widget.actualGpsLocation!,
      GeoPoint(_selectedPosition.latitude, _selectedPosition.longitude),
    );
    return distance > 2.0;
  }

  @override
  Widget build(BuildContext context) {
    final gpsLatLng = widget.actualGpsLocation != null
        ? LatLng(
            widget.actualGpsLocation!.latitude,
            widget.actualGpsLocation!.longitude,
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 300,
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedPosition,
                initialZoom: 14,
                onTap: _onMapTap,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.microhelp.app',
                  maxZoom: 19,
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _selectedPosition,
                      radius: widget.radiusKm * 1000,
                      useRadiusInMeter: true,
                      color:
                          Theme.of(context).colorScheme.primary.withAlpha(40),
                      borderColor: Theme.of(context).colorScheme.primary,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPosition,
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.location_pin,
                        size: 40,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    if (gpsLatLng != null && _showGpsWarning)
                      Marker(
                        point: gpsLatLng,
                        width: 32,
                        height: 32,
                        child: Icon(
                          Icons.my_location,
                          size: 32,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap the map to adjust your post location.',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        if (_showGpsWarning) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: Theme.of(context).colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your selected location differs from your current GPS. '
                    'Your real location (red pin) will be visible for safety.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onErrorContainer,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
