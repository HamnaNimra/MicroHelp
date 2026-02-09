import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// Distance in KM using Haversine formula
double distanceKm(GeoPoint a, GeoPoint b) {
  const earthRadiusKm = 6371.0;

  final dLat = _degToRad(b.latitude - a.latitude);
  final dLon = _degToRad(b.longitude - a.longitude);

  final sinLat = sin(dLat / 2);
  final sinLon = sin(dLon / 2);

  final h = sinLat * sinLat +
      cos(_degToRad(a.latitude)) *
          cos(_degToRad(b.latitude)) *
          sinLon *
          sinLon;

  return 2 * earthRadiusKm * asin(sqrt(h));
}

double _degToRad(double deg) => deg * (pi / 180);

/// Gets user location, handles permissions, requests precise accuracy on iOS,
/// and stores location in Firestore.
/// Returns last known location if GPS unavailable.
Future<GeoPoint?> getAndSaveUserLocation(
  BuildContext context, {
  bool showRationale = true,
}) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  GeoPoint? saved;

  // Fetch previously saved location
  if (uid != null) {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      saved = doc.data()?['location'] as GeoPoint?;
    } catch (_) {}
  }

  // Permission state
  var permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied && showRationale) {
    if (!context.mounted) return saved;

    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.location_on, size: 40),
        title: const Text('Share your location'),
        content: const Text(
          'We use your location to show nearby help. '
          'Your exact address is never shared.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Allow'),
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
            'Location access was turned off. '
            'Please enable it in Settings.',
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

  if (permission != LocationPermission.always &&
      permission != LocationPermission.whileInUse) {
    return saved;
  }

  return _fetchAndSave(uid, saved);
}

Future<GeoPoint?> _fetchAndSave(String? uid, GeoPoint? fallback) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return fallback;

    // iOS precise location handling
    final accuracy = await Geolocator.getLocationAccuracy();
    if (accuracy == LocationAccuracyStatus.reduced) {
      await Geolocator.requestTemporaryFullAccuracy(
        purposeKey: 'PreciseLocation',
      );
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );

    final geoPoint = GeoPoint(pos.latitude, pos.longitude);

    if (uid != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'location': geoPoint}, SetOptions(merge: true))
          .catchError((_) {});
    }

    return geoPoint;
  } catch (_) {
    return fallback;
  }
}
