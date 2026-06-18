import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import 'admin_overview_tab.dart';
import 'admin_users_tab.dart';
import 'admin_catalog_tab.dart';
import 'admin_settings_tab.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.read<AppState>().api;
    return DefaultTabController(
      length: 4,
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
              Tab(text: 'Users'),
              Tab(text: 'Sports & Channels'),
              Tab(text: 'Settings'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            AdminOverviewTab(api: api),
            AdminUsersTab(api: api),
            AdminCatalogTab(api: api),
            AdminSettingsTab(api: api),
          ],
        ),
      ),
    );
  }
}
