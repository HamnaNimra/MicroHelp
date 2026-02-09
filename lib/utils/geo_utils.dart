import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

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

/// Attempts to get the user's current location. If permission is already
/// granted, silently fetches GPS. If not, shows a rationale dialog first.
/// Returns the [GeoPoint] or null if unavailable.
/// Also saves the location to the user's Firestore profile.
Future<GeoPoint?> getAndSaveUserLocation(BuildContext context, {bool showRationale = true}) async {
  // First check if we have a saved location in Firestore
  final uid = FirebaseAuth.instance.currentUser?.uid;
  GeoPoint? saved;
  if (uid != null) {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      saved = doc.data()?['location'] as GeoPoint?;
    } catch (_) {}
  }

  // Check current permission state
  var permission = await Geolocator.checkPermission();

  // If already granted (always or while-in-use), just grab location
  if (permission == LocationPermission.always ||
      permission == LocationPermission.whileInUse) {
    return _fetchAndSave(uid, saved);
  }

  // Permission denied — show rationale and request
  if (permission == LocationPermission.denied && showRationale) {
    if (!context.mounted) return saved;
    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.location_on, size: 40),
        title: const Text('Share your location'),
        content: const Text(
          'We need your location to show your approximate area. '
          'Your exact address is never shared.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Allow location'),
          ),
        ],
      ),
    );
    if (shouldRequest != true) return saved;
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.deniedForever) {
    if (showRationale && context.mounted) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.location_off, size: 40),
          title: const Text('Location access needed'),
          content: const Text(
            'Location access was permanently denied. '
            'Please enable it in your device Settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
            FilledButton(
              onPressed: () {
                Geolocator.openAppSettings();
                Navigator.pop(ctx);
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }
    return saved;
  }

  if (permission == LocationPermission.denied) return saved;

  return _fetchAndSave(uid, saved);
}

Future<GeoPoint?> _fetchAndSave(String? uid, GeoPoint? fallback) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return fallback;
    final pos = await Geolocator.getCurrentPosition();
    final geoPoint = GeoPoint(pos.latitude, pos.longitude);
    // Save to Firestore for future use
    if (uid != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'location': geoPoint})
          .catchError((_) {});
    }
    return geoPoint;
  } catch (_) {
    return fallback;
  }
}
