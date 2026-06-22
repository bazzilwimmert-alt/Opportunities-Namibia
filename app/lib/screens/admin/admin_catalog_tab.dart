import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../theme.dart';

class AdminCatalogTab extends StatefulWidget {
  final ApiClient api;
  const AdminCatalogTab({super.key, required this.api});

  @override
  State<AdminCatalogTab> createState() => _AdminCatalogTabState();
}

class _AdminCatalogTabState extends State<AdminCatalogTab> {
  List<dynamic> _sports = [];
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
      final res = await widget.api.get('/api/catalog/sports');
      _sports = res['sports'] as List;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _run(Future<void> Function() fn) async {
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

  Future<void> _addSport() async {
    final name = TextEditingController();
    final slug = TextEditingController();
    final icon = TextEditingController();
    final ok = await _formDialog('Add sport', [
      _field(name, 'Name'),
      _field(slug, 'Slug (e.g. golf)'),
      _field(icon, 'Icon emoji (optional)'),
    ]);
    if (ok == true) {
      await _run(() => widget.api.post('/api/admin/sports', {
            'name': name.text.trim(),
            'slug': slug.text.trim(),
            'icon': icon.text.trim(),
          }));
    }
  }

  Future<void> _addChannel(String sportId) async {
    final name = TextEditingController();
    final url = TextEditingController();
    final desc = TextEditingController();
    final minAge = TextEditingController(text: '0');
    final ok = await _formDialog('Add channel', [
      _field(name, 'Channel name'),
      _field(url, 'Stream URL (HLS/DASH/MP4)'),
      _field(desc, 'Description (optional)'),
      _field(minAge, 'Age rating (0-18, 0 = all ages)', number: true),
    ]);
    if (ok == true) {
      await _run(() => widget.api.post('/api/admin/channels', {
            'sportId': sportId,
            'name': name.text.trim(),
            'streamUrl': url.text.trim(),
            'description': desc.text.trim(),
            'minAge': int.tryParse(minAge.text.trim()) ?? 0,
          }));
    }
  }

  Future<void> _editChannel(Map<String, dynamic> c, String sportId) async {
    final name = TextEditingController(text: c['name']);
    final url = TextEditingController(text: c['streamUrl'] ?? '');
    final minAge = TextEditingController(text: '${c['minAge'] ?? 0}');
    final ok = await _formDialog('Edit channel', [
      _field(name, 'Channel name'),
      _field(url, 'Stream URL'),
      _field(minAge, 'Age rating (0-18, 0 = all ages)', number: true),
    ]);
    if (ok == true) {
      await _run(() => widget.api.patch('/api/admin/channels/${c['id']}', {
            'name': name.text.trim(),
            'streamUrl': url.text.trim(),
            'minAge': int.tryParse(minAge.text.trim()) ?? 0,
          }));
    }
  }

  Widget _field(TextEditingController c, String hint, {bool number = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
            controller: c,
            keyboardType: number ? TextInputType.number : null,
            decoration: InputDecoration(hintText: hint)),
      );

  Future<bool?> _formDialog(String title, List<Widget> fields) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BaxColors.surface,
        title: Text(title),
        content: Column(mainAxisSize: MainAxisSize.min, children: fields),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSport,
        backgroundColor: BaxColors.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Add sport'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _sports.length,
          itemBuilder: (_, i) {
            final s = _sports[i] as Map<String, dynamic>;
            final channels = (s['channels'] ?? []) as List;
            return Card(
              color: BaxColors.card,
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                leading: Text(s['icon'] ?? '',
                    style: const TextStyle(fontSize: 22)),
                title: Text(s['name'],
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${channels.length} channels',
                    style: TextStyle(color: BaxColors.muted)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () =>
                      _run(() => widget.api.delete('/api/admin/sports/${s['id']}')),
                ),
                children: [
                  ...channels.map((c) {
                    final ch = c as Map<String, dynamic>;
                    return ListTile(
                      dense: true,
                      title: Row(
                        children: [
                          Flexible(child: Text(ch['name'])),
                          if ((ch['minAge'] ?? 0) > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                  color: BaxColors.accent,
                                  borderRadius: BorderRadius.circular(4)),
                              child: Text('${ch['minAge']}+',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(ch['streamUrl'] ?? '',
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () => _editChannel(ch, s['id']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: () => _run(() => widget.api
                                .delete('/api/admin/channels/${ch['id']}')),
                          ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () => _addChannel(s['id']),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add channel'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
