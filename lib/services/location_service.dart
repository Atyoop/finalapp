import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final LocationStatus status;
  final String? message;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.status,
    this.message,
  });
}

enum LocationStatus {
  success,
  denied,
  deniedForever,
  gpsDisabled,
  error,
}

class LocationService {
  static Future<LocationResult> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult(
          latitude: 0,
          longitude: 0,
          status: LocationStatus.gpsDisabled,
          message: 'GPS is disabled. Please enable location services.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult(
            latitude: 0,
            longitude: 0,
            status: LocationStatus.denied,
            message: 'Location permission denied.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult(
          latitude: 0,
          longitude: 0,
          status: LocationStatus.deniedForever,
          message: 'Location permission permanently denied. Please enable from Settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition();

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        status: LocationStatus.success,
      );
    } catch (e) {
      debugPrint('[LocationService] Error: $e');
      return LocationResult(
        latitude: 0,
        longitude: 0,
        status: LocationStatus.error,
        message: 'Could not get location: $e',
      );
    }
  }

  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  static Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  static Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  static Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}
