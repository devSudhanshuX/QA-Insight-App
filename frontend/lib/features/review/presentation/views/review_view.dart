import 'package:flutter/material.dart';
import 'package:qa_insight_hub/core/models/auth_session.dart';
import 'package:qa_insight_hub/core/models/submission_model.dart';
import 'package:qa_insight_hub/core/services/api_service.dart';

class ReviewView extends StatefulWidget {
  const ReviewView({
    required this.session,
    required this.apiService,
    super.key,
  });

  final AuthSession session;
  final ApiService apiService;

  @override
  State<ReviewView> createState() => _ReviewViewState();
}

class _ReviewViewState extends State<ReviewView> {
  bool _loading = true;
  String? _error;
  List<MonthlySubmission> _pending = const [];

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await widget.apiService.fetchPendingReviews(widget.session.token);
      if (!mounted) {
        return;
      }
      setState(() {
        _pending = data;
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

  Future<void> _reviewItem(MonthlySubmission item, String action) async {
    final remarksController = TextEditingController();

    final remarks = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add remarks (${action.replaceAll('_', ' ')})'),
        content: TextField(
          controller: remarksController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter review remarks',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = remarksController.text.trim();
              if (value.isEmpty) {
                return;
              }
              Navigator.of(context).pop(value);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    remarksController.dispose();
    if (remarks == null || remarks.isEmpty) {
      return;
    }

    try {
      await widget.apiService.submitReviewAction(
        token: widget.session.token,
        submissionId: item.id,
        action: action,
        remarks: remarks,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission ${item.acknowledgmentId} updated.')),
      );
      await _loadPending();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
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
            const SizedBox(height: 12),
            FilledButton(onPressed: _loadPending, child: const Text('Retry')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPending,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4A148C), Color(0xFF6A1B9A), Color(0xFFAB47BC)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Pending Submissions for Review',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_pending.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No pending submissions available.'),
              ),
            ),
          ..._pending.map(
            (item) => Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.siteName} | ${item.reportingPeriodLabel}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text('Ack: ${item.acknowledgmentId}'),
                    Text('Audit Score: ${item.auditScore.toStringAsFixed(2)}'),
                    Text('Defect Rate: ${item.defectRate.toStringAsFixed(2)}%'),
                    Text('Observations: ${item.observations}'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () => _reviewItem(item, 'reviewed'),
                          child: const Text('Mark Reviewed'),
                        ),
                        FilledButton(
                          onPressed: () => _reviewItem(item, 'approved'),
                          child: const Text('Approve'),
                        ),
                        FilledButton.tonal(
                          onPressed: () => _reviewItem(item, 'send_back'),
                          child: const Text('Send Back'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                          onPressed: () => _reviewItem(item, 'rejected'),
                          child: const Text('Reject'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
