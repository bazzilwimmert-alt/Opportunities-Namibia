import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'paywall_screen.dart';
import 'parental_controls_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user;
    final sub = user?.subscription;
    final entitled = state.isEntitled;

    String statusLabel;
    Color statusColor;
    if (entitled) {
      statusLabel = 'Active';
      statusColor = BaxColors.primary;
    } else if (sub?.status == 'PAST_DUE') {
      statusLabel = 'Payment due — streaming locked';
      statusColor = Colors.orangeAccent;
    } else {
      statusLabel = 'Inactive';
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
            const Text('Subscription',
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
                      Text(statusLabel,
                          style: TextStyle(
                              color: statusColor, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(state.appInfo?.priceDisplay ?? 'N\$200/month',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900)),
                  if (sub?.currentPeriodEnd != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      entitled
                          ? 'Renews on ${DateFormat.yMMMd().format(sub!.currentPeriodEnd!)}'
                          : 'Expired ${DateFormat.yMMMd().format(sub!.currentPeriodEnd!)}',
                      style: TextStyle(color: BaxColors.muted),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (!entitled)
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PaywallScreen())),
                      child: Text(sub?.status == 'PAST_DUE'
                          ? 'Renew subscription'
                          : 'Subscribe now'),
                    )
                  else
                    OutlinedButton(
                      onPressed: () async {
                        await state.cancelSubscription();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Subscription set to cancel at period end')),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: BaxColors.text,
                        side: const BorderSide(color: BaxColors.muted),
                      ),
                      child: const Text('Cancel subscription'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                  color: BaxColors.card,
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: const Text('Parental controls'),
                subtitle: Text(
                  (user?.parentalControlsEnabled ?? false)
                      ? 'On • limit ${(user?.maxContentRating ?? 18) == 0 ? 'All ages' : '${user?.maxContentRating}+'}'
                          '${(user?.parentalPinSet ?? false) ? ' • PIN set' : ''}'
                      : 'Off',
                  style: TextStyle(color: BaxColors.muted),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ParentalControlsScreen())),
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
                'Bax • Operated in Namibia • Prices in N\$ (NAD)\n'
                'Support: ${state.appInfo?.supportEmail ?? 'support@bax.tv'}',
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
