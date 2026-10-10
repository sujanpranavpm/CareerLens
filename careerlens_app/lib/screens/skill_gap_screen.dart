import 'package:flutter/material.dart';
import '../models/skill_gap.dart';
import '../services/api_service.dart';
import '../widgets/demand_badge.dart';
import 'roadmap_screen.dart';

class SkillGapScreen extends StatefulWidget {
  final ApiService apiService;
  final int studentId;
  final String roleId;

  const SkillGapScreen({
    super.key,
    required this.apiService,
    required this.studentId,
    required this.roleId,
  });

  @override
  State<SkillGapScreen> createState() => _SkillGapScreenState();
}

class _SkillGapScreenState extends State<SkillGapScreen> {
  SkillGapResponse? _gapResponse;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSkillGaps();
  }

  Future<void> _loadSkillGaps() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await widget.apiService.getSkillGaps(
        widget.studentId,
        widget.roleId,
      );
      setState(() => _gapResponse = response);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAiExplanationModal(SkillGapItem gap) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Color(0xFF1E293B)),
      ),
      builder: (ctx) => FutureBuilder<String>(
        future: widget.apiService.explainSkillGap(widget.roleId, gap.skill),
        builder: (ctx, snapshot) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF111827),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFF818CF8),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Why ${gap.skill} Matters',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF8FAFC),
                            ),
                          ),
                          Text(
                            'Importance: ${gap.roleImportance.toInt()}/5 • Demand: ${gap.demandLevel}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                    ),
                  )
                else if (snapshot.hasError)
                  Text(
                    'Error loading AI insights: ${snapshot.error}',
                    style: const TextStyle(color: Color(0xFFEF4444)),
                  )
                else
                  Text(
                    snapshot.data ?? 'No explanation available.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFE2E8F0),
                      height: 1.5,
                    ),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.school_rounded),
                    label: Text('Learn ${gap.skill} on Roadmap'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
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
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Skill Gap Analysis')),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Skill Gap Analysis')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error loading gaps: $_error', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadSkillGaps,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final data = _gapResponse!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skill Gap Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadSkillGaps,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF111827)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: const Border(
                bottom: BorderSide(color: Color(0xFF1E293B)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      data.roleTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF8FAFC),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                      ),
                      child: Text(
                        '${data.totalGaps} Identified Gaps',
                        style: const TextStyle(
                          color: Color(0xFF818CF8),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Prioritized by Formula: Gap Priority = Role Importance × Industry Demand Score',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),

          // Gaps list
          Expanded(
            child: data.gaps.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.verified_rounded, size: 48, color: Color(0xFF10B981)),
                        SizedBox(height: 12),
                        Text(
                          'No skill gaps found!',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFF8FAFC)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'You meet or exceed all requirements for this role.',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: data.gaps.length,
                    itemBuilder: (ctx, idx) {
                      final gap = data.gaps[idx];
                      final isMissing = gap.status.toLowerCase() == 'missing';

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: Color(0xFF1E293B)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showAiExplanationModal(gap),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF1E293B),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '#${idx + 1}',
                                        style: const TextStyle(
                                          color: Color(0xFF818CF8),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        gap.skill,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFF8FAFC),
                                        ),
                                      ),
                                    ),
                                    DemandBadge(
                                      demandLevel: gap.demandLevel,
                                      compact: true,
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 16,
                                      color: Color(0xFF818CF8),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMetricPill(
                                        label: 'Role Importance',
                                        value: '${gap.roleImportance.toInt()}/5',
                                        color: const Color(0xFF6366F1),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildMetricPill(
                                        label: 'Your Level',
                                        value: isMissing
                                            ? '0/5 (Missing)'
                                            : '${gap.studentProficiency.toInt()}/5',
                                        color: isMissing
                                            ? const Color(0xFFEF4444)
                                            : const Color(0xFFF59E0B),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildMetricPill(
                                        label: 'Gap Priority',
                                        value: gap.gapPriority.toStringAsFixed(1),
                                        color: const Color(0xFF8B5CF6),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Action
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.route_rounded),
                label: const Text('Generate Learning Roadmap'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shadowColor: const Color(0xFF6366F1).withOpacity(0.4),
                  elevation: 4,
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
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

