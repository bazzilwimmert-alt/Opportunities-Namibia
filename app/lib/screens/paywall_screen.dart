import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final _reference = TextEditingController();
  final _payerPhone = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _reference.dispose();
    _payerPhone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AppState>().submitPayment(
            reference: _reference.text.trim(),
            payerPhone: _payerPhone.text.trim(),
          );
      if (mounted) _showSubmitted();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSubmitted() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BaxColors.surface,
        title: const Row(
          children: [
            Icon(Icons.hourglass_top, color: BaxColors.primary),
            SizedBox(width: 8),
            Text('Payment submitted'),
          ],
        ),
        content: const Text(
            'Thanks! We have recorded your payment. An admin will confirm it '
            'and unlock full access to all vacancies shortly.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final info = state.appInfo;
    final membership = state.user?.membership;
    final pending = membership?.isPending ?? false;
    final phone = info?.paymentPhone ?? '+264814680324';
    final price = info?.priceDisplay ?? 'N\$200 / 6 months';

    final perks = [
      'Full access to every Namibian vacancy — skilled and unskilled',
      'Search and filter by category, location and job type',
      'See company contact details and how to apply',
      'Up to 2 profiles per account',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Membership')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [BaxColors.accent, BaxColors.primary]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text('Membership',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(price,
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 30,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ...perks.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle,
                              color: BaxColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(p)),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
                if (pending) _pendingCard(membership) else _payCard(phone, price),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pendingCard(Membership? membership) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BaxColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BaxColors.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.hourglass_top, color: BaxColors.primary, size: 36),
          const SizedBox(height: 12),
          const Text('Payment awaiting confirmation',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            'We received your payment notification. An admin will verify it and '
            'grant your access. You will see all vacancies once confirmed.',
            textAlign: TextAlign.center,
            style: TextStyle(color: BaxColors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _payCard(String phone, String price) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BaxColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How to pay',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          _step('1', 'Send $price to the number below via mobile payment.'),
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: phone));
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment number copied')));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: BaxColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_android, color: BaxColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(phone,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                  const Icon(Icons.copy, size: 18, color: BaxColors.muted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _step('2', 'Enter your payment reference below and submit.'),
          const SizedBox(height: 8),
          _step('3', 'An admin confirms your payment and unlocks access.'),
          const SizedBox(height: 16),
          TextField(
            controller: _payerPhone,
            keyboardType: TextInputType.phone,
            decoration:
                const InputDecoration(hintText: 'Number you paid from (optional)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reference,
            decoration: const InputDecoration(
                hintText: 'Payment reference / note (optional)'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loading ? null : _submit,
            icon: _loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black))
                : const Icon(Icons.check),
            label: const Text('I have paid'),
          ),
          const SizedBox(height: 12),
          Text(
            'Access lasts 6 months and is automatically revoked when it lapses, '
            'until a new payment is confirmed. Prices in N\$ (NAD).',
            textAlign: TextAlign.center,
            style: TextStyle(color: BaxColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _step(String n, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: BaxColors.primary,
          child: Text(n,
              style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 12)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }
}
