import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Calculates the distance in kilometers between two [GeoPoint]s
/// using the Haversine formula.
double distanceKm(GeoPoint a, GeoPoint b) {
  const earthRadiusKm = 6371.0;

  final dLat = _degToRad(b.latitude - a.latitude);
  final dLon = _degToRad(b.longitude - a.longitude);

  final sinLat = sin(dLat / 2);
  final sinLon = sin(dLon / 2);

  final h = sinLat * sinLat +
      cos(_degToRad(a.latitude)) * cos(_degToRad(b.latitude)) * sinLon * sinLon;

  return 2 * earthRadiusKm * asin(sqrt(h));
}

double _degToRad(double deg) => deg * (pi / 180);
