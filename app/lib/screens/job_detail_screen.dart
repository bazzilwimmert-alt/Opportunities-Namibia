import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/watermark.dart';

class JobDetailScreen extends StatefulWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  Job? _job;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await context.read<AppState>().api.get('/api/jobs/${widget.jobId}');
      _job = Job.fromJson(res['job']);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final wmLabel = '${state.user?.email ?? ''}  ';
    return Scaffold(
      appBar: AppBar(title: const Text('Vacancy')),
      body: SafeArea(
        child: Watermark(
          label: wmLabel,
          child: _body(),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    final job = _job!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const NoScreenshotNotice(),
        const SizedBox(height: 12),
        Text(job.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text('${job.company} • ${job.location}',
            style: TextStyle(color: BaxColors.muted, fontSize: 15)),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _tag(job.category, BaxColors.accent),
            _tag(job.typeLabel, BaxColors.card),
            _tag(job.isUnskilled ? 'Unskilled' : 'Skilled',
                job.isUnskilled ? Colors.orange.shade800 : Colors.teal.shade700),
            if (job.salary != null) _tag(job.salary!, BaxColors.card),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Description',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(job.description ?? '',
            style: const TextStyle(fontSize: 15, height: 1.5)),
        const SizedBox(height: 24),
        const Text('How to apply',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        _applyRow(Icons.link, job.applyUrl),
        _applyRow(Icons.email_outlined, job.applyEmail),
        _applyRow(Icons.phone, job.contact),
        if (job.applyUrl == null && job.applyEmail == null && job.contact == null)
          Text('Contact details were not provided for this vacancy.',
              style: TextStyle(color: BaxColors.muted)),
      ],
    );
  }

  Widget _applyRow(IconData icon, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: BaxColors.primary),
          const SizedBox(width: 10),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}
