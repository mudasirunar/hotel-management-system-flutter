import 'package:flutter/material.dart';

import '../../../../domain/services/hotel_search_service.dart';

/// Bottom sheet for adjusting destination city, budget, rating, amenities, and availability filters.
class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({
    super.key,
    required this.initialCriteria,
    required this.onApply,
  });

  final HotelFilterCriteria initialCriteria;
  final ValueChanged<HotelFilterCriteria> onApply;

  static Future<void> show({
    required BuildContext context,
    required HotelFilterCriteria criteria,
    required ValueChanged<HotelFilterCriteria> onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        initialCriteria: criteria,
        onApply: onApply,
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String? _selectedCity;
  late int? _maxPricePKR;
  late double? _minRating;
  late Set<String> _selectedAmenities;
  late bool _onlyAvailable;

  static const List<String> _cities = [
    'All Cities',
    'Karachi',
    'Lahore',
    'Islamabad',
    'Murree',
  ];

  static const List<int> _priceOptions = [
    15000,
    25000,
    35000,
    50000,
  ];

  static const List<String> _availableAmenities = [
    'WiFi',
    'Swimming Pool',
    'Breakfast',
    'Parking',
    'Air Conditioning',
    'Fitness Center',
    'Restaurant',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.initialCriteria.city;
    _maxPricePKR = widget.initialCriteria.maxNightlyPricePKR;
    _minRating = widget.initialCriteria.minRating;
    _selectedAmenities = Set<String>.from(widget.initialCriteria.requiredAmenities);
    _onlyAvailable = widget.initialCriteria.onlyAvailableRooms;
  }

  void _reset() {
    setState(() {
      _selectedCity = null;
      _maxPricePKR = null;
      _minRating = null;
      _selectedAmenities.clear();
      _onlyAvailable = false;
    });
  }

  void _apply() {
    final updated = widget.initialCriteria.copyWith(
      city: _selectedCity,
      clearCity: _selectedCity == null || _selectedCity == 'All Cities',
      maxNightlyPricePKR: _maxPricePKR,
      clearMaxPrice: _maxPricePKR == null,
      minRating: _minRating,
      clearMinRating: _minRating == null,
      requiredAmenities: _selectedAmenities,
      onlyAvailableRooms: _onlyAvailable,
    );
    widget.onApply(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceBg = isDark ? const Color(0xFF141A16) : Colors.white;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: surfaceBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: _reset,
                  child: const Text('Reset all'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable Filter Sections
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Destination City
                Text(
                  'Destination City',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _cities.map((city) {
                    final isSelected = (_selectedCity == null && city == 'All Cities') ||
                        (_selectedCity == city);
                    return ChoiceChip(
                      label: Text(city),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCity = (city == 'All Cities') ? null : city;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Max Budget
                Text(
                  'Max Nightly Budget',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Any Budget'),
                      selected: _maxPricePKR == null,
                      onSelected: (selected) {
                        setState(() => _maxPricePKR = null);
                      },
                    ),
                    ..._priceOptions.map((price) {
                      final isSelected = _maxPricePKR == price;
                      return ChoiceChip(
                        label: Text('Up to PKR ${(price / 1000).round()}k'),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _maxPricePKR = selected ? price : null);
                        },
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 24),

                // Guest Rating
                Text(
                  'Minimum Guest Rating',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Any'),
                      selected: _minRating == null,
                      onSelected: (selected) {
                        setState(() => _minRating = null);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('★ 4.0+'),
                      selected: _minRating == 4.0,
                      onSelected: (selected) {
                        setState(() => _minRating = selected ? 4.0 : null);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('★ 4.5+'),
                      selected: _minRating == 4.5,
                      onSelected: (selected) {
                        setState(() => _minRating = selected ? 4.5 : null);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Popular Amenities
                Text(
                  'Amenities',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableAmenities.map((amenity) {
                    final isSelected = _selectedAmenities.contains(amenity);
                    return FilterChip(
                      label: Text(amenity),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedAmenities.add(amenity);
                          } else {
                            _selectedAmenities.remove(amenity);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Only Available Rooms Switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Available for Selected Dates Only',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Hide hotels with no rooms matching your party size',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _onlyAvailable,
                  onChanged: (val) {
                    setState(() => _onlyAvailable = val);
                  },
                ),
              ],
            ),
          ),

          // Footer Apply Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _apply,
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
