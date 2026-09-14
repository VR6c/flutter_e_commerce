import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/delivery_location.dart';
import '../providers/delivery_location_provider.dart';
import '../screens/location_picker_map_screen.dart';

class LocationSelectionSheet extends ConsumerStatefulWidget {
  const LocationSelectionSheet({super.key});

  static Future<DeliveryLocation?> show(BuildContext context) {
    return showModalBottomSheet<DeliveryLocation>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LocationSelectionSheet(),
    );
  }

  @override
  ConsumerState<LocationSelectionSheet> createState() =>
      _LocationSelectionSheetState();
}

class _LocationSelectionSheetState
    extends ConsumerState<LocationSelectionSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isAddingNew = false;

  // New Address Form Controllers
  final _streetController = TextEditingController();
  final _cityController = TextEditingController(text: 'Phnom Penh');
  String _selectedLabelType = 'Home';
  final _customLabelController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _customLabelController.dispose();
    super.dispose();
  }

  IconData _getIconForType(String iconType) {
    switch (iconType.toLowerCase()) {
      case 'home':
        return Icons.home_rounded;
      case 'work':
      case 'office':
        return Icons.business_center_rounded;
      case 'apartment':
      case 'condo':
        return Icons.apartment_rounded;
      case 'current':
        return Icons.my_location_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  void _handleAddNewAddress() {
    final street = _streetController.text.trim();
    if (street.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a street address'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final label =
        _selectedLabelType == 'Other' &&
            _customLabelController.text.trim().isNotEmpty
        ? _customLabelController.text.trim()
        : _selectedLabelType;

    String iconType = 'pin';
    if (_selectedLabelType == 'Home') iconType = 'home';
    if (_selectedLabelType == 'Work') iconType = 'work';
    if (_selectedLabelType == 'Apartment') iconType = 'apartment';

    final newLocation = DeliveryLocation(
      id: 'loc_${DateTime.now().millisecondsSinceEpoch}',
      label: label,
      street: street,
      city: _cityController.text.trim().isEmpty
          ? 'Phnom Penh'
          : _cityController.text.trim(),
      iconType: iconType,
    );

    HapticFeedback.mediumImpact();
    ref.read(deliveryLocationProvider.notifier).addLocation(newLocation);
    Navigator.of(context).pop(newLocation);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Delivery address set to "$label"'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(deliveryLocationProvider);
    final selectedLocation = state.selectedLocation;

    // Filter saved locations by search query
    final filteredLocations = state.savedLocations.where((loc) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return loc.label.toLowerCase().contains(query) ||
          loc.street.toLowerCase().contains(query) ||
          loc.city.toLowerCase().contains(query);
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
            // ── Top Drag Handle ──────────────────────────────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // ── Header Row ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose Delivery Location',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Groceries will be delivered to this address',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.grey[400]
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ── Main Body (Scrollable) ───────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_isAddingNew) ...[
                      // ── Search Bar ─────────────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() => _searchQuery = val.trim());
                          },
                          decoration: InputDecoration(
                            hintText: 'Search area, street or landmark...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.grey[500]
                                  : const Color(0xFF94A3B8),
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear_rounded,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── "Set on Map" Quick Action ───────────────────────
                      InkWell(
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          final navigator = Navigator.of(context);
                          final loc = await LocationPickerMapScreen.show(
                            context,
                          );
                          if (loc != null && mounted) {
                            navigator.pop(loc);
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.map_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Set Location on Map',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary
                                                .withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            'Interactive',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Drag pin to your exact delivery spot',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: isDark
                                    ? Colors.grey[500]
                                    : const Color(0xFF94A3B8),
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Saved Addresses Section Title ──────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SAVED ADDRESSES',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: isDark
                                  ? Colors.grey[400]
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                          Text(
                            '${filteredLocations.length} locations',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.grey[500]
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // ── Saved Addresses List ───────────────────────────
                      if (filteredLocations.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 40,
                                color: isDark
                                    ? Colors.grey[600]
                                    : const Color(0xFFCBD5E1),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No addresses matching "$_searchQuery"',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredLocations.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final loc = filteredLocations[index];
                            final isSelected = selectedLocation?.id == loc.id;

                            return InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                ref
                                    .read(deliveryLocationProvider.notifier)
                                    .selectLocation(loc);
                                Navigator.of(context).pop(loc);
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (theme.colorScheme.primary.withValues(
                                          alpha: 0.06,
                                        ))
                                      : (isDark
                                            ? const Color(0xFF0F172A)
                                            : const Color(0xFFF8FAFC)),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : (isDark
                                              ? const Color(0xFF334155)
                                              : const Color(0xFFE2E8F0)),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Icon container
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                                  .withValues(alpha: 0.15)
                                            : (isDark
                                                  ? const Color(0xFF1E293B)
                                                  : const Color(0xFFEDF2F7)),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _getIconForType(loc.iconType),
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : (isDark
                                                  ? Colors.grey[300]
                                                  : const Color(0xFF475569)),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Address text
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                loc.label,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                  color: theme
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                              ),
                                              if (loc.isDefault) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 1.5,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: theme
                                                        .colorScheme
                                                        .primary
                                                        .withValues(
                                                          alpha: 0.12,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'Default',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: theme
                                                          .colorScheme
                                                          .primary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${loc.street}, ${loc.city}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: isDark
                                                  ? Colors.grey[400]
                                                  : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Radio / Checkmark
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: theme.colorScheme.primary,
                                        size: 22,
                                      )
                                    else
                                      Icon(
                                        Icons.radio_button_unchecked_rounded,
                                        color: isDark
                                            ? Colors.grey[600]
                                            : const Color(0xFFCBD5E1),
                                        size: 22,
                                      ),
                                    // Remove button for custom locations
                                    if (!loc.isDefault &&
                                        loc.id != 'loc_current') ...[
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete_outline_rounded,
                                          size: 18,
                                          color: isDark
                                              ? Colors.grey[500]
                                              : const Color(0xFF94A3B8),
                                        ),
                                        onPressed: () {
                                          ref
                                              .read(
                                                deliveryLocationProvider
                                                    .notifier,
                                              )
                                              .removeLocation(loc.id);
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: 16),

                      // ── Add New Address Button ─────────────────────────
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() => _isAddingNew = true);
                        },
                        icon: const Icon(
                          Icons.add_location_alt_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          'Add New Address',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          side: BorderSide(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ] else ...[
                      // ── Add New Address Form ───────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Add Delivery Address',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() => _isAddingNew = false);
                            },
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              size: 16,
                            ),
                            label: const Text('Back'),
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Label selection chips
                      Text(
                        'Address Label',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.grey[400]
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: ['Home', 'Work', 'Apartment', 'Other'].map((
                          label,
                        ) {
                          final isSelected = _selectedLabelType == label;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(label),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() => _selectedLabelType = label);
                              },
                              selectedColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.15),
                              labelStyle: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : (isDark
                                          ? Colors.grey[300]
                                          : const Color(0xFF475569)),
                                fontSize: 12.5,
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

                      if (_selectedLabelType == 'Other') ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: _customLabelController,
                          decoration: InputDecoration(
                            hintText:
                                'Custom label (e.g. Gym, Friend\'s Place)',
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      // Street Address Input
                      Text(
                        'Street & House / Building',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.grey[400]
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _streetController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'e.g. Street 2004, Sen Sok, House #42',
                          prefixIcon: const Icon(Icons.home_outlined, size: 20),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // City Input
                      Text(
                        'City / District',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.grey[400]
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _cityController,
                        decoration: InputDecoration(
                          hintText: 'Phnom Penh',
                          prefixIcon: const Icon(
                            Icons.location_city_rounded,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Save Button
                      ElevatedButton(
                        onPressed: _handleAddNewAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Save & Deliver Here',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
