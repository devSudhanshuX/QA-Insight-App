class MonthlySubmission {
  const MonthlySubmission({
    required this.id,
    required this.siteName,
    required this.businessUnitName,
    required this.reportingPeriodLabel,
    required this.totalChecks,
    required this.defectsFound,
    required this.auditScore,
    required this.defectRate,
    required this.status,
    required this.acknowledgmentId,
    required this.observations,
    this.reviewRemarks,
  });

  final int id;
  final String siteName;
  final String businessUnitName;
  final String reportingPeriodLabel;
  final int totalChecks;
  final int defectsFound;
  final double auditScore;
  final double defectRate;
  final String status;
  final String acknowledgmentId;
  final String observations;
  final String? reviewRemarks;

  factory MonthlySubmission.fromJson(Map<String, dynamic> json) {
    return MonthlySubmission(
      id: _asInt(json['id']),
      siteName: json['site_name'] as String? ?? '',
      businessUnitName: json['business_unit_name'] as String? ?? '',
      reportingPeriodLabel: json['reporting_period_label'] as String? ?? '',
      totalChecks: _asInt(json['total_checks']),
      defectsFound: _asInt(json['defects_found']),
      auditScore: _asDouble(json['audit_score']),
      defectRate: _asDouble(json['defect_rate']),
      status: json['status'] as String? ?? 'pending',
      acknowledgmentId: json['acknowledgment_id'] as String? ?? '-',
      observations: json['observations'] as String? ?? '',
      reviewRemarks: json['review_remarks'] as String?,
    );
  }

  static int _asInt(dynamic value) {
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

  static double _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }
}
