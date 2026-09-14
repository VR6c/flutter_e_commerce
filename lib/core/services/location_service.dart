import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../features/home/models/delivery_location.dart';

class LocationResult {
  final DeliveryLocation? location;
  final String? errorMessage;
  final bool isPermissionDeniedForever;
  final bool isGpsDisabled;

  const LocationResult.success(this.location)
      : errorMessage = null,
        isPermissionDeniedForever = false,
        isGpsDisabled = false;

  const LocationResult.error(
    this.errorMessage, {
    this.isPermissionDeniedForever = false,
    this.isGpsDisabled = false,
  }) : location = null;

  bool get isSuccess => location != null;
}

class LocationService {
  /// Request GPS coordinates and reverse-geocode to human-readable address
  static Future<LocationResult> getCurrentLocation() async {
    try {
      // 1. Check if location services (GPS) are enabled on the device
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult.error(
          'Location services (GPS) are disabled. Please turn on GPS in your device settings.',
          isGpsDisabled: true,
        );
      }

      // 2. Check & request runtime permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const LocationResult.error(
            'Location permission was denied. Please allow location access to pinpoint your delivery address.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationResult.error(
          'Location permissions are permanently denied. Please enable them in your device settings.',
          isPermissionDeniedForever: true,
        );
      }

      // 3. Acquire current GPS position
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      // 4. Reverse geocode to get street, district, and city
      String street = '';
      String city = 'Phnom Penh';
      String country = 'Cambodia';

      try {
        final List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final p = placemarks.first;

          final streetComponents = <String>[];
          if (p.street != null && p.street!.trim().isNotEmpty) {
            streetComponents.add(p.street!.trim());
          }
          if (p.subLocality != null &&
              p.subLocality!.trim().isNotEmpty &&
              !streetComponents.contains(p.subLocality!.trim())) {
            streetComponents.add(p.subLocality!.trim());
          }

          if (streetComponents.isNotEmpty) {
            street = streetComponents.join(', ');
          } else if (p.name != null && p.name!.trim().isNotEmpty) {
            street = p.name!.trim();
          }

          if (p.locality != null && p.locality!.trim().isNotEmpty) {
            city = p.locality!.trim();
          } else if (p.administrativeArea != null &&
              p.administrativeArea!.trim().isNotEmpty) {
            city = p.administrativeArea!.trim();
          }

          if (p.country != null && p.country!.trim().isNotEmpty) {
            country = p.country!.trim();
          }
        }
      } catch (e) {
        debugPrint('Reverse geocoding error (using coordinate fallback): $e');
      }

      // Fallback street name if reverse geocoding returned blank
      if (street.isEmpty) {
        street =
            'Near ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      }

      final location = DeliveryLocation(
        id: 'loc_current_${DateTime.now().millisecondsSinceEpoch}',
        label: 'Current Location',
        street: street,
        city: city,
        country: country,
        iconType: 'current',
      );

      return LocationResult.success(location);
    } on MissingPluginException catch (e) {
      debugPrint('GPS MissingPluginException (full app rebuild needed): $e');
      return const LocationResult.error(
        'GPS service not available. Please use "Set Location on Map" to pin your address.',
      );
    } catch (e) {
      debugPrint('GPS Detection Exception: $e');
      return LocationResult.error(
        'Unable to detect GPS location: ${e.toString().replaceAll('Exception:', '').trim()}',
      );
    }
  }

  /// Helper to open device app settings if permissions were permanently denied
  static Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Helper to open location settings if GPS is switched off
  static Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
}
