import 'package:flutter/material.dart';

import '../models/skill_gap.dart';
import '../models/youtube_video.dart';
import '../services/api_service.dart';
import '../widgets/video_card.dart';
import '../widgets/roadmap_step_card.dart';

class RoadmapScreen extends StatefulWidget {
  final ApiService apiService;
  final String roleId;
  final int? studentId;

  const RoadmapScreen({
    super.key,
    required this.apiService,
    required this.roleId,
    this.studentId,
  });

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  RoadmapResponse? _roadmap;
  String? _aiStudyAdvice;
  bool _isLoading = true;
  bool _isLoadingAdvice = false;
  String? _error;

  // Selected skill for YouTube videos
  String? _selectedVideoSkill;
  List<YouTubeVideo> _skillVideos = [];
  bool _isLoadingVideos = false;

  @override
  void initState() {
    super.initState();
    _loadRoadmap();
  }

  Future<void> _loadRoadmap() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await widget.apiService.getRoadmap(
        widget.roleId,
        studentId: widget.studentId,
      );
      setState(() {
        _roadmap = data;
        if (data.steps.isNotEmpty && _selectedVideoSkill == null) {
          // Find first pending skill or first step
          final pending = data.steps.firstWhere(
            (s) => s.status != 'completed',
            orElse: () => data.steps.first,
          );
          _selectedVideoSkill = pending.skill;
        }
      });

      if (_selectedVideoSkill != null) {
        _fetchVideosForSkill(_selectedVideoSkill!);
      }
      _fetchAiStudyAdvice();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAiStudyAdvice() async {
    setState(() => _isLoadingAdvice = true);
    try {
      final advice = await widget.apiService.explainRoadmap(
        widget.roleId,
        studentId: widget.studentId,
      );
      if (mounted) setState(() => _aiStudyAdvice = advice);
    } catch (e) {
      debugPrint('AI Advice error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingAdvice = false);
    }
  }

  Future<void> _fetchVideosForSkill(String skill) async {
    setState(() {
      _selectedVideoSkill = skill;
      _isLoadingVideos = true;
    });
    try {
      final videos = await widget.apiService.getSkillVideos(skill);
      if (mounted) setState(() => _skillVideos = videos);
    } catch (e) {
      debugPrint('Error fetching videos: $e');
    } finally {
      if (mounted) setState(() => _isLoadingVideos = false);
    }
  }

  Future<void> _toggleSkillProgress(String skillName, bool currentCompleted) async {
    if (widget.studentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF111827),
          content: Text('Save your student profile to track persistent progress.', style: TextStyle(color: Colors.white)),
        ),
      );
      return;
    }

    try {
      await widget.apiService.toggleRoadmapSkill(
        widget.studentId!,
        widget.roleId,
        skillName,
        completed: !currentCompleted,
      );
      // Reload roadmap data to update percentages & gaps
      final updated = await widget.apiService.getRoadmap(
        widget.roleId,
        studentId: widget.studentId,
      );
      setState(() => _roadmap = updated);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF111827),
          content: Text('Error updating progress: $e', style: const TextStyle(color: Color(0xFFEF4444))),
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Career Learning Roadmap')),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Career Learning Roadmap')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error loading roadmap: $_error', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadRoadmap,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final roadmap = _roadmap!;
    final completedCount =
        roadmap.steps.where((s) => s.status == 'completed').length;
    final totalSteps = roadmap.steps.length;
    final progressPct =
        totalSteps > 0 ? (completedCount / totalSteps).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('${roadmap.roleTitle} Roadmap'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadRoadmap,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Header Banner (Obsidian Neural Gradient)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF111827)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1E293B)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.alt_route_rounded,
                            color: Color(0xFF818CF8)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          roadmap.roleTitle,
                          style: const TextStyle(
                            color: Color(0xFFF8FAFC),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress Bar & Percentage
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Roadmap Completion',
                        style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${(progressPct * 100).toStringAsFixed(0)}% ($completedCount/$totalSteps done)',
                        style: const TextStyle(
                            color: Color(0xFF818CF8),
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progressPct,
                      minHeight: 10,
                      backgroundColor: const Color(0xFF1E293B),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Gemini AI Study Advice Banner (V2 - Obsidian Glow)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF111827)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.4)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        size: 18, color: Color(0xFF818CF8)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Gemini AI Study Advice',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFFC7D2FE),
                              ),
                            ),
                            const Spacer(),
                            if (_isLoadingAdvice)
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Color(0xFF818CF8)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _aiStudyAdvice ??
                              'Sequencing your study roadmap for maximum retention...',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFE2E8F0),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // YouTube Video Tutorials Section (V2)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.video_library_rounded,
                        color: Color(0xFFEF4444), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Video Tutorials: ${_selectedVideoSkill ?? "Skill"}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF8FAFC),
                      ),
                    ),
                  ],
                ),
                if (_isLoadingVideos)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFFEF4444)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_skillVideos.isEmpty && !_isLoadingVideos)
              const Text('No video tutorials available.',
                  style: TextStyle(color: Color(0xFF94A3B8)))
            else
              SizedBox(
                height: 195,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _skillVideos.length,
                  itemBuilder: (ctx, idx) {
                    return VideoCard(video: _skillVideos[idx]);
                  },
                ),
              ),
            const SizedBox(height: 28),

            // Milestone Steps Section
            const Text(
              'Interactive Milestone Steps',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF8FAFC),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Check off skills as you learn them to dynamically update your career readiness.',
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),

            ...List.generate(roadmap.steps.length, (idx) {
              final step = roadmap.steps[idx];
              final isCompleted = step.status == 'completed';
              final isLast = idx == roadmap.steps.length - 1;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action bar: checkbox + YouTube trigger
                  Row(
                    children: [
                      // Placeholder width matching timeline column
                      const SizedBox(width: 36),
                      const SizedBox(width: 14),
                      Checkbox(
                        value: isCompleted,
                        activeColor: const Color(0xFF10B981),
                        checkColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF64748B)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (_) =>
                            _toggleSkillProgress(step.skill, isCompleted),
                      ),
                      Text(
                        isCompleted ? 'Completed' : 'Mark as done',
                        style: TextStyle(
                          fontSize: 12,
                          color: isCompleted
                              ? const Color(0xFF10B981)
                              : const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.ondemand_video_rounded,
                            size: 14, color: Color(0xFFEF4444)),
                        label: const Text(
                          'Videos',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFFEF4444)),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _fetchVideosForSkill(step.skill),
                      ),
                    ],
                  ),
                  // Polished timeline step card
                  RoadmapStepCard(step: step, isLast: isLast),
                ],
              );
            }),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
