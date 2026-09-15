import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/location_service.dart';
import '../models/delivery_location.dart';
import '../providers/delivery_location_provider.dart';

class LocationPickerMapScreen extends ConsumerStatefulWidget {
  final LatLng? initialCenter;
  final String? initialLabel;

  const LocationPickerMapScreen({
    super.key,
    this.initialCenter,
    this.initialLabel,
  });

  static Future<DeliveryLocation?> show(
    BuildContext context, {
    LatLng? initialCenter,
    String? initialLabel,
  }) {
    return Navigator.of(context).push<DeliveryLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerMapScreen(
          initialCenter: initialCenter,
          initialLabel: initialLabel,
        ),
      ),
    );
  }

  @override
  ConsumerState<LocationPickerMapScreen> createState() =>
      _LocationPickerMapScreenState();
}

class _LocationPickerMapScreenState
    extends ConsumerState<LocationPickerMapScreen>
    with TickerProviderStateMixin {
  late final MapController _mapController;
  late LatLng _currentCenter;
  bool _isDragging = false;
  bool _isReverseGeocoding = false;
  bool _isLocatingGps = false;

  Timer? _debounceTimer;

  // Address details
  String _streetAddress = 'Loading address...';
  String _cityName = 'Phnom Penh';
  String _countryName = 'Cambodia';
  String _selectedLabel = 'Home';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Default to provided initial center or Phnom Penh
    _currentCenter =
        widget.initialCenter ??
        const LatLng(11.5564, 104.9282); // Phnom Penh coordinates

    _selectedLabel = widget.initialLabel ?? 'Home';

    // Initial reverse geocode
    _reverseGeocode(_currentCenter);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture) {
      if (!_isDragging) {
        setState(() => _isDragging = true);
      }
      _currentCenter = camera.center;

      // Debounce reverse geocoding to avoid excessive requests during scroll
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() => _isDragging = false);
          _reverseGeocode(camera.center);
        }
      });
    }
  }

  Future<void> _reverseGeocode(LatLng coordinates) async {
    setState(() => _isReverseGeocoding = true);
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        coordinates.latitude,
        coordinates.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        final streetParts = <String>[];
        if (p.street != null && p.street!.trim().isNotEmpty) {
          streetParts.add(p.street!.trim());
        }
        if (p.subLocality != null &&
            p.subLocality!.trim().isNotEmpty &&
            !streetParts.contains(p.subLocality!.trim())) {
          streetParts.add(p.subLocality!.trim());
        }

        setState(() {
          _streetAddress = streetParts.isNotEmpty
              ? streetParts.join(', ')
              : (p.name?.isNotEmpty == true ? p.name! : 'Near coordinates');
          _cityName =
              (p.locality?.isNotEmpty == true
                  ? p.locality
                  : p.administrativeArea) ??
              'Phnom Penh';
          _countryName = p.country ?? 'Cambodia';
          _isReverseGeocoding = false;
        });
        return;
      }
    } catch (_) {
      // Fallback to lat/lng display if offline or reverse geocoding unavailable
    }

    if (mounted) {
      setState(() {
        _streetAddress =
            'Near ${coordinates.latitude.toStringAsFixed(4)}, ${coordinates.longitude.toStringAsFixed(4)}';
        _isReverseGeocoding = false;
      });
    }
  }

  Future<void> _moveToCurrentGps() async {
    setState(() => _isLocatingGps = true);
    HapticFeedback.lightImpact();

    try {
      final result = await LocationService.getCurrentLocation();
      if (!mounted) return;
      setState(() => _isLocatingGps = false);

      if (result.isSuccess && result.location != null) {
        final loc = result.location!;
        if (loc.latitude != null && loc.longitude != null) {
          final target = LatLng(loc.latitude!, loc.longitude!);
          _mapController.move(target, 16.5);
          _reverseGeocode(target);
        } else {
          // Default to Phnom Penh center
          const target = LatLng(11.5564, 104.9282);
          _mapController.move(target, 16.5);
          _reverseGeocode(target);
        }
        HapticFeedback.mediumImpact();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.errorMessage ?? 'Could not detect GPS location',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _isLocatingGps = false);
    }
  }

  void _confirmPinnedLocation() {
    HapticFeedback.mediumImpact();

    String iconType = 'pin';
    if (_selectedLabel == 'Home') iconType = 'home';
    if (_selectedLabel == 'Work') iconType = 'work';
    if (_selectedLabel == 'Apartment') iconType = 'apartment';

    final location = DeliveryLocation(
      id: 'loc_map_${DateTime.now().millisecondsSinceEpoch}',
      label: _selectedLabel,
      street: _streetAddress,
      city: _cityName,
      country: _countryName,
      iconType: iconType,
      latitude: _currentCenter.latitude,
      longitude: _currentCenter.longitude,
    );

    ref.read(deliveryLocationProvider.notifier).addLocation(location);
    Navigator.of(context).pop(location);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pinned address saved: "$_streetAddress"'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // ── 1. Interactive OpenStreetMap ────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 16.0,
              minZoom: 10.0,
              maxZoom: 18.5,
              onPositionChanged: _onPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.flutter_e_commerce',
                maxZoom: 19,
              ),
            ],
          ),

          // ── 2. Center Target Pin (Interactive Floating Pin) ─────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Pin
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  transform: Matrix4.translationValues(
                    0,
                    _isDragging ? -14 : 0,
                    0,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _isDragging ? 'Move map to pin' : 'Deliver Here',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        Icons.location_pin,
                        color: theme.colorScheme.primary,
                        size: 46,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Drop shadow on ground
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: _isDragging ? 8 : 12,
                  height: _isDragging ? 3 : 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(
                      alpha: _isDragging ? 0.2 : 0.4,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(
                  height: 48,
                ), // Offsets center marker to pin point
              ],
            ),
          ),

          // ── 3. Top Floating App Bar ─────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Back button
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title pill
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.map_rounded,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.l10n.isKhmer
                                  ? 'កំណត់ទីតាំងដឹកជញ្ជូន'
                                  : 'Pin Delivery Location',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: theme.colorScheme.onSurface,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 4. My Location (GPS) Floating Button ────────────────────────
          Positioned(
            right: 16,
            bottom: 240,
            child: FloatingActionButton(
              heroTag: 'map_gps_fab',
              onPressed: _isLocatingGps ? null : _moveToCurrentGps,
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              foregroundColor: theme.colorScheme.primary,
              elevation: 4,
              child: _isLocatingGps
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    )
                  : const Icon(Icons.my_location_rounded, size: 24),
            ),
          ),

          // ── 5. Bottom Address Confirmation Card ─────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag notch
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey[700]
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Address Info Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.12,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            color: theme.colorScheme.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.isKhmer
                                    ? 'ទីតាំងដែលបានជ្រើសរើស'
                                    : 'SELECTED LOCATION',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: context.l10n.isKhmer ? 0 : 0.8,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 3),
                              if (_isReverseGeocoding)
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              theme.colorScheme.primary,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      context.l10n.isKhmer
                                          ? 'កំពុងកំណត់អាសយដ្ឋាន...'
                                          : 'Locating address...',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontSize: 14,
                                        letterSpacing: 0,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Text(
                                  _streetAddress,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.onSurface,
                                    letterSpacing: 0,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 2),
                              Text(
                                '$_cityName, $_countryName',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 12,
                                  letterSpacing: 0,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Label chips
                    Row(
                      children: ['Home', 'Work', 'Apartment', 'Other'].map((
                        label,
                      ) {
                        final isSelected = _selectedLabel == label;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              _translateLabelType(label, context.l10n.isKhmer),
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : (isDark
                                          ? Colors.grey[300]
                                          : const Color(0xFF475569)),
                                letterSpacing: 0,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (_) =>
                                setState(() => _selectedLabel = label),
                            selectedColor: theme.colorScheme.primary.withValues(
                              alpha: 0.15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : (isDark
                                          ? const Color(0xFF334155)
                                          : const Color(0xFFE2E8F0)),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Confirm button
                    ElevatedButton(
                      onPressed: _isReverseGeocoding
                          ? null
                          : _confirmPinnedLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        context.l10n.isKhmer
                            ? 'បញ្ជាក់ទីតាំងដឹកជញ្ជូន'
                            : 'Confirm Delivery Location',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _translateLabelType(String label, bool isKhmer) {
    if (!isKhmer) return label;
    switch (label.toLowerCase()) {
      case 'home':
        return 'ផ្ទះ';
      case 'work':
        return 'កន្លែងធ្វើការ';
      case 'apartment':
        return 'ខុនដូ/បន្ទប់';
      case 'other':
      default:
        return 'ផ្សេងៗ';
    }
  }
}
