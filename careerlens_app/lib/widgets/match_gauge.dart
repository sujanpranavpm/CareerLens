import 'package:flutter/material.dart';

class MatchGauge extends StatelessWidget {
  final double percentage;
  final double size;
  final String? subtitle;

  const MatchGauge({
    super.key,
    required this.percentage,
    this.size = 140,
    this.subtitle,
  });

  Color _getColor(double pct) {
    if (pct >= 75) return const Color(0xFF10B981); // Emerald Green
    if (pct >= 50) return const Color(0xFF6366F1); // Electric Indigo
    if (pct >= 30) return const Color(0xFFF59E0B); // Solar Amber
    return const Color(0xFFEF4444); // Cyber Rose
  }

  String _getFitLabel(double pct) {
    if (pct >= 80) return 'Exceptional Match';
    if (pct >= 65) return 'Strong Alignment';
    if (pct >= 45) return 'Moderate Fit';
    if (pct >= 25) return 'Emerging Potential';
    return 'Foundational Phase';
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(percentage);
    final clampedPct = (percentage / 100.0).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ambient glow ring
              Container(
                width: size * 0.85,
                height: size * 0.85,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.15),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              // Gauge Progress Indicator
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: clampedPct,
                  strokeWidth: 10,
                  backgroundColor: const Color(0xFF1E293B),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: size * 0.22,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFF8FAFC),
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Similarity',
                    style: TextStyle(
                      fontSize: size * 0.085,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            border: Border.all(color: color.withOpacity(0.4), width: 1.0),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            subtitle ?? _getFitLabel(percentage),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}
