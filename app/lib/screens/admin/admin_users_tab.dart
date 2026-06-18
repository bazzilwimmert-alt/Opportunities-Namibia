import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../theme.dart';

class AdminUsersTab extends StatefulWidget {
  final ApiClient api;
  const AdminUsersTab({super.key, required this.api});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  List<dynamic> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await widget.api.get('/api/admin/users');
      _users = res['users'] as List;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _action(Future<void> Function() fn) async {
    try {
      await fn();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final u = _users[i] as Map<String, dynamic>;
          final sub = u['subscription'] as Map<String, dynamic>?;
          final status = sub?['status'] ?? 'INACTIVE';
          final active = status == 'ACTIVE';
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: BaxColors.card,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u['fullName'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                          Text(u['email'] ?? '',
                              style: TextStyle(
                                  color: BaxColors.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                    _badge(u['role'], BaxColors.accent),
                    const SizedBox(width: 6),
                    _badge(status, active ? BaxColors.primary : Colors.orangeAccent),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () => _action(() => widget.api.post(
                          '/api/admin/users/${u['id']}/subscription',
                          {'action': active ? 'revoke' : 'grant'})),
                      icon: Icon(active ? Icons.lock : Icons.lock_open, size: 16),
                      label: Text(active ? 'Revoke access' : 'Grant access'),
                    ),
                    TextButton.icon(
                      onPressed: () => _action(() => widget.api.patch(
                          '/api/admin/users/${u['id']}',
                          {'role': u['role'] == 'ADMIN' ? 'USER' : 'ADMIN'})),
                      icon: const Icon(Icons.shield_outlined, size: 16),
                      label: Text(
                          u['role'] == 'ADMIN' ? 'Make user' : 'Make admin'),
                    ),
                    TextButton.icon(
                      onPressed: () => _action(() => widget.api.patch(
                          '/api/admin/users/${u['id']}', {
                        'status':
                            u['status'] == 'ACTIVE' ? 'SUSPENDED' : 'ACTIVE'
                      })),
                      icon: const Icon(Icons.block, size: 16),
                      label: Text(
                          u['status'] == 'ACTIVE' ? 'Suspend' : 'Unsuspend'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(text,
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.black)),
    );
  }
}
