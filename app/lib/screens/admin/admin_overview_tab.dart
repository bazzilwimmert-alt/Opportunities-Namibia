import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../theme.dart';

class AdminOverviewTab extends StatefulWidget {
  final ApiClient api;
  const AdminOverviewTab({super.key, required this.api});

  @override
  State<AdminOverviewTab> createState() => _AdminOverviewTabState();
}

class _AdminOverviewTabState extends State<AdminOverviewTab> {
  Map<String, dynamic>? _stats;
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
      _stats = Map<String, dynamic>.from(await widget.api.get('/api/admin/stats'));
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    final s = _stats!;
    final revenue = (s['revenueCents'] ?? 0) / 100;
    final cards = [
      _StatCard('Users', '${s['users']}', Icons.people),
      _StatCard('Active members', '${s['activeMembers']}', Icons.verified),
      _StatCard('Pending payments', '${s['pendingClaims']}', Icons.hourglass_top),
      _StatCard('Vacancies', '${s['jobs']}', Icons.work),
      _StatCard('Sources', '${s['sources']}', Icons.cloud_download),
      _StatCard('Revenue', 'N\$${revenue.toStringAsFixed(0)}', Icons.payments),
    ];
    return RefreshIndicator(
      onRefresh: _load,
      child: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
        children: cards,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BaxColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: BaxColors.primary),
          Text(value,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          Text(label, style: TextStyle(color: BaxColors.muted)),
        ],
      ),
    );
  }
}
