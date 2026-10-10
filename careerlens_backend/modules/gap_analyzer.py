"""
gap_analyzer.py — Skill gap analysis and priority scoring for CareerLens V1.

Priority formula (ported from original app.py get_skill_gap logic):
  gap_priority = role_importance × industry_demand_score

Where:
  role_importance      — from career_roles.json (1–5)
  industry_demand_score — derived from mock JD analysis:
                          High=3, Medium=2, Low=1, Unknown=1

Returns skills sorted descending by gap_priority (highest impact gaps first).
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Optional

from modules.skill_normalizer import normalize

# Demand level → numeric score
_DEMAND_SCORES: dict[str, int] = {
    "High": 3,
    "Medium": 2,
    "Low": 1,
}


@dataclass
class SkillGapItem:
    skill: str
    role_importance: float     # 1–5
    demand_level: str          # "High" | "Medium" | "Low" | "Unknown"
    demand_score: int          # 1–3
    gap_priority: float        # role_importance × demand_score
    student_proficiency: float # 0 = missing, 1–5 = proficiency
    status: str                # "missing" | "developing"


def compute_skill_gaps(
    student_skills: list[dict],
    role_required_skills: list[dict],
    industry_demand: Optional[dict[str, dict]] = None,
) -> list[SkillGapItem]:
    """
    Identify and prioritize skill gaps for a student vs. a target role.

    Args:
        student_skills:
            List of {"name": str, "proficiency": int 1–5}.
        role_required_skills:
            List of {"name": str, "importance": int 1–5} from career_roles.json.
        industry_demand:
            Optional dict from skill_extractor.compute_demand_from_jds().
            Keys are canonical skill names; values contain "demand_level".
            If None, all demand scores default to 1.

    Returns:
        List of SkillGapItem sorted descending by gap_priority.
        Only includes missing and developing skills (not already matched).

    Priority formula:
        gap_priority = role_importance × demand_score
    """
    # Build student proficiency lookup (normalized names)
    student_map: dict[str, float] = {}
    for s in student_skills:
        canon = normalize(s["name"])
        student_map[canon] = float(s.get("proficiency", 1))

    # Demand lookup (normalized names)
    demand_map: dict[str, str] = {}
    if industry_demand:
        for skill_name, info in industry_demand.items():
            canon = normalize(skill_name)
            demand_map[canon] = info.get("demand_level", "Low")

    gaps: list[SkillGapItem] = []

    for r in role_required_skills:
        canon = normalize(r["name"])
        importance = float(r.get("importance", 1))

        student_prof = student_map.get(canon, 0.0)

        # Threshold: same as career_matcher (60% of max importance)
        threshold = importance * 0.6

        if student_prof >= threshold:
            continue  # Already matched — not a gap

        demand_level = demand_map.get(canon, "Low")
        demand_score = _DEMAND_SCORES.get(demand_level, 1)
        priority = importance * demand_score
        status = "missing" if student_prof == 0.0 else "developing"

        gaps.append(SkillGapItem(
            skill=canon,
            role_importance=importance,
            demand_level=demand_level,
            demand_score=demand_score,
            gap_priority=round(priority, 2),
            student_proficiency=student_prof,
            status=status,
        ))

    # Sort by gap_priority descending, then by skill name for tie-breaking
    gaps.sort(key=lambda g: (-g.gap_priority, g.skill))
    return gaps


def gaps_to_dict(gaps: list[SkillGapItem]) -> list[dict]:
    """Convert list of SkillGapItem to JSON-serializable list of dicts."""
    return [
        {
            "skill": g.skill,
            "role_importance": g.role_importance,
            "demand_level": g.demand_level,
            "demand_score": g.demand_score,
            "gap_priority": g.gap_priority,
            "student_proficiency": g.student_proficiency,
            "status": g.status,
        }
        for g in gaps
    ]
