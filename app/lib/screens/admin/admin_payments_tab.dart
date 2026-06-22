import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../theme.dart';

class AdminPaymentsTab extends StatefulWidget {
  final ApiClient api;
  const AdminPaymentsTab({super.key, required this.api});

  @override
  State<AdminPaymentsTab> createState() => _AdminPaymentsTabState();
}

class _AdminPaymentsTabState extends State<AdminPaymentsTab> {
  List<dynamic> _payments = [];
  bool _loading = true;
  String? _error;
  String _filter = 'PENDING';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final q = _filter == 'ALL' ? '' : '?status=$_filter';
      final res = await widget.api.get('/api/admin/payments$q');
      _payments = res['payments'] as List;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _act(String id, String action) async {
    try {
      await widget.api.post('/api/admin/payments/$id/$action', {});
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment $action${action == 'confirm' ? 'ed' : 'ed'}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              for (final f in ['PENDING', 'CONFIRMED', 'REJECTED', 'ALL'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: _filter == f,
                    onSelected: (_) {
                      setState(() => _filter = f);
                      _load();
                    },
                    selectedColor: BaxColors.primary,
                    labelStyle: TextStyle(
                        color: _filter == f ? Colors.black : BaxColors.text,
                        fontSize: 12),
                    backgroundColor: BaxColors.card,
                    side: BorderSide.none,
                  ),
                ),
            ],
          ),
        ),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_payments.isEmpty) {
      return Center(
          child: Text('No $_filter payments.',
              style: TextStyle(color: BaxColors.muted)));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _payments.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final p = _payments[i] as Map<String, dynamic>;
          final user = p['user'] as Map<String, dynamic>?;
          final status = p['status'] as String;
          final amount = (p['amountCents'] ?? 0) / 100;
          final pending = status == 'PENDING';
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
                      child: Text(user?['fullName'] ?? user?['email'] ?? '—',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    Text('N\$${amount.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                  ],
                ),
                Text(user?['email'] ?? '',
                    style: TextStyle(color: BaxColors.muted, fontSize: 12)),
                const SizedBox(height: 6),
                if ((p['payerPhone'] ?? '').toString().isNotEmpty)
                  Text('Paid from: ${p['payerPhone']}',
                      style: TextStyle(color: BaxColors.muted, fontSize: 12)),
                if ((p['reference'] ?? '').toString().isNotEmpty)
                  Text('Ref: ${p['reference']}',
                      style: TextStyle(color: BaxColors.muted, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: status == 'CONFIRMED'
                              ? BaxColors.primary
                              : status == 'REJECTED'
                                  ? Colors.redAccent
                                  : Colors.orangeAccent,
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(status,
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.black)),
                    ),
                    const Spacer(),
                    if (pending) ...[
                      TextButton(
                        onPressed: () => _act(p['id'], 'reject'),
                        child: const Text('Reject',
                            style: TextStyle(color: Colors.redAccent)),
                      ),
                      ElevatedButton(
                        onPressed: () => _act(p['id'], 'confirm'),
                        child: const Text('Confirm'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
