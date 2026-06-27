import 'package:flutter/material.dart';
import 'package:qa_insight_hub/core/models/auth_session.dart';
import 'package:qa_insight_hub/core/services/api_service.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({
    required this.session,
    required this.apiService,
    super.key,
  });

  final AuthSession session;
  final ApiService apiService;

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  bool _loading = true;
  bool _exportingPdf = false;
  bool _exportingExcel = false;
  bool _customLoading = false;
  String? _error;
  List<Map<String, dynamic>> _templates = const [];
  int? _customCount;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final templates = await widget.apiService.fetchReportTemplates(widget.session.token);
      if (!mounted) {
        return;
      }
      setState(() {
        _templates = templates;
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

  Future<void> _export(String format) async {
    setState(() {
      if (format == 'pdf') {
        _exportingPdf = true;
      } else {
        _exportingExcel = true;
      }
    });

    try {
      final bytes = await widget.apiService.downloadReportBytes(
        token: widget.session.token,
        format: format,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${format.toUpperCase()} report generated ($bytes bytes).')),
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
        setState(() {
          if (format == 'pdf') {
            _exportingPdf = false;
          } else {
            _exportingExcel = false;
          }
        });
      }
    }
  }

  Future<void> _generateCustomReport() async {
    setState(() => _customLoading = true);
    try {
      final response = await widget.apiService.generateCustomReport(widget.session.token);
      if (!mounted) {
        return;
      }
      setState(() {
        _customCount = response['count'] as int? ?? 0;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _customLoading = false);
      }
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
            const SizedBox(height: 10),
            FilledButton(onPressed: _loadTemplates, child: const Text('Retry')),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F4C5C), Color(0xFF2C7DA0), Color(0xFF61A5C2)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Report Module',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontSize: 22,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Standard Report Templates',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ..._templates.map(
                  (template) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.article_outlined),
                    title: Text(template['name'] as String? ?? '-'),
                    subtitle: Text('Template ID: ${template['id']}'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Export Reports',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _exportingPdf ? null : () => _export('pdf'),
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: Text(_exportingPdf ? 'Exporting...' : 'Export PDF'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _exportingExcel ? null : () => _export('excel'),
                        icon: const Icon(Icons.table_chart_outlined),
                        label: Text(_exportingExcel ? 'Exporting...' : 'Export Excel'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Custom Report Generation',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: _customLoading ? null : _generateCustomReport,
                  icon: const Icon(Icons.auto_graph_outlined),
                  label: Text(_customLoading ? 'Generating...' : 'Generate Custom Report'),
                ),
                if (_customCount != null) ...[
                  const SizedBox(height: 8),
                  Text('Custom report generated with $_customCount records.'),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
