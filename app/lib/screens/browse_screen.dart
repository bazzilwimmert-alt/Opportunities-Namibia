import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/bax_logo.dart';
import 'paywall_screen.dart';
import 'player_screen.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AppState>().loadCatalog();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onChannelTap(Channel c) async {
    final state = context.read<AppState>();
    if (!state.isEntitled) {
      await Navigator.push(context,
          MaterialPageRoute(builder: (_) => const PaywallScreen()));
      // Refresh entitlement/lock state after a possible subscription.
      if (mounted) await _load();
      return;
    }
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => PlayerScreen(channel: c)));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const BaxLogo(size: 36),
                      if (state.activeProfile != null)
                        Chip(
                          avatar: const Icon(Icons.person, size: 16),
                          label: Text(state.activeProfile!.name),
                          backgroundColor: BaxColors.card,
                          side: BorderSide.none,
                        ),
                    ],
                  ),
                ),
              ),
              if (!state.isEntitled)
                SliverToBoxAdapter(child: _paywallBanner(context, state)),
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SliverFillRemaining(
                  child: Center(child: Text(_error!)),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _sportSection(state.sports[i]),
                    childCount: state.sports.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paywallBanner(BuildContext context, AppState state) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [BaxColors.accent, BaxColors.primary]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock, color: Colors.black),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              state.user?.subscription?.status == 'PAST_DUE'
                  ? 'Your payment lapsed — streaming is locked. Renew for ${state.appInfo?.priceDisplay ?? 'N\$200/month'}.'
                  : 'Subscribe for ${state.appInfo?.priceDisplay ?? 'N\$200/month'} to unlock all channels.',
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, foregroundColor: Colors.white),
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PaywallScreen()));
              if (mounted) await _load();
            },
            child: const Text('Subscribe'),
          ),
        ],
      ),
    );
  }

  Widget _sportSection(Sport sport) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(sport.icon ?? '', style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(sport.name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: sport.channels.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _channelCard(sport.channels[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _channelCard(Channel c) {
    return GestureDetector(
      onTap: () => _onChannelTap(c),
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: BaxColors.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          BaxColors.accent.withValues(alpha: 0.6),
                          BaxColors.bg,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(14)),
                    ),
                    child: const Center(
                        child: Icon(Icons.sports, size: 44, color: Colors.white24)),
                  ),
                  if (c.isLive)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6)),
                        child: const Text('LIVE',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ),
                    ),
                  if (c.locked)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(Icons.lock, color: Colors.white, size: 18),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (c.description != null)
                    Text(c.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: BaxColors.muted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
