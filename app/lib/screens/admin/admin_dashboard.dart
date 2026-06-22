import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import 'admin_overview_tab.dart';
import 'admin_payments_tab.dart';
import 'admin_users_tab.dart';
import 'admin_jobs_tab.dart';
import 'admin_sources_tab.dart';
import 'admin_settings_tab.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.read<AppState>().api;
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Console'),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: BaxColors.primary,
            labelColor: BaxColors.primary,
            unselectedLabelColor: BaxColors.muted,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Payments'),
              Tab(text: 'Users'),
              Tab(text: 'Vacancies'),
              Tab(text: 'Sources'),
              Tab(text: 'Settings'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            AdminOverviewTab(api: api),
            AdminPaymentsTab(api: api),
            AdminUsersTab(api: api),
            AdminJobsTab(api: api),
            AdminSourcesTab(api: api),
            AdminSettingsTab(api: api),
          ],
        ),
      ),
    );
  }
}
