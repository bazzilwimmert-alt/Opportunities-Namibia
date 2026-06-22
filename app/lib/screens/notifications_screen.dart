import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models.dart';
import '../theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
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
      await context.read<AppState>().loadNotifications();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'PAYMENT_CONFIRMED':
        return Icons.verified;
      case 'PAYMENT_REJECTED':
        return Icons.error_outline;
      case 'EXPIRING_SOON':
        return Icons.hourglass_top;
      case 'EXPIRED':
        return Icons.lock_clock;
      default:
        return Icons.notifications;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'PAYMENT_CONFIRMED':
        return Colors.teal.shade600;
      case 'PAYMENT_REJECTED':
      case 'EXPIRED':
        return Colors.red.shade400;
      case 'EXPIRING_SOON':
        return Colors.orange.shade700;
      default:
        return BaxColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () async {
                await context.read<AppState>().markAllNotificationsRead();
              },
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: _body(state),
    );
  }

  Widget _body(AppState state) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (state.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none, size: 48, color: BaxColors.muted),
            const SizedBox(height: 12),
            Text('No notifications yet.', style: TextStyle(color: BaxColors.muted)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _tile(state.notifications[i]),
      ),
    );
  }

  Widget _tile(NotificationItem n) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: n.read ? BaxColors.card : BaxColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: n.read
            ? null
            : Border.all(color: BaxColors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _colorFor(n.type).withValues(alpha: 0.18),
            child: Icon(_iconFor(n.type), size: 18, color: _colorFor(n.type)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 4),
                Text(n.body,
                    style: TextStyle(color: BaxColors.muted, fontSize: 13)),
              ],
            ),
          ),
          if (!n.read)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(left: 8, top: 4),
              decoration: const BoxDecoration(
                  color: BaxColors.primary, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}
