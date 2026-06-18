import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../theme.dart';

class AdminSettingsTab extends StatefulWidget {
  final ApiClient api;
  const AdminSettingsTab({super.key, required this.api});

  @override
  State<AdminSettingsTab> createState() => _AdminSettingsTabState();
}

class _AdminSettingsTabState extends State<AdminSettingsTab> {
  final Map<String, TextEditingController> _controllers = {};
  bool _loading = true;
  String? _error;

  // Editable platform settings the admin controls online.
  static const _knownKeys = ['appName', 'tagline', 'supportEmail'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await widget.api.get('/api/admin/settings');
      final settings = res['settings'] as List;
      final map = {for (final s in settings) s['key']: s['value']};
      for (final k in _knownKeys) {
        _controllers[k] = TextEditingController(text: map[k]?.toString() ?? '');
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save(String key) async {
    try {
      await widget.api.put('/api/admin/settings/$key',
          {'value': _controllers[key]!.text});
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$key updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Platform settings',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: BaxColors.text)),
        const SizedBox(height: 4),
        Text('Edit your platform branding live. Changes apply instantly.',
            style: TextStyle(color: BaxColors.muted)),
        const SizedBox(height: 20),
        ..._knownKeys.map((k) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_label(k),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _controllers[k])),
                      const SizedBox(width: 8),
                      ElevatedButton(
                          onPressed: () => _save(k),
                          child: const Text('Save')),
                    ],
                  ),
                ],
              ),
            )),
      ],
    );
  }

  String _label(String key) {
    switch (key) {
      case 'appName':
        return 'App name';
      case 'tagline':
        return 'Tagline';
      case 'supportEmail':
        return 'Support email';
      default:
        return key;
    }
  }
}
