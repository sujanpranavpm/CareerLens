import 'package:flutter/material.dart';
import '../models/career_match.dart';
import '../services/api_service.dart';
import '../widgets/match_gauge.dart';
import '../widgets/skill_chip.dart';
import 'skill_gap_screen.dart';
import 'roadmap_screen.dart';

class CareerMatchScreen extends StatefulWidget {
  final ApiService apiService;
  final int studentId;
  final String roleId;

  const CareerMatchScreen({
    super.key,
    required this.apiService,
    required this.studentId,
    required this.roleId,
  });

  @override
  State<CareerMatchScreen> createState() => _CareerMatchScreenState();
}

class _CareerMatchScreenState extends State<CareerMatchScreen> {
  CareerMatchResult? _matchResult;
  String? _aiExplanation;
  bool _isLoading = true;
  bool _isLoadingAi = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _calculateMatch();
  }

  Future<void> _calculateMatch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await widget.apiService.matchCareer(
        widget.studentId,
        widget.roleId,
      );
      setState(() => _matchResult = result);
      _fetchAiExplanation();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAiExplanation() async {
    setState(() => _isLoadingAi = true);
    try {
      final explanation = await widget.apiService.explainCareerMatch(
        widget.studentId,
        widget.roleId,
      );
      if (mounted) setState(() => _aiExplanation = explanation);
    } catch (e) {
      debugPrint('AI explanation error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingAi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Career Match')),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Career Match')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error matching career: $_error', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _calculateMatch,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final match = _matchResult!;

    return Scaffold(
      appBar: AppBar(
        title: Text(match.roleTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Gauge Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1E293B)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Target Role Alignment',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 18),
                  MatchGauge(
                    percentage: match.matchPercentage,
                    size: 155,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Deterministic Cosine Similarity score based on O*NET software skills and student proficiency.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Gemini AI Career Advisor Card (V2 - Obsidian Glow)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF111827)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.12),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withOpacity(0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Gemini AI Career Advisor Insights',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC7D2FE),
                        ),
                      ),
                      const Spacer(),
                      if (_isLoadingAi)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF818CF8)),
                        )
                      else
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          color: const Color(0xFFA5B4FC),
                          onPressed: _fetchAiExplanation,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _aiExplanation ??
                        'Analyzing your engineering profile and role alignment...',
                    style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Breakdown Sections
            // 1. Matched Skills
            _buildSkillSection(
              title: 'Matched Skills (${match.matchedSkills.length})',
              subtitle: 'Skills meeting or exceeding the role proficiency threshold',
              skills: match.matchedSkills,
              status: SkillStatus.matched,
              emptyText: 'No skills matched yet. Keep learning!',
            ),
            const SizedBox(height: 16),

            // 2. Developing Skills
            _buildSkillSection(
              title: 'Developing Skills (${match.developingSkills.length})',
              subtitle: 'Present in your profile, but need higher proficiency',
              skills: match.developingSkills,
              status: SkillStatus.developing,
              emptyText: 'None in developing status.',
            ),
            const SizedBox(height: 16),

            // 3. Missing Skills
            _buildSkillSection(
              title: 'Missing Skills (${match.missingSkills.length})',
              subtitle: 'Required for this role but not yet in your profile',
              skills: match.missingSkills,
              status: SkillStatus.missing,
              emptyText: 'No missing skills — congratulations!',
            ),
            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.analytics_rounded),
                    label: const Text('Skill Gap Analysis'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: const Color(0xFF818CF8),
                      side: const BorderSide(color: Color(0xFF6366F1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SkillGapScreen(
                            apiService: widget.apiService,
                            studentId: widget.studentId,
                            roleId: widget.roleId,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.map_rounded),
                    label: const Text('Learning Roadmap'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: const Color(0xFF6366F1).withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RoadmapScreen(
                            apiService: widget.apiService,
                            roleId: widget.roleId,
                            studentId: widget.studentId,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillSection({
    required String title,
    required String subtitle,
    required List<String> skills,
    required SkillStatus status,
    required String emptyText,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF8FAFC),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 12),
          if (skills.isEmpty)
            Text(
              emptyText,
              style: const TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Color(0xFF64748B),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills
                  .map((s) => SkillChip(label: s, status: status))
                  .toList(),
            ),
        ],
      ),
    );
  }
}
