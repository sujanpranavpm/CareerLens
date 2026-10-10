import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/skill_gap.dart';

class RoadmapStepCard extends StatefulWidget {
  final RoadmapStep step;
  final bool isLast;

  const RoadmapStepCard({
    super.key,
    required this.step,
    this.isLast = false,
  });

  @override
  State<RoadmapStepCard> createState() => _RoadmapStepCardState();
}

class _RoadmapStepCardState extends State<RoadmapStepCard> {
  bool _isExpanded = false;

  Future<void> _openUrl(String urlString) async {
    final uri = Uri.tryParse(urlString);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF10B981); // Emerald
      case 'developing':
        return const Color(0xFFF59E0B); // Amber
      case 'missing':
      default:
        return const Color(0xFFEF4444); // Rose
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle_rounded;
      case 'developing':
        return Icons.timelapse_rounded;
      case 'missing':
      default:
        return Icons.radio_button_unchecked_rounded;
    }
  }

  IconData _getResourceTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'official docs':
      case 'documentation':
        return Icons.menu_book_rounded;
      case 'interactive course':
      case 'course':
        return Icons.school_rounded;
      case 'tutorial':
      case 'guide':
        return Icons.article_rounded;
      default:
        return Icons.link_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.step;
    final statusColor = _getStatusColor(step.status);
    final statusIcon = _getStatusIcon(step.status);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator column
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${step.step}',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              if (!widget.isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFF1E293B),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Card Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E293B)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        step.skill,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFFF8FAFC),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: statusColor.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(statusIcon,
                                                size: 12, color: statusColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              step.status.toUpperCase(),
                                              style: TextStyle(
                                                color: statusColor,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${step.resources.length} free learning resources available',
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              _isExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: const Color(0xFF64748B),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isExpanded && step.resources.isNotEmpty) ...[
                      const Divider(height: 1, color: Color(0xFF1E293B)),
                      Container(
                        color: const Color(0xFF0B0F19),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: step.resources.map((res) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF111827),
                                border: Border.all(color: const Color(0xFF1E293B)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                dense: true,
                                leading: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getResourceTypeIcon(res.type),
                                    size: 18,
                                    color: const Color(0xFF818CF8),
                                  ),
                                ),
                                title: Text(
                                  res.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Color(0xFFF8FAFC),
                                  ),
                                ),
                                subtitle: Text(
                                  '${res.type} • Est: ${res.estimatedTime}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.open_in_new_rounded,
                                    size: 16,
                                    color: Color(0xFF6366F1),
                                  ),
                                  onPressed: () => _openUrl(res.url),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
