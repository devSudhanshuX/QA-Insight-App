import 'package:flutter/material.dart';
import 'package:qa_insight_hub/core/models/auth_session.dart';
import 'package:qa_insight_hub/core/models/master_data.dart';
import 'package:qa_insight_hub/core/models/submission_model.dart';
import 'package:qa_insight_hub/core/services/api_service.dart';

class SubmissionView extends StatefulWidget {
  const SubmissionView({
    required this.session,
    required this.apiService,
    super.key,
  });

  final AuthSession session;
  final ApiService apiService;

  @override
  State<SubmissionView> createState() => _SubmissionViewState();
}

class _SubmissionViewState extends State<SubmissionView> {
  final _formKey = GlobalKey<FormState>();
  final _totalChecksController = TextEditingController();
  final _defectsController = TextEditingController();
  final _scoreController = TextEditingController();
  final _observationController = TextEditingController();

  bool _isSubmitting = false;
  bool _isLoadingMaster = true;
  String? _error;

  List<BusinessUnit> _businessUnits = const [];
  List<SiteMaster> _sites = const [];
  List<ReportingPeriod> _periods = const [];
  List<MonthlySubmission> _submissions = const [];

  BusinessUnit? _selectedBu;
  SiteMaster? _selectedSite;
  ReportingPeriod? _selectedPeriod;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _totalChecksController.dispose();
    _defectsController.dispose();
    _scoreController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingMaster = true;
      _error = null;
    });
    try {
      final token = widget.session.token;
      final result = await Future.wait([
        widget.apiService.fetchBusinessUnits(token),
        widget.apiService.fetchSites(token),
        widget.apiService.fetchReportingPeriods(token),
        widget.apiService.fetchSubmissions(token),
      ]);

      final businessUnits = result[0] as List<BusinessUnit>;
      final sites = result[1] as List<SiteMaster>;
      final periods = result[2] as List<ReportingPeriod>;
      final submissions = result[3] as List<MonthlySubmission>;

      if (!mounted) {
        return;
      }

      setState(() {
        _businessUnits = businessUnits;
        _sites = sites;
        _periods = periods;
        _submissions = submissions;
        _selectedBu = businessUnits.isNotEmpty ? businessUnits.first : null;
        _selectedSite = _filteredSites.isNotEmpty ? _filteredSites.first : null;
        _selectedPeriod = periods.isNotEmpty ? periods.first : null;
        _isLoadingMaster = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _isLoadingMaster = false;
      });
    }
  }

  List<SiteMaster> get _filteredSites {
    if (_selectedBu == null) {
      return _sites;
    }
    return _sites.where((site) => site.businessUnit == _selectedBu!.id).toList();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedBu == null || _selectedSite == null || _selectedPeriod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select BU, Site, and Reporting Period.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final submission = await widget.apiService.submitMonthlyData(
        token: widget.session.token,
        siteId: _selectedSite!.id,
        businessUnitId: _selectedBu!.id,
        reportingPeriodId: _selectedPeriod!.id,
        totalChecks: int.parse(_totalChecksController.text.trim()),
        defectsFound: int.parse(_defectsController.text.trim()),
        auditScore: double.parse(_scoreController.text.trim()),
        observations: _observationController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      _totalChecksController.clear();
      _defectsController.clear();
      _scoreController.clear();
      _observationController.clear();
      await _loadData();

      if (!mounted) {
        return;
      }
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Submission Acknowledged'),
          content: Text(
            'Data submitted successfully.\nAcknowledgment ID: ${submission.acknowledgmentId}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingMaster) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 8),
            FilledButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2A4D69), Color(0xFF4B86B4), Color(0xFFADCBE3)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Monthly QA Submission',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<BusinessUnit>(
                      key: ValueKey('bu-${_selectedBu?.id ?? 'none'}'),
                      initialValue: _selectedBu,
                      decoration: const InputDecoration(labelText: 'Business Unit'),
                      items: _businessUnits
                          .map(
                            (bu) => DropdownMenuItem(
                              value: bu,
                              child: Text('${bu.code} - ${bu.name}'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedBu = value;
                          final availableSites = _filteredSites;
                          _selectedSite = availableSites.isNotEmpty ? availableSites.first : null;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<SiteMaster>(
                      key: ValueKey('site-${_selectedSite?.id ?? 'none'}'),
                      initialValue: _selectedSite,
                      decoration: const InputDecoration(labelText: 'Site'),
                      items: _filteredSites
                          .map(
                            (site) => DropdownMenuItem(
                              value: site,
                              child: Text('${site.code} - ${site.name}'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _selectedSite = value),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<ReportingPeriod>(
                      key: ValueKey('period-${_selectedPeriod?.id ?? 'none'}'),
                      initialValue: _selectedPeriod,
                      decoration: const InputDecoration(labelText: 'Reporting Period'),
                      items: _periods
                          .map(
                            (period) => DropdownMenuItem(
                              value: period,
                              child: Text('${period.label} | Cutoff: ${period.cutoffDate}'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _selectedPeriod = value),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _totalChecksController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Total Checks (mandatory)'),
                      validator: _requiredNumberValidator,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _defectsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Defects Found (mandatory)'),
                      validator: _requiredNumberValidator,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _scoreController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Audit Score (mandatory)'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Audit Score is required';
                        }
                        final parsed = double.tryParse(value.trim());
                        if (parsed == null) {
                          return 'Enter a valid score';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _observationController,
                      minLines: 3,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Observations (mandatory)'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Observations are required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        icon: const Icon(Icons.send_outlined),
                        label: _isSubmitting
                            ? const Text('Submitting...')
                            : const Text('Submit Monthly QA Data'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Recent Submissions',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
          const SizedBox(height: 8),
          ..._submissions.take(6).map(
                (item) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text('${item.siteName} - ${item.reportingPeriodLabel}'),
                    subtitle: Text('Ack: ${item.acknowledgmentId}\nStatus: ${item.status}'),
                    trailing: Text('Score ${item.auditScore.toStringAsFixed(1)}'),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  String? _requiredNumberValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is mandatory';
    }
    if (int.tryParse(value.trim()) == null) {
      return 'Enter a valid number';
    }
    return null;
  }
}
