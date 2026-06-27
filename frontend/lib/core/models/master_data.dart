class BusinessUnit {
  const BusinessUnit({
    required this.id,
    required this.name,
    required this.code,
  });

  final int id;
  final String name;
  final String code;

  factory BusinessUnit.fromJson(Map<String, dynamic> json) {
    return BusinessUnit(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
    );
  }
}

class SiteMaster {
  const SiteMaster({
    required this.id,
    required this.name,
    required this.code,
    required this.businessUnit,
    required this.businessUnitName,
  });

  final int id;
  final String name;
  final String code;
  final int businessUnit;
  final String businessUnitName;

  factory SiteMaster.fromJson(Map<String, dynamic> json) {
    return SiteMaster(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
      businessUnit: json['business_unit'] as int,
      businessUnitName: json['business_unit_name'] as String? ?? '',
    );
  }
}

class ReportingPeriod {
  const ReportingPeriod({
    required this.id,
    required this.year,
    required this.month,
    required this.cutoffDate,
    required this.label,
  });

  final int id;
  final int year;
  final int month;
  final String cutoffDate;
  final String label;

  factory ReportingPeriod.fromJson(Map<String, dynamic> json) {
    return ReportingPeriod(
      id: json['id'] as int,
      year: json['year'] as int,
      month: json['month'] as int,
      cutoffDate: json['cutoff_date'] as String,
      label: json['label'] as String,
    );
  }
}

class UserProfileLite {
  const UserProfileLite({
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
  });

  final String username;
  final String fullName;
  final String email;
  final String role;

  factory UserProfileLite.fromJson(Map<String, dynamic> json) {
    return UserProfileLite(
      username: json['username'] as String,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String,
    );
  }
}
