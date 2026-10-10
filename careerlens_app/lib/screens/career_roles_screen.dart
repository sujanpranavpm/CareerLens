import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/career_role.dart';
import '../services/api_service.dart';
import 'career_match_screen.dart';

class CareerRolesScreen extends StatefulWidget {
  final ApiService apiService;

  const CareerRolesScreen({super.key, required this.apiService});

  @override
  State<CareerRolesScreen> createState() => _CareerRolesScreenState();
}

class _CareerRolesScreenState extends State<CareerRolesScreen> {
  List<CareerRole> _roles = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedRoleId;
  int? _studentId;

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
      final prefs = await SharedPreferences.getInstance();
      _studentId = prefs.getInt('student_id');

      final roles = await widget.apiService.getRoles();
      setState(() {
        _roles = roles;
        if (_roles.isNotEmpty && _selectedRoleId == null) {
          _selectedRoleId = _roles.first.id;
        }
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRoleDetailModal(CareerRole role) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: Color(0xFF1E293B)),
      ),
      builder: (ctx) => FutureBuilder<CareerRole>(
        future: widget.apiService.getRoleDetail(role.id),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return SizedBox(
              height: 250,
              child: Center(child: Text('Error loading role: ${snapshot.error}', style: const TextStyle(color: Colors.white))),
            );
          }

          final detail = snapshot.data!;

          return Container(
            padding: const EdgeInsets.all(24),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.78,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detail.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF8FAFC),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'O*NET SOC: ${detail.onetCode}',
                            style: const TextStyle(
                              color: Color(0xFF06B6D4), // Cyan
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
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
                const SizedBox(height: 14),
                Text(
                  detail.description,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Required Technical Skills (O*NET 31.0 Aligned)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    itemCount: detail.requiredSkills.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF1E293B)),
                    itemBuilder: (ctx, idx) {
                      final s = detail.requiredSkills[idx];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0x1A6366F1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.4)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${s.importance}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFA5B4FC),
                            ),
                          ),
                        ),
                        title: Text(
                          s.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        trailing: Text(
                          'Importance: ${s.importance}/5',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _matchRole(detail.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: const Color(0xFF6366F1).withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Analyze AI Match Fit',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _matchRole(String roleId) async {
    final prefs = await SharedPreferences.getInstance();
    final studentId = prefs.getInt('student_id');

    if (studentId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF1E293B),
            content: Text('Please save your student profile first before matching.', style: TextStyle(color: Colors.white)),
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CareerMatchScreen(
          apiService: widget.apiService,
          studentId: studentId,
          roleId: roleId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load career roles: $_error', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Career Roles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF94A3B8)),
            onPressed: _loadData,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _roles.length,
        itemBuilder: (ctx, idx) {
          final role = _roles[idx];
          final isSelected = role.id == _selectedRoleId;

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
                width: isSelected ? 1.8 : 1.0,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() => _selectedRoleId = role.id);
                _showRoleDetailModal(role);
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0x1A6366F1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                          ),
                          child: const Icon(
                            Icons.work_outline_rounded,
                            color: Color(0xFF818CF8),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                role.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFF8FAFC),
                                ),
                              ),
                              Text(
                                'SOC ${role.onetCode} • ${role.skillCount} core skills',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF06B6D4), // Cyan
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF64748B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      role.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.radar_rounded, size: 16),
                          label: const Text('Match Fit'),
                          onPressed: () => _matchRole(role.id),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF818CF8),
                            side: const BorderSide(color: Color(0xFF6366F1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
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
    );
  }
}
