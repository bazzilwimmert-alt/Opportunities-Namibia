import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';

class ParentalControlsScreen extends StatefulWidget {
  const ParentalControlsScreen({super.key});

  @override
  State<ParentalControlsScreen> createState() => _ParentalControlsScreenState();
}

class _ParentalControlsScreenState extends State<ParentalControlsScreen> {
  static const ratings = [0, 6, 9, 12, 13, 16, 18];
  bool _busy = false;
  String? _error;

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askPin(String title) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '4-6 digit PIN'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user;
    final enabled = user?.parentalControlsEnabled ?? false;
    final pinSet = user?.parentalPinSet ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Parental controls')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (user?.isMinor ?? false)
              _infoBanner(
                  'This is a minor account, so parental controls are always on '
                  'and capped at age ${user?.age ?? ''}.'),
            Container(
              decoration: BoxDecoration(
                  color: BaxColors.card,
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  SwitchListTile(
                    value: enabled,
                    activeThumbColor: BaxColors.primary,
                    title: const Text('Enable parental controls'),
                    subtitle: const Text(
                        'Restrict channels above the chosen age rating'),
                    onChanged: (user?.isMinor ?? false)
                        ? null
                        : (v) => _run(() async {
                              String? pin;
                              if (pinSet) pin = await _askPin('Enter PIN');
                              await state.updateParentalSettings(
                                  enabled: v, pin: pin);
                            }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Maximum content rating',
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              'Channels rated above this are blocked'
              '${pinSet ? ' (a guardian PIN can override at play time)' : ''}.',
              style: TextStyle(color: BaxColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ratings.map((r) {
                final selected = user?.maxContentRating == r;
                return ChoiceChip(
                  label: Text(r == 0 ? 'All ages' : '$r+'),
                  selected: selected,
                  selectedColor: BaxColors.primary,
                  onSelected: enabled
                      ? (_) => _run(() async {
                            String? pin;
                            if (pinSet) pin = await _askPin('Enter PIN');
                            await state.updateParentalSettings(
                                maxContentRating: r, pin: pin);
                          })
                      : null,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text('Guardian PIN',
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              pinSet
                  ? 'A PIN is set. It is required to change these settings and to '
                      'override a block at play time.'
                  : 'Set a PIN to protect these settings and allow play-time overrides.',
              style: TextStyle(color: BaxColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                final messenger = ScaffoldMessenger.of(context);
                _run(() async {
                  String? current;
                  if (pinSet) {
                    current = await _askPin('Current PIN');
                    if (current == null) return;
                  }
                  final newPin = await _askPin(pinSet ? 'New PIN' : 'Set PIN');
                  if (newPin == null || newPin.isEmpty) return;
                  await state.setParentalPin(
                      currentPin: current, newPin: newPin);
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Guardian PIN updated')),
                  );
                });
              },
              child: Text(pinSet ? 'Change PIN' : 'Set PIN'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoBanner(String text) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: BaxColors.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(Icons.shield_outlined, color: BaxColors.accent),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
          ],
        ),
      );
}
