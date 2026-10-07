import 'package:flutter/material.dart';

import '../../../application/customer_controller.dart';
import '../../../application/theme_controller.dart';

/// Traveler profile and appearance preferences screen.
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
    final nameCtrl = TextEditingController(text: profile?.name ?? '');
    final phoneCtrl = TextEditingController(text: profile?.phone ?? '');
    final emailCtrl = TextEditingController(text: profile?.email ?? '');

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Traveler Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address (optional)',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final phone = phoneCtrl.text.trim();
              if (name.isNotEmpty && phone.isNotEmpty) {
                widget.customerController.updateProfile(
                  name: name,
                  phone: phone,
                  email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
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

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
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
                              hasProfile ? profile.phone : 'No contact saved yet',
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

                // App Info & Destination Stats
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
              ],
            ),
          ),
        );
      },
    );
  }
}
