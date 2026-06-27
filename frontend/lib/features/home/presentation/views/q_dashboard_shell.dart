import 'package:flutter/material.dart';
import 'package:qa_insight_hub/core/models/auth_session.dart';
import 'package:qa_insight_hub/core/services/api_service.dart';
import 'package:qa_insight_hub/core/services/session_storage.dart';
import 'package:qa_insight_hub/features/auth/presentation/views/login_view.dart';
import 'package:qa_insight_hub/features/dashboard/presentation/views/dashboard_view.dart';
import 'package:qa_insight_hub/features/master/presentation/views/master_data_view.dart';
import 'package:qa_insight_hub/features/reports/presentation/views/reports_view.dart';
import 'package:qa_insight_hub/features/review/presentation/views/review_view.dart';
import 'package:qa_insight_hub/features/submission/presentation/views/submission_view.dart';

class QDashboardShell extends StatefulWidget {
  const QDashboardShell({required this.session, super.key});

  final AuthSession session;

  @override
  State<QDashboardShell> createState() => _QDashboardShellState();
}

class _QDashboardShellState extends State<QDashboardShell> {
  final ApiService _apiService = ApiService();
  final SessionStorage _sessionStorage = SessionStorage();
  int _selectedIndex = 0;

  late final List<_NavConfig> _navItems = _buildNavItems();

  List<_NavConfig> _buildNavItems() {
    final role = widget.session.role;
    final items = <_NavConfig>[
      _NavConfig(
        label: 'Dashboard',
        icon: Icons.analytics_outlined,
        builder: () => DashboardView(session: widget.session, apiService: _apiService),
      ),
      if (role == 'assembly_user' || role == 'admin')
        _NavConfig(
          label: 'Submission',
          icon: Icons.upload_file_outlined,
          builder: () => SubmissionView(session: widget.session, apiService: _apiService),
        ),
      if (role == 'qa_representative' || role == 'admin')
        _NavConfig(
          label: 'Review',
          icon: Icons.fact_check_outlined,
          builder: () => ReviewView(session: widget.session, apiService: _apiService),
        ),
      if (role == 'assembly_user' ||
          role == 'qa_representative' ||
          role == 'management_viewer' ||
          role == 'admin')
        _NavConfig(
          label: 'Master',
          icon: Icons.dataset_outlined,
          builder: () => MasterDataView(session: widget.session, apiService: _apiService),
        ),
      _NavConfig(
        label: 'Reports',
        icon: Icons.summarize_outlined,
        builder: () => ReportsView(session: widget.session, apiService: _apiService),
      ),
    ];
    return items;
  }

  Future<void> _logout() async {
    try {
      await _apiService.logout(widget.session.token);
    } catch (_) {
      // Ignore API logout error and still clear local state.
    }
    await _sessionStorage.clearSession();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QA Insight Hub'),
        backgroundColor: const Color(0xFF123B8A),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                widget.session.roleName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        child: _navItems[_selectedIndex].builder(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        indicatorColor: const Color(0xFFBEE3FF),
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: _navItems
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NavConfig {
  const _NavConfig({
    required this.label,
    required this.icon,
    required this.builder,
  });

  final String label;
  final IconData icon;
  final Widget Function() builder;
}
