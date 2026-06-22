import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../theme.dart';

class AdminSourcesTab extends StatefulWidget {
  final ApiClient api;
  const AdminSourcesTab({super.key, required this.api});

  @override
  State<AdminSourcesTab> createState() => _AdminSourcesTabState();
}

class _AdminSourcesTabState extends State<AdminSourcesTab> {
  List<dynamic> _sources = [];
  bool _loading = true;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await widget.api.get('/api/admin/sources');
      _sources = res['sources'] as List;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _run(Future<void> Function() fn, {String? toast}) async {
    setState(() => _busy = true);
    try {
      await fn();
      await _load();
      if (mounted && toast != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(toast)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _fetchOne(String id) async {
    setState(() => _busy = true);
    try {
      final res = await widget.api.post('/api/admin/sources/$id/fetch', {});
      final created = (res['result']?['created']) ?? 0;
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fetched — $created new vacancies')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addSource() async {
    final name = TextEditingController();
    final url = TextEditingController();
    final category = TextEditingController(text: 'General');
    String type = 'RSS';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: BaxColors.surface,
          title: const Text('Add job source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(name, 'Source name'),
              _field(url, 'Feed URL (RSS/Atom)'),
              _field(category, 'Default category'),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'RSS', child: Text('RSS / Atom feed')),
                  DropdownMenuItem(
                      value: 'LINKEDIN', child: Text('LinkedIn (official API)')),
                ],
                onChanged: (v) => setLocal(() => type = v ?? 'RSS'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok == true) {
      await _run(
          () => widget.api.post('/api/admin/sources', {
                'name': name.text.trim(),
                'url': url.text.trim(),
                'category': category.text.trim(),
                'type': type,
                'enabled': true,
              }),
          toast: 'Source added');
    }
  }

  Widget _field(TextEditingController c, String hint) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
            controller: c, decoration: InputDecoration(hintText: hint)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSource,
        backgroundColor: BaxColors.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Add source'),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: BaxColors.card,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_download, color: BaxColors.primary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                      'Auto-ingestion pulls vacancies from enabled sources on a '
                      'schedule. Use "Fetch now" to run immediately.'),
                ),
                ElevatedButton(
                  onPressed: _busy
                      ? null
                      : () => _run(() => widget.api.post('/api/admin/ingest', {}),
                          toast: 'Ingestion run complete'),
                  child: const Text('Fetch all'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ..._sources.map((s) {
            final src = s as Map<String, dynamic>;
            final enabled = src['enabled'] == true;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
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
                        child: Text(src['name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      Switch(
                        value: enabled,
                        activeThumbColor: BaxColors.primary,
                        onChanged: _busy
                            ? null
                            : (v) => _run(() => widget.api.patch(
                                '/api/admin/sources/${src['id']}',
                                {'enabled': v})),
                      ),
                    ],
                  ),
                  Text('${src['type']} • ${src['category'] ?? ''}',
                      style: TextStyle(color: BaxColors.muted, fontSize: 12)),
                  Text(src['url'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: BaxColors.muted, fontSize: 12)),
                  if ((src['lastResult'] ?? '').toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Last: ${src['lastResult']}',
                          style: TextStyle(color: BaxColors.muted, fontSize: 11)),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: _busy ? null : () => _fetchOne(src['id']),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Fetch now'),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: _busy
                            ? null
                            : () => _run(() => widget.api
                                .delete('/api/admin/sources/${src['id']}')),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
