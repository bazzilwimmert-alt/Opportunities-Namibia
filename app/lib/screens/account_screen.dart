import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'paywall_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user;
    final membership = user?.membership;
    final access = state.hasAccess;

    String statusLabel;
    Color statusColor;
    if (access) {
      statusLabel = 'Active member';
      statusColor = BaxColors.primary;
    } else if (membership?.isPending ?? false) {
      statusLabel = 'Payment pending confirmation';
      statusColor = Colors.orangeAccent;
    } else if (membership?.status == 'EXPIRED') {
      statusLabel = 'Membership expired';
      statusColor = Colors.orangeAccent;
    } else {
      statusLabel = 'Not a member';
      statusColor = BaxColors.muted;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: BaxColors.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: BaxColors.accent,
                    child: Text(
                      (user?.fullName.isNotEmpty ?? false)
                          ? user!.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.fullName ?? '',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                        Text(user?.email ?? '',
                            style: TextStyle(color: BaxColors.muted)),
                        if (user?.isAdmin ?? false)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: BaxColors.accent,
                                borderRadius: BorderRadius.circular(6)),
                            child: const Text('ADMIN',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w800)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Membership',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: BaxColors.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.circle, size: 12, color: statusColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(statusLabel,
                            style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(state.appInfo?.priceDisplay ?? 'N\$200 / 6 months',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900)),
                  if (membership?.currentPeriodEnd != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      access
                          ? 'Access until ${DateFormat.yMMMd().format(membership!.currentPeriodEnd!)}'
                          : 'Expired ${DateFormat.yMMMd().format(membership!.currentPeriodEnd!)}',
                      style: TextStyle(color: BaxColors.muted),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (!access)
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PaywallScreen())),
                      child: Text((membership?.isPending ?? false)
                          ? 'View payment status'
                          : 'Become a member'),
                    )
                  else
                    OutlinedButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PaywallScreen())),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: BaxColors.text,
                        side: const BorderSide(color: BaxColors.muted),
                      ),
                      child: const Text('Renew / extend membership'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.no_photography, color: Colors.redAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Screenshots and screen recording of vacancies are '
                      'prohibited. All listings are watermarked with your '
                      'account; a fine applies if leaked screenshots are detected.',
                      style: TextStyle(color: BaxColors.text, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log out'),
              onTap: () => state.logout(),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Opportunities Namibia • Prices in N\$ (NAD)\n'
                'Support: ${state.appInfo?.supportEmail ?? 'support@opportunities.na'}',
                textAlign: TextAlign.center,
                style: TextStyle(color: BaxColors.muted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
