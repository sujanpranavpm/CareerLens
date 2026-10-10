import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student_profile.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback? onProfileSaved;

  const ProfileScreen({
    super.key,
    required this.apiService,
    this.onProfileSaved,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _degreeController = TextEditingController(text: 'B.Tech');
  final _branchController = TextEditingController(text: 'Computer Science & Engineering');
  final _cgpaController = TextEditingController(text: '8.5');
  int _selectedYear = 3;

  int? _studentId;
  bool _isLoading = false;
  bool _isSaving = false;

  final List<SkillItem> _skills = [
    SkillItem(name: 'Python', proficiency: 4),
    SkillItem(name: 'SQL', proficiency: 3),
    SkillItem(name: 'Git', proficiency: 3),
  ];

  final List<ProjectItem> _projects = [];
  final List<CertificationItem> _certifications = [];

  final _newSkillNameController = TextEditingController();
  int _newSkillProficiency = 3;

  final _projectTitleController = TextEditingController();
  final _projectDescController = TextEditingController();

  final _certNameController = TextEditingController();
  final _certIssuerController = TextEditingController();
  final _certYearController = TextEditingController(text: '2024');

  @override
  void initState() {
    super.initState();
    _loadSavedProfile();
  }

  Future<void> _loadSavedProfile() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getInt('student_id');
      if (savedId != null) {
        final profile = await widget.apiService.getProfile(savedId);
        setState(() {
          _studentId = profile.id;
          _nameController.text = profile.name;
          _degreeController.text = profile.degree;
          _branchController.text = profile.branch;
          _selectedYear = profile.year;
          _cgpaController.text = profile.cgpa.toString();

          _skills.clear();
          _skills.addAll(profile.skills);

          _projects.clear();
          _projects.addAll(profile.projects);

          _certifications.clear();
          _certifications.addAll(profile.certifications);
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_skills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF1E293B),
          content: Text('Please add at least one technical skill.', style: TextStyle(color: Colors.white)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final profile = StudentProfile(
        id: _studentId,
        name: _nameController.text.trim(),
        degree: _degreeController.text.trim(),
        branch: _branchController.text.trim(),
        year: _selectedYear,
        cgpa: double.tryParse(_cgpaController.text.trim()) ?? 8.0,
        skills: _skills,
        projects: _projects,
        certifications: _certifications,
      );

      StudentProfile result;
      if (_studentId == null) {
        result = await widget.apiService.createProfile(profile);
      } else {
        result = await widget.apiService.updateProfile(_studentId!, profile.toJson());
      }

      final prefs = await SharedPreferences.getInstance();
      if (result.id != null) {
        await prefs.setInt('student_id', result.id!);
        setState(() => _studentId = result.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF10B981),
            content: Text('Profile saved successfully! Ready for AI Career Matching.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
        widget.onProfileSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text('Error saving profile: $e', style: const TextStyle(color: Colors.white)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAddSkillDialog() {
    _newSkillNameController.clear();
    _newSkillProficiency = 3;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF111827),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF1E293B)),
          ),
          title: const Text('Add Technical Skill', style: TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _newSkillNameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Skill Name (e.g. Python, Docker, React)',
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Proficiency Level: $_newSkillProficiency / 5',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF818CF8)),
              ),
              Slider(
                value: _newSkillProficiency.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                activeColor: const Color(0xFF6366F1),
                inactiveColor: const Color(0xFF1E293B),
                label: '$_newSkillProficiency',
                onChanged: (val) {
                  setDlgState(() => _newSkillProficiency = val.round());
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final name = _newSkillNameController.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    _skills.removeWhere(
                        (s) => s.name.toLowerCase() == name.toLowerCase());
                    _skills.add(SkillItem(
                        name: name, proficiency: _newSkillProficiency));
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProjectDialog() {
    _projectTitleController.clear();
    _projectDescController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1E293B)),
        ),
        title: const Text('Add Engineering Project', style: TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _projectTitleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Project Title',
                hintText: 'e.g., E-Commerce Microservices',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _projectDescController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description & Tech Stack',
                hintText: 'Built with FastAPI, Redis, and PostgreSQL',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final title = _projectTitleController.text.trim();
              if (title.isNotEmpty) {
                setState(() {
                  _projects.add(ProjectItem(
                    title: title,
                    description: _projectDescController.text.trim(),
                  ));
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddCertDialog() {
    _certNameController.clear();
    _certIssuerController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1E293B)),
        ),
        title: const Text('Add Certification', style: TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _certNameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Certificate Name',
                hintText: 'e.g. AWS Cloud Practitioner',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _certIssuerController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Issuer / Organization',
                hintText: 'e.g. Amazon Web Services',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _certYearController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Year Obtained',
                hintText: '2024',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final name = _certNameController.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  _certifications.add(CertificationItem(
                    name: name,
                    issuer: _certIssuerController.text.trim(),
                    year: int.tryParse(_certYearController.text.trim()),
                  ));
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF94A3B8)),
            onPressed: _loadSavedProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.school_rounded, size: 32, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameController.text.isEmpty
                                ? 'Engineering Student'
                                : _nameController.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_degreeController.text} • Year $_selectedYear • CGPA ${_cgpaController.text}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Academic Info Section
              const Text(
                'Academic Credentials',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFFF8FAFC)),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline_rounded, color: Color(0xFF6366F1)),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _degreeController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Degree',
                      ),
                      validator: (val) =>
                          (val == null || val.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedYear,
                      dropdownColor: const Color(0xFF111827),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Year of Study',
                      ),
                      items: [1, 2, 3, 4, 5].map((y) {
                        return DropdownMenuItem(
                          value: y,
                          child: Text('Year $y', style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedYear = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _branchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Branch / Specialization',
                      ),
                      validator: (val) =>
                          (val == null || val.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cgpaController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'CGPA (0-10)',
                      ),
                      validator: (val) {
                        final parsed = double.tryParse(val ?? '');
                        if (parsed == null || parsed < 0 || parsed > 10) {
                          return '0.0 - 10.0';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Skills Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Technical Skills',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFFF8FAFC)),
                  ),
                  TextButton.icon(
                    onPressed: _showAddSkillDialog,
                    icon: const Icon(Icons.add_rounded, color: Color(0xFF818CF8)),
                    label: const Text('Add Skill', style: TextStyle(color: Color(0xFF818CF8))),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_skills.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    border: Border.all(color: const Color(0xFF1E293B)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('No skills added yet. Tap "Add Skill" above.', style: TextStyle(color: Color(0xFF64748B))),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _skills.map((s) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0x1A6366F1),
                        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.4)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${s.name} (${s.proficiency}/5)',
                            style: const TextStyle(color: Color(0xFFA5B4FC), fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => setState(() => _skills.remove(s)),
                            child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF818CF8)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 28),

              // Projects Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Projects',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFFF8FAFC)),
                  ),
                  TextButton.icon(
                    onPressed: _showAddProjectDialog,
                    icon: const Icon(Icons.add_rounded, color: Color(0xFF818CF8)),
                    label: const Text('Add Project', style: TextStyle(color: Color(0xFF818CF8))),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_projects.isEmpty)
                const Text(
                  'No projects added yet.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                )
              else
                ..._projects.map((p) {
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Color(0xFF1E293B)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(p.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      subtitle: p.description.isNotEmpty
                          ? Text(p.description, style: const TextStyle(color: Color(0xFF94A3B8)))
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 20, color: Color(0xFFEF4444)),
                        onPressed: () => setState(() => _projects.remove(p)),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 28),

              // Certifications Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Certifications',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFFF8FAFC)),
                  ),
                  TextButton.icon(
                    onPressed: _showAddCertDialog,
                    icon: const Icon(Icons.add_rounded, color: Color(0xFF818CF8)),
                    label: const Text('Add Cert', style: TextStyle(color: Color(0xFF818CF8))),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_certifications.isEmpty)
                const Text(
                  'No certifications added yet.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                )
              else
                ..._certifications.map((c) {
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Color(0xFF1E293B)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.workspace_premium_rounded,
                          color: Color(0xFFF59E0B)),
                      title: Text(c.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      subtitle: Text(
                          '${c.issuer}${c.year != null ? ' (${c.year})' : ''}',
                          style: const TextStyle(color: Color(0xFF94A3B8))),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 20, color: Color(0xFFEF4444)),
                        onPressed: () =>
                            setState(() => _certifications.remove(c)),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveProfile,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.bolt_rounded),
                  label: Text(
                    _studentId == null ? 'Create Student Profile' : 'Update Profile & Re-Sync',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shadowColor: const Color(0xFF6366F1).withOpacity(0.5),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
