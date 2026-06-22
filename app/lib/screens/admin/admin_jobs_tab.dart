import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../theme.dart';

class AdminJobsTab extends StatefulWidget {
  final ApiClient api;
  const AdminJobsTab({super.key, required this.api});

  @override
  State<AdminJobsTab> createState() => _AdminJobsTabState();
}

class _AdminJobsTabState extends State<AdminJobsTab> {
  List<dynamic> _jobs = [];
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
      final res = await widget.api.get('/api/admin/jobs');
      _jobs = res['jobs'] as List;
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

  Future<void> _editJob([Map<String, dynamic>? job]) async {
    final title = TextEditingController(text: job?['title'] ?? '');
    final company = TextEditingController(text: job?['company'] ?? '');
    final location = TextEditingController(text: job?['location'] ?? 'Windhoek');
    final category = TextEditingController(text: job?['category'] ?? 'General');
    final salary = TextEditingController(text: job?['salary'] ?? '');
    final desc = TextEditingController(text: job?['description'] ?? '');
    final applyEmail = TextEditingController(text: job?['applyEmail'] ?? '');
    final applyUrl = TextEditingController(text: job?['applyUrl'] ?? '');
    final contact = TextEditingController(text: job?['contact'] ?? '');
    String type = job?['type'] ?? 'FULL_TIME';
    String skill = job?['skillLevel'] ?? 'SKILLED';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: BaxColors.surface,
          title: Text(job == null ? 'Add vacancy' : 'Edit vacancy'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(title, 'Job title'),
                _field(company, 'Company'),
                _field(location, 'Location'),
                _field(category, 'Category (e.g. IT, Trades)'),
                _field(salary, 'Salary (optional)'),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: type,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: const [
                          DropdownMenuItem(value: 'FULL_TIME', child: Text('Full-time')),
                          DropdownMenuItem(value: 'PART_TIME', child: Text('Part-time')),
                          DropdownMenuItem(value: 'CONTRACT', child: Text('Contract')),
                          DropdownMenuItem(value: 'TEMPORARY', child: Text('Temporary')),
                          DropdownMenuItem(value: 'INTERNSHIP', child: Text('Internship')),
                        ],
                        onChanged: (v) => setLocal(() => type = v ?? 'FULL_TIME'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: skill,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Skill'),
                        items: const [
                          DropdownMenuItem(value: 'SKILLED', child: Text('Skilled')),
                          DropdownMenuItem(value: 'UNSKILLED', child: Text('Unskilled')),
                        ],
                        onChanged: (v) => setLocal(() => skill = v ?? 'SKILLED'),
                      ),
                    ),
                  ],
                ),
                _field(desc, 'Description', lines: 3),
                _field(applyEmail, 'Apply email (optional)'),
                _field(applyUrl, 'Apply URL (optional)'),
                _field(contact, 'Contact phone (optional)'),
              ],
            ),
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

    if (ok != true) return;
    final body = {
      'title': title.text.trim(),
      'company': company.text.trim(),
      'location': location.text.trim(),
      'category': category.text.trim(),
      'salary': salary.text.trim(),
      'type': type,
      'skillLevel': skill,
      'description': desc.text.trim(),
      'applyEmail': applyEmail.text.trim(),
      'applyUrl': applyUrl.text.trim(),
      'contact': contact.text.trim(),
    };
    if (job == null) {
      await _run(() => widget.api.post('/api/admin/jobs', body));
    } else {
      await _run(() => widget.api.patch('/api/admin/jobs/${job['id']}', body));
    }
  }

  Widget _field(TextEditingController c, String hint, {int lines = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          maxLines: lines,
          decoration: InputDecoration(hintText: hint),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editJob(),
        backgroundColor: BaxColors.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Add vacancy'),
      ),
      body: _list(),
    );
  }

  Widget _list() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _jobs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final j = _jobs[i] as Map<String, dynamic>;
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: BaxColors.card,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(j['title'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${j['company']} • ${j['location']} • ${j['category']}',
                          style: TextStyle(color: BaxColors.muted, fontSize: 12)),
                      Text('${j['skillLevel']} • ${j['source']}',
                          style: TextStyle(color: BaxColors.muted, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _editJob(j),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () =>
                      _run(() => widget.api.delete('/api/admin/jobs/${j['id']}')),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
