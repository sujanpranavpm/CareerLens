import 'package:flutter/material.dart';

enum SkillStatus { matched, developing, missing, neutral }

class SkillChip extends StatelessWidget {
  final String label;
  final SkillStatus status;
  final int? proficiency;
  final VoidCallback? onTap;

  const SkillChip({
    super.key,
    required this.label,
    this.status = SkillStatus.neutral,
    this.proficiency,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color textColor;
    IconData? icon;

    switch (status) {
      case SkillStatus.matched:
        bg = const Color(0x1A10B981); // 10% Emerald
        border = const Color(0xFF10B981);
        textColor = const Color(0xFF34D399);
        icon = Icons.check_circle_rounded;
        break;
      case SkillStatus.developing:
        bg = const Color(0x1AF59E0B); // 10% Amber
        border = const Color(0xFFF59E0B);
        textColor = const Color(0xFFFBBF24);
        icon = Icons.timelapse_rounded;
        break;
      case SkillStatus.missing:
        bg = const Color(0x1AEF4444); // 10% Rose
        border = const Color(0xFFEF4444);
        textColor = const Color(0xFFF87171);
        icon = Icons.add_circle_outline_rounded;
        break;
      case SkillStatus.neutral:
        bg = const Color(0x1A6366F1); // 10% Indigo
        border = const Color(0xFF6366F1);
        textColor = const Color(0xFFA5B4FC);
        icon = null;
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border.withOpacity(0.5), width: 1.2),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: border.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: textColor),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: -0.2,
              ),
            ),
            if (proficiency != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$proficiency/5',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
