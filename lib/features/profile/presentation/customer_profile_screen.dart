import 'package:flutter/material.dart';

import '../../../application/customer_controller.dart';
import '../../../application/theme_controller.dart';

/// Traveler profile, appearance preferences, and local data management screen.
class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({
    super.key,
    required this.customerController,
    required this.themeController,
  });

  final CustomerController customerController;
  final ThemeController themeController;

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  void _editProfileDialog() {
    final profile = widget.customerController.state.profile;
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: profile?.name ?? '');
    final phoneCtrl = TextEditingController(text: profile?.phone ?? '');
    final emailCtrl = TextEditingController(text: profile?.email ?? '');

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Traveler Details'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'e.g. Mudasir Unar',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Full name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    hintText: '0300 1234567',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Phone number is required';
                    }
                    if (val.trim().length < 7) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address (optional)',
                    hintText: 'traveler@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (val) {
                    if (val != null && val.trim().isNotEmpty && !val.contains('@')) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (profile != null)
            TextButton(
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                await widget.customerController.resetProfile();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile reset to Guest')),
                  );
                }
              },
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final name = nameCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                final email = emailCtrl.text.trim();

                await widget.customerController.updateProfile(
                  name: name,
                  phone: phone,
                  email: email.isEmpty ? null : email,
                );
                if (dialogCtx.mounted) {
                  Navigator.of(dialogCtx).pop();
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Traveler profile saved')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmResetData() {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Clear Local Bookings?'),
        content: const Text(
          'This will remove your test bookings and saved hotels from this device. The curated 12-hotel catalog will remain available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Keep Data'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await widget.customerController.clearCustomerData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Personal bookings and saved stays reset')),
                );
              }
            },
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.customerController,
        widget.themeController,
      ]),
      builder: (context, _) {
        final profile = widget.customerController.state.profile;
        final hasProfile = profile != null && profile.name.isNotEmpty;
        final bookingCount = widget.customerController.state.bookings.length;
        final savedCount = widget.customerController.state.savedHotelIds.length;

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 132),
              children: [
                Text(
                  'Profile & Settings',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your contact details and app preferences',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),

                // Traveler Profile Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2822) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2B3A30) : const Color(0xFFE2EBE5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.person_rounded,
                            size: 28,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasProfile ? profile.name : 'Guest Traveler',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hasProfile ? profile.phone : 'Tap to add contact info',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                            ),
                            if (hasProfile && (profile.email?.isNotEmpty ?? false)) ...[
                              Text(
                                profile.email!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _editProfileDialog,
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit Profile',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Activity Stats
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2822) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF2B3A30) : const Color(0xFFE2EBE5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.bookmark_added_outlined, size: 16, color: theme.colorScheme.primary),
                                const SizedBox(width: 6),
                                const Expanded(
                                  child: Text(
                                    'Bookings',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$bookingCount',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2822) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF2B3A30) : const Color(0xFFE2EBE5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.favorite_outline, size: 16, color: theme.colorScheme.primary),
                                const SizedBox(width: 6),
                                const Expanded(
                                  child: Text(
                                    'Saved Stays',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$savedCount',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Appearance Section
                Text(
                  'Appearance',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Material(
                  color: isDark ? const Color(0xFF1E2822) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark ? const Color(0xFF2B3A30) : const Color(0xFFE2EBE5),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          widget.themeController.mode == ThemeMode.system
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: theme.colorScheme.primary,
                        ),
                        title: const Text('System Default'),
                        subtitle: const Text('Match device light/dark appearance'),
                        onTap: () => widget.themeController.select(ThemeMode.system),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(
                          widget.themeController.mode == ThemeMode.light
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: theme.colorScheme.primary,
                        ),
                        title: const Text('Light'),
                        subtitle: const Text('Mint and emerald accents'),
                        onTap: () => widget.themeController.select(ThemeMode.light),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(
                          widget.themeController.mode == ThemeMode.dark
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: theme.colorScheme.primary,
                        ),
                        title: const Text('Dark'),
                        subtitle: const Text('Obsidian and deep emerald accents'),
                        onTap: () => widget.themeController.select(ThemeMode.dark),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Destination Coverage
                Text(
                  'Destination Coverage',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2822) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2B3A30) : const Color(0xFFE2EBE5),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Curated Destinations', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Karachi, Lahore, Islamabad, Murree',
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Catalog Accommodations', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${widget.customerController.catalog.hotels.length} hotels available',
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Offline Capability', style: TextStyle(fontSize: 13)),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Full local booking store',
                              textAlign: TextAlign.end,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Data Reset & Demo Disclosure
                Text(
                  'About & Data',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2822) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2B3A30) : const Color(0xFFE2EBE5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text(
                            'Demo Accommodation Explorer',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This application is a consumer hotel discovery demo showcasing multi-property reservations across Pakistan. All bookings and favorites persist locally on this device without requiring external accounts.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: _confirmResetData,
                        icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                        label: const Text('Reset Local Bookings & Saved'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
