import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/student_profile.dart';
import '../models/career_role.dart';
import '../models/skill_demand.dart';
import '../models/career_match.dart';
import '../models/skill_gap.dart';
import '../models/youtube_video.dart';
import '../models/roadmap_progress.dart';
import '../models/skill_trend.dart';

class ApiService {
  static String _baseUrl = 'http://10.0.2.2:8000'; // Default for Android Emulator

  static String get baseUrl => _baseUrl;

  static void setBaseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static void autoConfigureBaseUrl() {
    if (kIsWeb) {
      _baseUrl = 'http://localhost:8000';
    } else if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      _baseUrl = 'http://127.0.0.1:8000';
    } else {
      _baseUrl = 'http://10.0.2.2:8000';
    }
  }

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  // ──────────────────────────────────────────────────────────────────────────
  // PROFILE ENDPOINTS
  // ──────────────────────────────────────────────────────────────────────────

  Future<StudentProfile> createProfile(StudentProfile profile) async {
    final uri = Uri.parse('$_baseUrl/api/profile');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(profile.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return StudentProfile.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create profile: ${response.statusCode} - ${response.body}');
    }
  }

  Future<StudentProfile> updateProfile(int studentId, Map<String, dynamic> updateData) async {
    final uri = Uri.parse('$_baseUrl/api/profile/$studentId');
    final response = await _client.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updateData),
    );

    if (response.statusCode == 200) {
      return StudentProfile.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update profile: ${response.statusCode} - ${response.body}');
    }
  }

  Future<StudentProfile> getProfile(int studentId) async {
    final uri = Uri.parse('$_baseUrl/api/profile/$studentId');
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      return StudentProfile.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load profile: ${response.statusCode} - ${response.body}');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ROLES ENDPOINTS
  // ──────────────────────────────────────────────────────────────────────────

  Future<List<CareerRole>> getRoles() async {
    final uri = Uri.parse('$_baseUrl/api/roles');
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => CareerRole.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load roles: ${response.statusCode} - ${response.body}');
    }
  }

  Future<CareerRole> getRoleDetail(String roleId) async {
    final uri = Uri.parse('$_baseUrl/api/roles/$roleId');
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      return CareerRole.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load role detail: ${response.statusCode} - ${response.body}');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // INDUSTRY DEMAND & TRENDS ENDPOINTS (V2)
  // ──────────────────────────────────────────────────────────────────────────

  Future<IndustryDemandResponse> getIndustryDemand({String? roleId}) async {
    final path = roleId != null ? '$_baseUrl/api/industry-demand/$roleId' : '$_baseUrl/api/industry-demand';
    final uri = Uri.parse(path);
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      return IndustryDemandResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load industry demand: ${response.statusCode} - ${response.body}');
    }
  }

  Future<IndustryTrendsResponse> getIndustryTrends({String? roleId}) async {
    final path = roleId != null ? '$_baseUrl/api/industry-trends?role_id=$roleId' : '$_baseUrl/api/industry-trends';
    final uri = Uri.parse(path);
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      return IndustryTrendsResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load trends: ${response.statusCode} - ${response.body}');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // MATCH & GAP ENDPOINTS
  // ──────────────────────────────────────────────────────────────────────────

  Future<CareerMatchResult> matchCareer(int studentId, String roleId) async {
    final uri = Uri.parse('$_baseUrl/api/match');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'student_id': studentId,
        'role_id': roleId,
      }),
    );

    if (response.statusCode == 200) {
      return CareerMatchResult.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to calculate match: ${response.statusCode} - ${response.body}');
    }
  }

  Future<SkillGapResponse> getSkillGaps(int studentId, String roleId) async {
    final uri = Uri.parse('$_baseUrl/api/gap/$studentId/$roleId');
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      return SkillGapResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load skill gaps: ${response.statusCode} - ${response.body}');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ROADMAP & PROGRESS TRACKING (V2)
  // ──────────────────────────────────────────────────────────────────────────

  Future<RoadmapResponse> getRoadmap(String roleId, {int? studentId}) async {
    var url = '$_baseUrl/api/roadmap/$roleId';
    if (studentId != null) {
      url += '?student_id=$studentId';
    }
    final uri = Uri.parse(url);
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      return RoadmapResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load roadmap: ${response.statusCode} - ${response.body}');
    }
  }

  Future<RoadmapProgress> getStudentProgress(int studentId, String roleId) async {
    final uri = Uri.parse('$_baseUrl/api/progress/$studentId/$roleId');
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      return RoadmapProgress.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load progress: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> toggleRoadmapSkill(
    int studentId,
    String roleId,
    String skillName, {
    bool? completed,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/progress/$studentId/$roleId/toggle');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'skill_name': skillName,
        if (completed != null) 'completed': completed,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to toggle progress: ${response.statusCode} - ${response.body}');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // YOUTUBE VIDEO RESOURCES (V2)
  // ──────────────────────────────────────────────────────────────────────────

  Future<List<YouTubeVideo>> getSkillVideos(String skillName, {int maxResults = 3}) async {
    final uri = Uri.parse('$_baseUrl/api/resources/videos/${Uri.encodeComponent(skillName)}?max_results=$maxResults');
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> videos = data['videos'] ?? [];
      return videos.map((v) => YouTubeVideo.fromJson(v as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load videos: ${response.statusCode} - ${response.body}');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GEMINI AI EXPLANATIONS (V2)
  // ──────────────────────────────────────────────────────────────────────────

  Future<String> explainCareerMatch(int studentId, String roleId) async {
    final uri = Uri.parse('$_baseUrl/api/explain/match');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'student_id': studentId,
        'role_id': roleId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['explanation'] ?? '';
    } else {
      throw Exception('Failed to get AI match explanation: ${response.statusCode}');
    }
  }

  Future<String> explainSkillGap(String roleId, String skillName) async {
    final uri = Uri.parse('$_baseUrl/api/explain/gap');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'role_id': roleId,
        'skill_name': skillName,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['explanation'] ?? '';
    } else {
      throw Exception('Failed to get AI gap explanation: ${response.statusCode}');
    }
  }

  Future<String> explainRoadmap(String roleId, {int? studentId}) async {
    final uri = Uri.parse('$_baseUrl/api/explain/roadmap');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'role_id': roleId,
        if (studentId != null) 'student_id': studentId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['advice'] ?? '';
    } else {
      throw Exception('Failed to get AI study advice: ${response.statusCode}');
    }
  }
}
