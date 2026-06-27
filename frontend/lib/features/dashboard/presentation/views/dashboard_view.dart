import 'package:flutter/material.dart';
import 'package:qa_insight_hub/core/models/auth_session.dart';
import 'package:qa_insight_hub/core/models/dashboard_model.dart';
import 'package:qa_insight_hub/core/services/api_service.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({
    required this.session,
    required this.apiService,
    super.key,
  });

  final AuthSession session;
  final ApiService apiService;

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  bool _isLoading = true;
  String? _error;
  DashboardKpis? _kpis;
  List<StatusBreakdown> _status = const [];
  List<ComparativeInsight> _comparative = const [];
  List<TrendPoint> _trends = const [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = widget.session.token;
      final result = await Future.wait([
        widget.apiService.fetchDashboardKpis(token),
        widget.apiService.fetchStatusBreakdown(token),
        widget.apiService.fetchComparativeInsights(token),
        widget.apiService.fetchTrendPoints(token),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _kpis = result[0] as DashboardKpis;
        _status = result[1] as List<StatusBreakdown>;
        _comparative = result[2] as List<ComparativeInsight>;
        _trends = result[3] as List<TrendPoint>;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
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
          _DashboardBanner(roleName: widget.session.roleName),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _KpiCard(
                title: 'Total Submissions',
                value: '${_kpis?.totalSubmissions ?? 0}',
                colorA: const Color(0xFF2B2D42),
                colorB: const Color(0xFF5F6CAF),
                icon: Icons.inventory_2_outlined,
              ),
              _KpiCard(
                title: 'Avg Audit Score',
                value: '${_kpis?.avgAuditScore.toStringAsFixed(2) ?? '0'}',
                colorA: const Color(0xFF05668D),
                colorB: const Color(0xFF00A896),
                icon: Icons.scoreboard_outlined,
              ),
              _KpiCard(
                title: 'Defect Rate %',
                value: '${_kpis?.defectRate.toStringAsFixed(2) ?? '0'}%',
                colorA: const Color(0xFF9C2C77),
                colorB: const Color(0xFFC74B50),
                icon: Icons.bug_report_outlined,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trend Chart',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: _trends.isEmpty
                        ? const Center(child: Text('No trend data available'))
                        : _TrendChart(points: _trends),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Approval Status Tracking',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _status
                        .map(
                          (item) => Chip(
                            label: Text('${item.status}: ${item.count}'),
                            backgroundColor: const Color(0xFFE0F4FF),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Comparative Analysis by BU',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ..._comparative.map(
                    (item) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.domain_outlined),
                      title: Text(item.name),
                      subtitle: Text('Submissions: ${item.submissions}'),
                      trailing: Text('Score ${item.avgScore.toStringAsFixed(2)}'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardBanner extends StatelessWidget {
  const _DashboardBanner({required this.roleName});

  final String roleName;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF03045E), Color(0xFF0077B6), Color(0xFF00B4D8)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const Icon(Icons.dashboard_customize_rounded, color: Colors.white, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Q Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Role: $roleName',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.colorA,
    required this.colorB,
    required this.icon,
  });

  final String title;
  final String value;
  final Color colorA;
  final Color colorB;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cardWidth = width > 900 ? 290.0 : (width - 44) / 2;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      width: width < 560 ? double.infinity : cardWidth,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colorA, colorB]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.points});

  final List<TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TrendPainter(points: points),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Wrap(
            spacing: 8,
            children: points
                .map((p) => Text(
                      p.label,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF4A5D78)),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({required this.points});

  final List<TrendPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = const Color(0xFFB8C6DB)
      ..strokeWidth = 1;

    canvas.drawLine(Offset(20, size.height - 25), Offset(size.width - 20, size.height - 25), axisPaint);
    canvas.drawLine(Offset(20, 16), Offset(20, size.height - 25), axisPaint);

    if (points.length < 2) {
      return;
    }

    final minScore = points.map((e) => e.avgAuditScore).reduce((a, b) => a < b ? a : b);
    final maxScore = points.map((e) => e.avgAuditScore).reduce((a, b) => a > b ? a : b);
    final scoreRange = (maxScore - minScore).abs() < 0.1 ? 1.0 : (maxScore - minScore);

    final chartWidth = size.width - 40;
    final chartHeight = size.height - 50;
    final stepX = chartWidth / (points.length - 1);

    final path = Path();
    final dotPaint = Paint()..color = const Color(0xFF0C63E7);
    final linePaint = Paint()
      ..color = const Color(0xFF0C63E7)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < points.length; i++) {
      final normalizedY = (points[i].avgAuditScore - minScore) / scoreRange;
      final dx = 20 + stepX * i;
      final dy = 16 + (chartHeight * (1 - normalizedY));

      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
      canvas.drawCircle(Offset(dx, dy), 4, dotPaint);
    }

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
