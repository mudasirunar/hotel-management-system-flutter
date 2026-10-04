import 'package:flutter/material.dart';

import '../../../application/hotel_controller.dart';
import '../../../application/theme_controller.dart';
import '../../../data/local/hotel_profile_preferences.dart';
import '../../../domain/services/demo_data_seeder.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.controller,
    required this.hotelController,
    this.profilePreferences,
  });

  final ThemeController controller;
  final HotelController hotelController;
  final HotelProfilePreferences? profilePreferences;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final HotelProfilePreferences _prefs =
      widget.profilePreferences ?? HotelProfilePreferences();
  HotelProfile _profile = HotelProfile.defaultProfile;
  bool _operating = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final loaded = await _prefs.load();
    if (mounted) {
      setState(() => _profile = loaded);
    }
  }

  Future<void> _editProfile() async {
    final updated = await showDialog<HotelProfile>(
      context: context,
      builder: (context) => _EditHotelProfileDialog(profile: _profile),
    );

    if (updated != null && mounted) {
      await _prefs.save(updated);
      setState(() => _profile = updated);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Hotel profile updated.')));
      }
    }
  }

  Future<void> _seedDemoData() async {
    if (_operating) return;
    setState(() => _operating = true);
    try {
      var isSeeding = false;
      final success = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) {
            final scheme = Theme.of(context).colorScheme;
            return AlertDialog(
              title: const Text('Load Demo Records?'),
              content: const Text(
                'This will populate sample rooms, guest profiles, and active stays for evaluation and demonstration. Existing records will be replaced.',
              ),
              actions: [
                TextButton(
                  onPressed: isSeeding
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSeeding
                      ? null
                      : () async {
                          setDialogState(() => isSeeding = true);
                          try {
                            final demoState = DemoDataSeeder.createDemoState();
                            await widget.hotelController.seedDemoData(demoState);
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, true);
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              setDialogState(() => isSeeding = false);
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text('Unable to load demo data: $e'),
                                ),
                              );
                            }
                          }
                        },
                  child: isSeeding
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              scheme.onPrimary,
                            ),
                          ),
                        )
                      : const Text('Load Demo Data'),
                ),
              ],
            );
          },
        ),
      );

      if (success == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sample demo records loaded successfully.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _operating = false);
    }
  }

  Future<void> _clearAllData() async {
    if (_operating) return;
    setState(() => _operating = true);
    try {
      var isClearing = false;
      final success = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Clear All Data?'),
            content: const Text(
              'Are you sure you want to delete all rooms, guests, and booking history? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: isClearing
                    ? null
                    : () => Navigator.pop(dialogContext, false),
                child: const Text('Keep Data'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFBA1A1A),
                  foregroundColor: Colors.white,
                ),
                onPressed: isClearing
                    ? null
                    : () async {
                        setDialogState(() => isClearing = true);
                        try {
                          await widget.hotelController.clearAllData();
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext, true);
                          }
                        } catch (e) {
                          if (dialogContext.mounted) {
                            setDialogState(() => isClearing = false);
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text('Unable to clear records: $e'),
                              ),
                            );
                          }
                        }
                      },
                child: isClearing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Delete Everything'),
              ),
            ],
          ),
        ),
      );

      if (success == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All hotel records have been cleared.')),
        );
      }
    } finally {
      if (mounted) setState(() => _operating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListenableBuilder(
              listenable: Listenable.merge([
                widget.controller,
                widget.hotelController,
              ]),
              builder: (context, _) {
                final hotelState = widget.hotelController.state;
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Section 1: Hotel Profile
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _sectionHeader(
                            theme,
                            scheme,
                            title: 'Hotel Profile',
                            subtitle: 'Business identity and stay policies',
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _editProfile,
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Edit'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: scheme.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            _profileRow(
                              context,
                              icon: Icons.apartment_outlined,
                              label: 'Hotel Name',
                              value: _profile.name,
                              isTitle: true,
                            ),
                            const Divider(height: 20),
                            _profileRow(
                              context,
                              icon: Icons.phone_outlined,
                              label: 'Contact',
                              value: _profile.phone,
                            ),
                            const Divider(height: 20),
                            _profileRow(
                              context,
                              icon: Icons.location_on_outlined,
                              label: 'Address',
                              value: _profile.address,
                            ),
                            const Divider(height: 20),
                            _profileRow(
                              context,
                              icon: Icons.schedule_outlined,
                              label: 'Timings',
                              value:
                                  'Check-in ${_profile.checkInTime} • Check-out ${_profile.checkOutTime}',
                            ),
                            const Divider(height: 20),
                            _profileRow(
                              context,
                              icon: Icons.payments_outlined,
                              label: 'Currency',
                              value: 'PKR (₨) • Pakistani Rupee',
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 20),

                    // Section 2: Storage & Health
                    _sectionHeader(
                      theme,
                      scheme,
                      title: 'Storage & Health',
                      subtitle: 'Local embedded database status and counts',
                    ),
                    const SizedBox(height: 14),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: scheme.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: scheme.secondaryContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.verified_outlined,
                                    color: scheme.onSecondaryContainer,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Offline Database Active',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Hive CE 2.20.1 embedded storage',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF007F5F)
                                        .withAlpha(30),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'HEALTHY',
                                    style: TextStyle(
                                      color: Color(0xFF007F5F),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _dbStat(
                                  context,
                                  'Rooms',
                                  hotelState.rooms.length.toString(),
                                ),
                                _dbStat(
                                  context,
                                  'Guests',
                                  hotelState.guests.length.toString(),
                                ),
                                _dbStat(
                                  context,
                                  'Bookings',
                                  hotelState.bookings.length.toString(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 20),

                    // Section 3: Appearance
                    _sectionHeader(
                      theme,
                      scheme,
                      title: 'Appearance',
                      subtitle:
                          'Choose how the application looks on this device.',
                    ),
                    const SizedBox(height: 16),
                    for (final option
                        in <(ThemeMode, String, String, IconData)>[
                          (
                            ThemeMode.system,
                            'System default',
                            'Automatically matches your device theme',
                            Icons.brightness_auto_outlined,
                          ),
                          (
                            ThemeMode.light,
                            'Light theme',
                            'Clean mint and emerald surfaces',
                            Icons.light_mode_outlined,
                          ),
                          (
                            ThemeMode.dark,
                            'Dark theme',
                            'Deep forest tones for low light',
                            Icons.dark_mode_outlined,
                          ),
                        ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Semantics(
                          selected: widget.controller.mode == option.$1,
                          child: Material(
                            color: scheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: widget.controller.mode == option.$1
                                    ? scheme.primary
                                    : scheme.outlineVariant,
                                width: widget.controller.mode == option.$1
                                    ? 1.5
                                    : 1,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              leading: Icon(
                                option.$4,
                                color: widget.controller.mode == option.$1
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant,
                              ),
                              title: Text(
                                option.$2,
                                style: TextStyle(
                                  fontWeight:
                                      widget.controller.mode == option.$1
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(option.$3),
                              trailing: widget.controller.mode == option.$1
                                  ? Icon(
                                      Icons.check_circle,
                                      color: scheme.primary,
                                    )
                                  : null,
                              onTap:
                                  widget.controller.saving ||
                                      widget.controller.loading
                                  ? null
                                  : () async {
                                      await widget.controller.select(option.$1);
                                    },
                            ),
                          ),
                        ),
                      ),

                    if (widget.controller.saving) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                    ],

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 20),

                    // Section 4: Data Management
                    _sectionHeader(
                      theme,
                      scheme,
                      title: 'Data Management',
                      subtitle: 'Populate sample data or reset local records',
                    ),
                    const SizedBox(height: 14),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: scheme.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.dataset_outlined),
                              title: const Text('Load Demo Records'),
                              subtitle: const Text(
                                'Populate sample rooms, guests, and stays',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: _operating ? null : _seedDemoData,
                            ),
                            const Divider(),
                            ListTile(
                              leading: Icon(
                                Icons.delete_sweep_outlined,
                                color: scheme.error,
                              ),
                              title: Text(
                                'Clear All Records',
                                style: TextStyle(
                                  color: scheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: const Text(
                                'Permanently wipe all rooms, guests, and bookings',
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: scheme.error,
                              ),
                              onTap: _operating ? null : _clearAllData,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 20),

                    // Section 5: About
                    _sectionHeader(
                      theme,
                      scheme,
                      title: 'About App',
                      subtitle: 'System identity and specifications',
                    ),
                    const SizedBox(height: 14),
                    Card(
                      elevation: 0,
                      color: scheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: scheme.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hotel Management System',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Version 1.0.0 • Offline-first hotel manager',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Application ID: com.mudasir.hotelmanagementsystem',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(
    ThemeData theme,
    ColorScheme scheme, {
    required String title,
    required String subtitle,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: scheme.primary,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
    ],
  );

  Widget _profileRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isTitle = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: scheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: isTitle ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _dbStat(BuildContext context, String label, String count) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      children: [
        Text(
          count,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: scheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _EditHotelProfileDialog extends StatefulWidget {
  const _EditHotelProfileDialog({required this.profile});

  final HotelProfile profile;

  @override
  State<_EditHotelProfileDialog> createState() =>
      _EditHotelProfileDialogState();
}

class _EditHotelProfileDialogState extends State<_EditHotelProfileDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _checkInCtrl;
  late final TextEditingController _checkOutCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.name);
    _phoneCtrl = TextEditingController(text: widget.profile.phone);
    _addressCtrl = TextEditingController(text: widget.profile.address);
    _checkInCtrl = TextEditingController(text: widget.profile.checkInTime);
    _checkOutCtrl = TextEditingController(text: widget.profile.checkOutTime);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _checkInCtrl.dispose();
    _checkOutCtrl.dispose();
    super.dispose();
  }

  void _onSave() {
    final newProfile = HotelProfile(
      name: _nameCtrl.text.trim().isEmpty
          ? HotelProfile.defaultProfile.name
          : _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty
          ? HotelProfile.defaultProfile.phone
          : _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty
          ? HotelProfile.defaultProfile.address
          : _addressCtrl.text.trim(),
      checkInTime: _checkInCtrl.text.trim().isEmpty
          ? HotelProfile.defaultProfile.checkInTime
          : _checkInCtrl.text.trim(),
      checkOutTime: _checkOutCtrl.text.trim().isEmpty
          ? HotelProfile.defaultProfile.checkOutTime
          : _checkOutCtrl.text.trim(),
    );
    Navigator.pop(context, newProfile);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Hotel Profile'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Hotel Name',
                  prefixIcon: Icon(Icons.apartment_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Contact Phone',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Address / Location',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _checkInCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Check-In Time',
                        prefixIcon: Icon(Icons.login),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _checkOutCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Check-Out Time',
                        prefixIcon: Icon(Icons.logout),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _onSave,
          child: const Text('Save Profile'),
        ),
      ],
    );
  }
}

