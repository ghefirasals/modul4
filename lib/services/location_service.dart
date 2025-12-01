import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service untuk mengelola lokasi GPS dan Network Provider
/// Mendukung toggle antara GPS (akurasi tinggi) dan Network Provider (hemat baterai)
class LocationService {
  StreamSubscription<Position>? _positionSubscription;

  /// Cek apakah location service enabled
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      if (kDebugMode) print('Error checking location service: $e');
      return false;
    }
  }

  /// Cek permission status
  Future<LocationPermission> checkPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      if (kDebugMode) print('Error checking permission: $e');
      return LocationPermission.denied;
    }
  }

  /// Request permission dengan opsi GPS requirement
  Future<bool> requestPermission({bool requireGps = true}) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      // Jika permission denied, request
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      // Jika denied forever, buka settings
      if (permission == LocationPermission.deniedForever) {
        await openAppSettings();
        return false;
      }

      // Jika GPS di-required dan service tidak aktif, buka settings
      if (requireGps) {
        bool isEnabled = await isLocationServiceEnabled();
        if (!isEnabled) {
          await openLocationSettings();
          return false;
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) print('Error requesting permission: $e');
      return false;
    }
  }

  /// Buka location settings
  Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
      if (kDebugMode) print('Error opening location settings: $e');
      // Fallback: buka app settings
      await openAppSettings();
    }
  }

  /// Buka app settings
  Future<void> openAppSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (e) {
      if (kDebugMode) print('Error opening app settings: $e');
      // Fallback: gunakan url launcher
      try {
        await openAppSettingsFallback();
      } catch (e2) {
        if (kDebugMode) print('Error opening app settings fallback: $e2');
      }
    }
  }

  /// Fallback method untuk membuka app settings
  Future<void> openAppSettingsFallback() async {
    try {
      if (await canLaunchUrl(Uri.parse('app-settings:'))) {
        await launchUrl(Uri.parse('app-settings:'));
      }
    } catch (e) {
      if (kDebugMode) print('Error in fallback app settings: $e');
    }
  }

  /// Dapatkan posisi saat ini dengan opsi GPS/Network
  Future<Position?> getCurrentPosition({
    bool useGps = true,
    LocationAccuracy accuracy = LocationAccuracy.best,
    int timeoutInSeconds = 15,
  }) async {
    try {
      // Cek permission dulu
      LocationPermission permission = await checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      // Jika GPS di-required dan service tidak aktif
      if (useGps) {
        bool isEnabled = await isLocationServiceEnabled();
        if (!isEnabled) {
          return null;
        }
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: useGps ? LocationAccuracy.bestForNavigation : LocationAccuracy.medium,
        timeLimit: Duration(seconds: timeoutInSeconds),
        forceAndroidLocationManager: !useGps, // Gunakan network provider jika GPS tidak di-required
      );
    } catch (e) {
      if (kDebugMode) print('Error getting current position: $e');
      return null;
    }
  }

  /// Dapatkan posisi terakhir yang diketahui
  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      if (kDebugMode) print('Error getting last known position: $e');
      return null;
    }
  }

  /// Dapatkan stream posisi dengan opsi GPS/Network
  Stream<Position>? getPositionStream({
    bool useGps = true,
    LocationAccuracy accuracy = LocationAccuracy.best,
    int distanceFilter = 10,
    bool stopWhenLastPositionNull = true,
  }) {
    try {
      // Cek permission dulu
      checkPermission().then((permission) {
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          _positionSubscription?.cancel();
          return;
        }
      }).catchError((e) {
        if (kDebugMode) print('Error checking permission for stream: $e');
        _positionSubscription?.cancel();
      });

      return Geolocator.getPositionStream(
        locationSettings: useGps
            ? AndroidSettings(
                accuracy: LocationAccuracy.bestForNavigation,
                distanceFilter: distanceFilter,
                intervalDuration: const Duration(seconds: 2),
                foregroundNotificationConfig: const ForegroundNotificationConfig(
                  notificationText: "Nasi Padang App is tracking your location",
                  notificationTitle: "Location Tracking",
                  enableWakeLock: true,
                ),
              )
            : LocationSettings(
                accuracy: LocationAccuracy.medium,
                distanceFilter: distanceFilter,
              ),
      );
    } catch (e) {
      if (kDebugMode) print('Error getting position stream: $e');
      return null;
    }
  }

  /// Stop position stream
  void stopPositionStream() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Dispose service
  void dispose() {
    stopPositionStream();
  }
}