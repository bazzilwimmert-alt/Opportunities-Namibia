import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/bax_logo.dart';
import '../widgets/watermark.dart';
import 'paywall_screen.dart';
import 'job_detail_screen.dart';
import 'notifications_screen.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final _search = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _category;
  String? _skillLevel;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final state = context.read<AppState>();
      await Future.wait([
        state.loadJobs(
          q: _search.text.trim(),
          category: _category,
          skillLevel: _skillLevel,
        ),
        if (state.categories.isEmpty) state.loadCategories(),
        state.loadNotifications().catchError((_) {}),
      ]);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onJobTap(Job job, AppState state) {
    if (!state.hasAccess) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const PaywallScreen())).then((_) {
        if (mounted) _load();
      });
      return;
    }
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: job.id)));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final wmLabel = '${state.user?.email ?? ''}  ';
    return Scaffold(
      body: SafeArea(
        child: Watermark(
          label: wmLabel,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(child: BaxLogo(size: 34)),
                    Row(
                      children: [
                        Text('${state.jobs.length} vacancies',
                            style: TextStyle(
                                color: BaxColors.muted, fontSize: 12)),
                        _notificationBell(state),
                      ],
                    ),
                  ],
                ),
              ),
              const NoScreenshotNotice(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _load(),
                  decoration: InputDecoration(
                    hintText: 'Search jobs, companies, keywords…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.tune),
                      onPressed: _load,
                    ),
                  ),
                ),
              ),
              _filters(state),
              if (!state.hasAccess) _accessBanner(context, state),
              Expanded(child: _list(state, wmLabel)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notificationBell(AppState state) {
    return IconButton(
      tooltip: 'Notifications',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined),
          if (state.unreadCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                    color: Colors.red, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  '${state.unreadCount}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ),
        ],
      ),
      onPressed: () async {
        await Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()));
        if (mounted) {
          await context.read<AppState>().loadNotifications().catchError((_) {});
        }
      },
    );
  }

  Widget _filters(AppState state) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _chip('All', _category == null && _skillLevel == null, () {
            setState(() {
              _category = null;
              _skillLevel = null;
            });
            _load();
          }),
          _chip('Skilled', _skillLevel == 'SKILLED', () {
            setState(() => _skillLevel = _skillLevel == 'SKILLED' ? null : 'SKILLED');
            _load();
          }),
          _chip('Unskilled', _skillLevel == 'UNSKILLED', () {
            setState(() => _skillLevel = _skillLevel == 'UNSKILLED' ? null : 'UNSKILLED');
            _load();
          }),
          for (final c in state.categories)
            _chip(c, _category == c, () {
              setState(() => _category = _category == c ? null : c);
              _load();
            }),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: BaxColors.primary,
        labelStyle: TextStyle(
          color: selected ? Colors.black : BaxColors.text,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: BaxColors.card,
        side: BorderSide.none,
      ),
    );
  }

  Widget _accessBanner(BuildContext context, AppState state) {
    final pending = state.user?.membership?.isPending ?? false;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [BaxColors.accent, BaxColors.primary]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(pending ? Icons.hourglass_top : Icons.lock, color: Colors.black),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              pending
                  ? 'Payment received — waiting for admin to confirm your access.'
                  : 'Become a member for ${state.appInfo?.priceDisplay ?? 'N\$200 / 6 months'} to view full vacancy details and apply.',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, foregroundColor: Colors.white),
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PaywallScreen()));
              if (mounted) _load();
            },
            child: Text(pending ? 'Details' : 'Join'),
          ),
        ],
      ),
    );
  }

  Widget _list(AppState state, String wmLabel) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (state.jobs.isEmpty) {
      return Center(
        child: Text('No vacancies match your search.',
            style: TextStyle(color: BaxColors.muted)),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.jobs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _jobCard(state.jobs[i], state),
      ),
    );
  }

  Widget _jobCard(Job job, AppState state) {
    return GestureDetector(
      onTap: () => _onJobTap(job, state),
      child: Container(
        padding: const EdgeInsets.all(16),
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
                  child: Text(job.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                ),
                if (job.locked)
                  const Icon(Icons.lock, size: 16, color: BaxColors.muted),
              ],
            ),
            const SizedBox(height: 4),
            Text('${job.company} • ${job.location}',
                style: TextStyle(color: BaxColors.muted)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _tag(job.category, BaxColors.accent),
                _tag(job.typeLabel, BaxColors.surface),
                _tag(job.isUnskilled ? 'Unskilled' : 'Skilled',
                    job.isUnskilled ? Colors.orange.shade800 : Colors.teal.shade700),
                if (job.salary != null) _tag(job.salary!, BaxColors.surface),
              ],
            ),
            if (!job.locked && job.description != null) ...[
              const SizedBox(height: 10),
              Text(job.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: BaxColors.muted, fontSize: 13)),
            ],
            if (job.locked) ...[
              const SizedBox(height: 10),
              Text('Join to see full details and how to apply.',
                  style: TextStyle(
                      color: BaxColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
