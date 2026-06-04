import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/custom_text_field.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _darkMode = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _name.text = settings.adminName;
    _phone.text = settings.adminPhone;
    _darkMode = settings.darkMode;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await context.read<SettingsProvider>().save(
          adminName: _name.text.trim(),
          adminPhone: _phone.text.trim(),
          darkMode: _darkMode,
        );
    setState(() => _saved = true);
    Future.delayed(
        const Duration(seconds: 2), () => setState(() => _saved = false));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Admin Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Landlord / Admin Info',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Shown on generated receipts',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Your Name',
                    controller: _name,
                    prefixIcon: const Icon(Icons.person),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Your Phone Number',
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Appearance Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appearance',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Dark Mode'),
                    subtitle:
                        const Text('Use dark theme throughout the app'),
                    value: _darkMode,
                    onChanged: (v) => setState(() => _darkMode = v),
                    secondary: const Icon(Icons.dark_mode),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: _save,
            icon: _saved
                ? const Icon(Icons.check, color: Colors.white)
                : const Icon(Icons.save),
            label: Text(_saved ? 'Saved!' : 'Save Settings'),
          ),
          const SizedBox(height: 24),

          // App Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _infoRow('App', 'Rent Receipt Manager'),
                  _infoRow('Version', '1.0.0'),
                  _infoRow('Database', 'Firebase Firestore (Free Tier)'),
                  _infoRow('PDF', 'dart pdf package'),
                  _infoRow('Sharing', 'share_plus'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500)),
            ),
            Expanded(
                child: Text(value,
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant))),
          ],
        ),
      );
}
