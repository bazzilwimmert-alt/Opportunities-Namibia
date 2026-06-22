import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models.dart';
import '../theme.dart';

class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key});

  Future<void> _addProfile(BuildContext context) async {
    final state = context.read<AppState>();
    final controller = TextEditingController();
    final headline = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BaxColors.surface,
        title: const Text('New profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Profile name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: headline,
              decoration: const InputDecoration(
                  hintText: 'Headline e.g. "Electrician, 5 yrs" (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Create')),
        ],
      ),
    );
    if (result == true && controller.text.trim().isNotEmpty) {
      try {
        await state.createProfile(controller.text.trim(),
            headline: headline.text.trim());
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profiles = state.user?.profiles ?? [];
    final max = state.appInfo?.maxProfiles ?? 2;

    return Scaffold(
      appBar: AppBar(title: const Text('Profiles')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('You can create up to $max profiles per account.',
                  style: TextStyle(color: BaxColors.muted)),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.95,
                  children: [
                    ...profiles.map((p) => _profileTile(context, state, p)),
                    if (profiles.length < max) _addTile(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileTile(BuildContext context, AppState state, Profile p) {
    final isActive = state.activeProfile?.id == p.id;
    return GestureDetector(
      onTap: () => state.setActiveProfile(p),
      child: Container(
        decoration: BoxDecoration(
          color: BaxColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isActive ? BaxColors.primary : Colors.transparent,
              width: 2),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: BaxColors.accent,
                    child: Text(
                      p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          fontSize: 30, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(p.name,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (p.headline != null && p.headline!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(p.headline!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: BaxColors.muted, fontSize: 12)),
                    ),
                ],
              ),
            ),
            if (state.user!.profiles.length > 1)
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: BaxColors.muted,
                  onPressed: () => state.deleteProfile(p.id),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _addTile(BuildContext context) {
    return GestureDetector(
      onTap: () => _addProfile(context),
      child: DottedBorderBox(
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 36, color: BaxColors.muted),
              SizedBox(height: 8),
              Text('Add profile', style: TextStyle(color: BaxColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

class DottedBorderBox extends StatelessWidget {
  final Widget child;
  const DottedBorderBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BaxColors.muted.withValues(alpha: 0.4)),
      ),
      child: child,
    );
  }
}
