import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _subscribe() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final state = context.read<AppState>();
    try {
      final checkout = await state.startCheckout();
      if (checkout['sandbox'] == true) {
        final confirmed = await _showPayTodaySandbox();
        if (confirmed == true) {
          await state.confirmSandboxPayment(checkout['paymentId']);
          if (mounted) {
            _showSuccess();
          }
        }
      } else {
        // Live mode: open checkoutUrl in browser (url_launcher in production).
        setState(() => _error =
            'Live PayToday checkout URL: ${checkout['checkoutUrl']}');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool?> _showPayTodaySandbox() {
    final price = context.read<AppState>().appInfo?.priceDisplay ?? 'N\$200';
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: BaxColors.surface,
        title: Row(
          children: [
            const Icon(Icons.payment, color: BaxColors.primary),
            const SizedBox(width: 8),
            const Text('PayToday'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sandbox checkout', style: TextStyle(color: BaxColors.muted)),
            const SizedBox(height: 8),
            Text('Pay $price to Bax',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text(
              'This simulates the PayToday hosted checkout. In production this '
              'redirects to PayToday to complete payment.',
              style: TextStyle(color: BaxColors.muted, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Pay now'),
          ),
        ],
      ),
    );
  }

  void _showSuccess() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BaxColors.surface,
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: BaxColors.primary),
            SizedBox(width: 8),
            Text('You\'re in!'),
          ],
        ),
        content: const Text(
            'Payment successful. All sports channels are now unlocked.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Start watching'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = context.watch<AppState>().appInfo;
    final perks = [
      'All sports channels — soccer, basketball, F1, tennis, cricket, rugby, NFL, swimming & more',
      'Live & on-demand streaming on any device',
      'Up to 2 profiles per account',
      'Cancel anytime',
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Subscribe')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
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
                      const Text('Bax Premium',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(info?.priceDisplay ?? 'N\$200/month',
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 34,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ...perks.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
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
                const SizedBox(height: 12),
                if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                  const SizedBox(height: 12),
                ],
                ElevatedButton.icon(
                  onPressed: _loading ? null : _subscribe,
                  icon: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.lock_open),
                  label: Text('Pay with PayToday — ${info?.priceDisplay ?? 'N\$200'}'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Secure payments via PayToday. Your streaming rights are '
                  'automatically revoked if a monthly payment is missed, and '
                  'restored as soon as you pay again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: BaxColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
