import 'package:flutter/material.dart';

class DemandBadge extends StatelessWidget {
  final String demandLevel;
  final bool compact;

  const DemandBadge({
    super.key,
    required this.demandLevel,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    Color border;
    IconData icon;

    switch (demandLevel.toLowerCase()) {
      case 'high':
        bg = const Color(0x26EF4444);
        text = const Color(0xFFF87171);
        border = const Color(0xFFEF4444);
        icon = Icons.local_fire_department_rounded;
        break;
      case 'medium':
        bg = const Color(0x26F59E0B);
        text = const Color(0xFFFBBF24);
        border = const Color(0xFFF59E0B);
        icon = Icons.trending_up_rounded;
        break;
      case 'low':
      default:
        bg = const Color(0x2664748B);
        text = const Color(0xFF94A3B8);
        border = const Color(0xFF64748B);
        icon = Icons.remove_rounded;
        break;
    }

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border.withOpacity(0.4), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          demandLevel,
          style: TextStyle(
            color: text,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border.withOpacity(0.4), width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: text),
          const SizedBox(width: 4),
          Text(
            '$demandLevel Demand',
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
