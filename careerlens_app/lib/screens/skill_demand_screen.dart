import 'package:flutter/material.dart';
import '../models/career_role.dart';
import '../models/skill_demand.dart';
import '../models/skill_trend.dart';
import '../services/api_service.dart';
import '../widgets/demand_badge.dart';

class SkillDemandScreen extends StatefulWidget {
  final ApiService apiService;

  const SkillDemandScreen({super.key, required this.apiService});

  @override
  State<SkillDemandScreen> createState() => _SkillDemandScreenState();
}

class _SkillDemandScreenState extends State<SkillDemandScreen> {
  bool _isLoading = true;
  String? _error;
  List<CareerRole> _roles = [];
  String? _selectedRoleId; // null = all roles
  IndustryDemandResponse? _demandData;
  IndustryTrendsResponse? _trendsData;
  bool _showTrendsTab = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final roles = await widget.apiService.getRoles();
      final demand = await widget.apiService.getIndustryDemand();
      final trends = await widget.apiService.getIndustryTrends();
      setState(() {
        _roles = roles;
        _demandData = demand;
        _trendsData = trends;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _filterByRole(String? roleId) async {
    setState(() {
      _selectedRoleId = roleId;
      _isLoading = true;
      _error = null;
    });

    try {
      final demand = await widget.apiService.getIndustryDemand(roleId: roleId);
      final trends = await widget.apiService.getIndustryTrends(roleId: roleId);
      setState(() {
        _demandData = demand;
        _trendsData = trends;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTrendPill(SkillTrendItem item) {
    Color bg;
    Color text;
    Color border;
    String label;
    IconData icon;

    switch (item.trendDirection) {
      case 'rising':
        bg = const Color(0x2610B981);
        text = const Color(0xFF34D399);
        border = const Color(0xFF10B981);
        label = '+${item.changePercentage}% Rising';
        icon = Icons.trending_up_rounded;
        break;
      case 'emerging':
        bg = const Color(0x26F59E0B);
        text = const Color(0xFFFBBF24);
        border = const Color(0xFFF59E0B);
        label = 'Emerging Hot Tech';
        icon = Icons.star_rounded;
        break;
      case 'declining':
        bg = const Color(0x26EF4444);
        text = const Color(0xFFF87171);
        border = const Color(0xFFEF4444);
        label = '${item.changePercentage}% Change';
        icon = Icons.trending_down_rounded;
        break;
      case 'stable':
      default:
        bg = const Color(0x2664748B);
        text = const Color(0xFF94A3B8);
        border = const Color(0xFF64748B);
        label = '${item.changePercentage >= 0 ? "+" : ""}${item.changePercentage}% Stable';
        icon = Icons.trending_flat_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border.withOpacity(0.4), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: text),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Industry Skill Demand & Trends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF94A3B8)),
            onPressed: () => _filterByRole(_selectedRoleId),
          ),
        ],
      ),
      body: Column(
        children: [
          // View Mode Selector (Current vs Trends)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<bool>(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFF6366F1);
                  }
                  return const Color(0xFF111827);
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white;
                  }
                  return const Color(0xFF94A3B8);
                }),
                side: WidgetStateProperty.all(
                  const BorderSide(color: Color(0xFF1E293B)),
                ),
              ),
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('Current Demand'),
                  icon: Icon(Icons.bar_chart_rounded, size: 16),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('Industry Trends (V2)'),
                  icon: Icon(Icons.show_chart_rounded, size: 16),
                ),
              ],
              selected: {_showTrendsTab},
              onSelectionChanged: (set) =>
                  setState(() => _showTrendsTab = set.first),
            ),
          ),

          // Role Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Roles'),
                  selected: _selectedRoleId == null,
                  onSelected: (_) => _filterByRole(null),
                  backgroundColor: const Color(0xFF111827),
                  selectedColor: const Color(0x336366F1),
                  side: BorderSide(
                    color: _selectedRoleId == null
                        ? const Color(0xFF6366F1)
                        : const Color(0xFF1E293B),
                  ),
                  labelStyle: TextStyle(
                    color: _selectedRoleId == null
                        ? const Color(0xFF818CF8)
                        : const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                  ),
                  checkmarkColor: const Color(0xFF818CF8),
                ),
                const SizedBox(width: 8),
                ..._roles.map((r) {
                  final isSel = _selectedRoleId == r.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(r.title),
                      selected: isSel,
                      backgroundColor: const Color(0xFF111827),
                      selectedColor: const Color(0x336366F1),
                      side: BorderSide(
                        color: isSel
                            ? const Color(0xFF6366F1)
                            : const Color(0xFF1E293B),
                      ),
                      labelStyle: TextStyle(
                        color: isSel
                            ? const Color(0xFF818CF8)
                            : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => _filterByRole(r.id),
                      checkmarkColor: const Color(0xFF818CF8),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Main Content List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                : _error != null
                    ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.white)))
                    : _showTrendsTab
                        ? _buildTrendsView()
                        : _buildDemandView(),
          ),
        ],
      ),
    );
  }

  Widget _buildDemandView() {
    if (_demandData == null || _demandData!.skills.isEmpty) {
      return const Center(child: Text('No skill demand data available.', style: TextStyle(color: Color(0xFF64748B))));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _demandData!.skills.length,
      itemBuilder: (ctx, idx) {
        final item = _demandData!.skills[idx];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFF1E293B)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.skill,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF8FAFC),
                      ),
                    ),
                    DemandBadge(
                      demandLevel: item.demandLevel,
                      compact: false,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (item.percentage / 100.0).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: const Color(0xFF1E293B),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            item.demandLevel == 'High'
                                ? const Color(0xFFEF4444)
                                : item.demandLevel == 'Medium'
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFF06B6D4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${item.percentage.toStringAsFixed(0)}% JDs',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Found in ${item.frequency} of ${_demandData!.totalJdsAnalyzed} job descriptions',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrendsView() {
    if (_trendsData == null || _trendsData!.trends.isEmpty) {
      return const Center(child: Text('No trend data available.', style: TextStyle(color: Color(0xFF64748B))));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _trendsData!.trends.length,
      itemBuilder: (ctx, idx) {
        final item = _trendsData!.trends[idx];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFF1E293B)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.skill,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF8FAFC),
                          ),
                        ),
                        if (item.isHotTech) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0x26EF4444),
                              border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.5)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'O*NET Hot Tech',
                              style: TextStyle(
                                color: Color(0xFFF87171),
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    _buildTrendPill(item),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Current: ${item.percentage.toStringAsFixed(1)}% JDs',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    Text(
                      'Historical Baseline: ${item.baselinePercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
