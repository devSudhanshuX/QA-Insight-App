import 'package:flutter/material.dart';
import 'package:qa_insight_hub/core/models/auth_session.dart';
import 'package:qa_insight_hub/core/models/master_data.dart';
import 'package:qa_insight_hub/core/services/api_service.dart';

class MasterDataView extends StatefulWidget {
  const MasterDataView({
    required this.session,
    required this.apiService,
    super.key,
  });

  final AuthSession session;
  final ApiService apiService;

  @override
  State<MasterDataView> createState() => _MasterDataViewState();
}

class _MasterDataViewState extends State<MasterDataView> {
  bool _loading = true;
  String? _error;

  List<BusinessUnit> _businessUnits = const [];
  List<SiteMaster> _sites = const [];
  List<ReportingPeriod> _periods = const [];
  List<UserProfileLite> _users = const [];

  @override
  void initState() {
    super.initState();
    _loadMasters();
  }

  Future<void> _loadMasters() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = widget.session.token;
      final result = await Future.wait([
        widget.apiService.fetchBusinessUnits(token),
        widget.apiService.fetchSites(token),
        widget.apiService.fetchReportingPeriods(token),
        widget.apiService.fetchUserProfiles(token),
      ]);

      if (!mounted) {
        return;
      }
      setState(() {
        _businessUnits = result[0] as List<BusinessUnit>;
        _sites = result[1] as List<SiteMaster>;
        _periods = result[2] as List<ReportingPeriod>;
        _users = result[3] as List<UserProfileLite>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 8),
            FilledButton(onPressed: _loadMasters, child: const Text('Retry')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMasters,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF003049), Color(0xFF1D3557), Color(0xFF457B9D)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Master Data Center',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _MasterSection<BusinessUnit>(
            title: 'BU Master',
            items: _businessUnits,
            rowBuilder: (bu) => ListTile(
              leading: const Icon(Icons.account_tree_outlined),
              title: Text('${bu.code} - ${bu.name}'),
            ),
          ),
          const SizedBox(height: 10),
          _MasterSection<SiteMaster>(
            title: 'Site Master',
            items: _sites,
            rowBuilder: (site) => ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text('${site.code} - ${site.name}'),
              subtitle: Text('BU: ${site.businessUnitName}'),
            ),
          ),
          const SizedBox(height: 10),
          _MasterSection<ReportingPeriod>(
            title: 'Reporting Period Master',
            items: _periods,
            rowBuilder: (period) => ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: Text('Period ${period.label}'),
              subtitle: Text('Cut-off: ${period.cutoffDate}'),
            ),
          ),
          const SizedBox(height: 10),
          _MasterSection<UserProfileLite>(
            title: 'User Master',
            items: _users,
            rowBuilder: (user) => ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(user.username),
              subtitle: Text('${user.fullName} | ${user.email}'),
              trailing: Chip(label: Text(user.role)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MasterSection<T> extends StatelessWidget {
  const _MasterSection({
    required this.title,
    required this.items,
    required this.rowBuilder,
  });

  final String title;
  final List<T> items;
  final Widget Function(T item) rowBuilder;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        children: [
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('No records found.'),
            ),
          ...items.map(rowBuilder),
        ],
      ),
    );
  }
}
