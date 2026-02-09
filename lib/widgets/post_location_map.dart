import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostLocationMap extends StatelessWidget {
  const PostLocationMap({
    super.key,
    required this.location,
    required this.radiusKm,
    this.isGlobal = false,
    this.myLocation,
  });

  final GeoPoint location;
  final double radiusKm;
  final bool isGlobal;
  final GeoPoint? myLocation;

  @override
  Widget build(BuildContext context) {
    final center = LatLng(location.latitude, location.longitude);
    final myLatLng = myLocation != null
        ? LatLng(myLocation!.latitude, myLocation!.longitude)
        : null;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: isGlobal ? 2 : 13,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.microhelp.app',
              maxZoom: 19,
            ),
            if (!isGlobal)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: center,
                    radius: radiusKm * 1000,
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
                  point: center,
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.location_pin,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (myLatLng != null)
                  Marker(
                    point: myLatLng,
                    width: 32,
                    height: 32,
                    child: Icon(
                      Icons.my_location,
                      size: 32,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
