class DashboardKpis {
  const DashboardKpis({
    required this.totalSubmissions,
    required this.avgAuditScore,
    required this.defectRate,
  });

  final int totalSubmissions;
  final double avgAuditScore;
  final double defectRate;

  factory DashboardKpis.fromJson(Map<String, dynamic> json) {
    return DashboardKpis(
      totalSubmissions: _asInt(json['total_submissions']),
      avgAuditScore: _asDouble(json['avg_audit_score']),
      defectRate: _asDouble(json['defect_rate']),
    );
  }
}

class TrendPoint {
  const TrendPoint({
    required this.year,
    required this.month,
    required this.avgAuditScore,
  });

  final int year;
  final int month;
  final double avgAuditScore;

  String get label => '$month/$year';

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    return TrendPoint(
      year: _asInt(json['reporting_period__year']),
      month: _asInt(json['reporting_period__month']),
      avgAuditScore: _asDouble(json['avg_audit_score']),
    );
  }
}

class StatusBreakdown {
  const StatusBreakdown({required this.status, required this.count});

  final String status;
  final int count;

  factory StatusBreakdown.fromJson(Map<String, dynamic> json) {
    return StatusBreakdown(
      status: json['status'] as String? ?? '',
      count: _asInt(json['count']),
    );
  }
}

class ComparativeInsight {
  const ComparativeInsight({
    required this.name,
    required this.avgScore,
    required this.submissions,
  });

  final String name;
  final double avgScore;
  final int submissions;

  factory ComparativeInsight.fromJson(Map<String, dynamic> json) {
    return ComparativeInsight(
      name: json['name'] as String? ?? '',
      avgScore: _asDouble(json['avg_score']),
      submissions: _asInt(json['submissions']),
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
  }
  return 0;
}

double _asDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0;
  }
  return 0;
}
