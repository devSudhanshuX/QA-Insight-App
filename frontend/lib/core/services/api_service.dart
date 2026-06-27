import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:qa_insight_hub/core/models/auth_session.dart';
import 'package:qa_insight_hub/core/models/dashboard_model.dart';
import 'package:qa_insight_hub/core/models/master_data.dart';
import 'package:qa_insight_hub/core/models/submission_model.dart';

class ApiService {
  ApiService({String? baseUrl}) : _baseUrl = baseUrl ?? _resolveBaseUrl();

  final String _baseUrl;

  static String _resolveBaseUrl() {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://127.0.0.1:8000/api';
  }

  Map<String, String> _headers({String? token}) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Token $token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> getHealth() async {
    final response = await http.get(Uri.parse('$_baseUrl/health/'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Backend health check failed');
  }

  Future<AuthSession> login({required String username, required String password}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login/'),
      headers: _headers(),
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthSession.fromJson(map);
    }

    final message = _extractError(response.body);
    throw Exception(message);
  }

  Future<void> logout(String token) async {
    await http.post(
      Uri.parse('$_baseUrl/auth/logout/'),
      headers: _headers(token: token),
    );
  }

  Future<List<BusinessUnit>> fetchBusinessUnits(String token) async {
    final mapList = await _getList('$_baseUrl/master/business-units/', token);
    return mapList.map(BusinessUnit.fromJson).toList();
  }

  Future<List<SiteMaster>> fetchSites(String token) async {
    final mapList = await _getList('$_baseUrl/master/sites/', token);
    return mapList.map(SiteMaster.fromJson).toList();
  }

  Future<List<ReportingPeriod>> fetchReportingPeriods(String token) async {
    final mapList = await _getList('$_baseUrl/master/reporting-periods/', token);
    return mapList.map(ReportingPeriod.fromJson).toList();
  }

  Future<List<UserProfileLite>> fetchUserProfiles(String token) async {
    final mapList = await _getList('$_baseUrl/master/user-profiles/', token);
    return mapList.map(UserProfileLite.fromJson).toList();
  }

  Future<List<MonthlySubmission>> fetchSubmissions(String token) async {
    final mapList = await _getList('$_baseUrl/submissions/', token);
    return mapList.map(MonthlySubmission.fromJson).toList();
  }

  Future<MonthlySubmission> submitMonthlyData({
    required String token,
    required int siteId,
    required int businessUnitId,
    required int reportingPeriodId,
    required int totalChecks,
    required int defectsFound,
    required double auditScore,
    required String observations,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/submissions/'),
      headers: _headers(token: token),
      body: jsonEncode(
        {
          'site': siteId,
          'business_unit': businessUnitId,
          'reporting_period': reportingPeriodId,
          'total_checks': totalChecks,
          'defects_found': defectsFound,
          'audit_score': auditScore,
          'observations': observations,
        },
      ),
    );

    if (response.statusCode == 201) {
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      return MonthlySubmission.fromJson(map);
    }

    throw Exception(_extractError(response.body));
  }

  Future<List<MonthlySubmission>> fetchPendingReviews(String token) async {
    final mapList = await _getList('$_baseUrl/reviews/pending/', token);
    return mapList.map(MonthlySubmission.fromJson).toList();
  }

  Future<void> submitReviewAction({
    required String token,
    required int submissionId,
    required String action,
    required String remarks,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/reviews/$submissionId/action/'),
      headers: _headers(token: token),
      body: jsonEncode({'action': action, 'remarks': remarks}),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response.body));
    }
  }

  Future<DashboardKpis> fetchDashboardKpis(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/dashboard/overview/'),
      headers: _headers(token: token),
    );

    if (response.statusCode == 200) {
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      return DashboardKpis.fromJson(map['kpis'] as Map<String, dynamic>);
    }
    throw Exception('Failed to load KPI dashboard');
  }

  Future<List<StatusBreakdown>> fetchStatusBreakdown(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/dashboard/overview/'),
      headers: _headers(token: token),
    );

    if (response.statusCode == 200) {
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (map['status_breakdown'] as List<dynamic>?) ?? const [];
      return data
          .map((item) => StatusBreakdown.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load status breakdown');
  }

  Future<List<ComparativeInsight>> fetchComparativeInsights(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/dashboard/overview/'),
      headers: _headers(token: token),
    );

    if (response.statusCode == 200) {
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (map['comparative_analysis'] as List<dynamic>?) ?? const [];
      return data
          .map((item) => ComparativeInsight.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load comparative analysis');
  }

  Future<List<TrendPoint>> fetchTrendPoints(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/dashboard/trends/'),
      headers: _headers(token: token),
    );

    if (response.statusCode == 200) {
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (map['trend'] as List<dynamic>?) ?? const [];
      return data.map((item) => TrendPoint.fromJson(item as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load trends');
  }

  Future<List<Map<String, dynamic>>> fetchReportTemplates(String token) async {
    final mapList = await _getList('$_baseUrl/reports/templates/', token);
    return mapList;
  }

  Future<Map<String, dynamic>> generateCustomReport(String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/reports/custom/'),
      headers: _headers(token: token),
      body: jsonEncode({}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception('Custom report generation failed');
  }

  Future<int> downloadReportBytes({required String token, required String format}) async {
    final endpoint = format == 'pdf' ? 'pdf' : 'excel';
    final response = await http.get(
      Uri.parse('$_baseUrl/reports/export/$endpoint/'),
      headers: _headers(token: token),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes.length;
    }

    throw Exception('Failed to export $format report');
  }

  Future<List<Map<String, dynamic>>> _getList(String url, String token) async {
    final response = await http.get(Uri.parse(url), headers: _headers(token: token));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List<dynamic>) {
        return decoded.cast<Map<String, dynamic>>();
      }
      if (decoded is Map<String, dynamic> && decoded['results'] is List<dynamic>) {
        return (decoded['results'] as List<dynamic>).cast<Map<String, dynamic>>();
      }
    }

    throw Exception(_extractError(response.body));
  }

  String _extractError(String body) {
    try {
      final dynamic decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        if (decoded['detail'] is String) {
          return decoded['detail'] as String;
        }
        final firstValue = decoded.values.isNotEmpty ? decoded.values.first : null;
        if (firstValue is List<dynamic> && firstValue.isNotEmpty) {
          return firstValue.first.toString();
        }
        if (firstValue != null) {
          return firstValue.toString();
        }
      }
      if (decoded is List<dynamic> && decoded.isNotEmpty) {
        return decoded.first.toString();
      }
    } catch (_) {
      return 'Request failed. Please try again.';
    }
    return 'Request failed. Please try again.';
  }
}
