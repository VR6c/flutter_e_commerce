import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/location_service.dart';
import '../models/delivery_location.dart';

const _kSavedDeliveryLocationsKey = 'saved_delivery_locations_v1';
const _kSelectedDeliveryLocationIdKey = 'selected_delivery_location_id_v1';

class DeliveryLocationState {
  final List<DeliveryLocation> savedLocations;
  final DeliveryLocation? selectedLocation;
  final bool isLoading;

  const DeliveryLocationState({
    required this.savedLocations,
    this.selectedLocation,
    this.isLoading = false,
  });

  DeliveryLocationState copyWith({
    List<DeliveryLocation>? savedLocations,
    DeliveryLocation? selectedLocation,
    bool? isLoading,
  }) {
    return DeliveryLocationState(
      savedLocations: savedLocations ?? this.savedLocations,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class DeliveryLocationNotifier extends StateNotifier<DeliveryLocationState> {
  DeliveryLocationNotifier()
      : super(
          const DeliveryLocationState(
            savedLocations: DeliveryLocation.defaultLocations,
            selectedLocation: DeliveryLocation.defaultHome,
            isLoading: true,
          ),
        ) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getString(_kSavedDeliveryLocationsKey);
      final selectedId = prefs.getString(_kSelectedDeliveryLocationIdKey);

      List<DeliveryLocation> locations = List.from(DeliveryLocation.defaultLocations);

      if (rawList != null && rawList.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(rawList) as List<dynamic>;
        final loaded = decoded
            .map((e) => DeliveryLocation.fromJson(e as Map<String, dynamic>))
            // Purge any old "Current Location" or "Toul Kork" entries
            .where((loc) => !loc.id.contains('current') && !loc.street.toLowerCase().contains('toul kork'))
            .toList();
        if (loaded.isNotEmpty) {
          locations = loaded;
        }
      }

      DeliveryLocation selected;
      if (selectedId != null && !selectedId.contains('current')) {
        selected = locations.firstWhere(
          (loc) => loc.id == selectedId,
          orElse: () => locations.firstWhere((l) => l.isDefault, orElse: () => locations.first),
        );
      } else {
        selected = locations.firstWhere(
          (loc) => loc.isDefault,
          orElse: () => locations.first,
        );
      }

      // Overwrite prefs if cleanup occurred
      if (rawList != null && rawList.contains('current')) {
        final encoded = jsonEncode(locations.map((e) => e.toJson()).toList());
        await prefs.setString(_kSavedDeliveryLocationsKey, encoded);
        await prefs.setString(_kSelectedDeliveryLocationIdKey, selected.id);
      }

      state = DeliveryLocationState(
        savedLocations: locations,
        selectedLocation: selected,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> selectLocation(DeliveryLocation location) async {
    state = state.copyWith(selectedLocation: location);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kSelectedDeliveryLocationIdKey, location.id);
    } catch (_) {}
  }

  Future<void> addLocation(DeliveryLocation location) async {
    // Avoid duplicate IDs
    final updated = [
      ...state.savedLocations.where((l) => l.id != location.id),
      location,
    ];

    state = state.copyWith(
      savedLocations: updated,
      selectedLocation: location,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(updated.map((e) => e.toJson()).toList());
      await prefs.setString(_kSavedDeliveryLocationsKey, encoded);
      await prefs.setString(_kSelectedDeliveryLocationIdKey, location.id);
    } catch (_) {}
  }

  Future<void> removeLocation(String id) async {
    final updated = state.savedLocations.where((l) => l.id != id).toList();
    if (updated.isEmpty) return;

    DeliveryLocation newSelected = state.selectedLocation ?? updated.first;
    if (state.selectedLocation?.id == id) {
      newSelected = updated.first;
    }

    state = state.copyWith(
      savedLocations: updated,
      selectedLocation: newSelected,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(updated.map((e) => e.toJson()).toList());
      await prefs.setString(_kSavedDeliveryLocationsKey, encoded);
      await prefs.setString(_kSelectedDeliveryLocationIdKey, newSelected.id);
    } catch (_) {}
  }

  /// Detect real current location via GPS and reverse geocoding
  Future<LocationResult> detectAndUseGpsLocation() async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await LocationService.getCurrentLocation();
      if (result.isSuccess && result.location != null) {
        await addLocation(result.location!);
      }
      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return LocationResult.error(e.toString());
    }
  }
}

final deliveryLocationProvider =
    StateNotifierProvider<DeliveryLocationNotifier, DeliveryLocationState>(
  (ref) => DeliveryLocationNotifier(),
);
