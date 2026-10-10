"""
career_matcher.py — Cosine similarity career matching for CareerLens V1.

Given a student's skill proficiencies and a career role's required skills,
computes:
  - match_percentage  (0–100, deterministic cosine similarity)
  - matched_skills    — student has skill AND proficiency ≥ threshold
  - developing_skills — student has skill but proficiency below threshold
  - missing_skills    — student does not have skill at all

Matching is entirely deterministic (no LLM, no randomness).
"""

from __future__ import annotations

import math
from typing import NamedTuple

from modules.skill_normalizer import normalize

# Proficiency threshold: a skill is "matched" if the student's proficiency
# is at least this fraction of the role's maximum importance (5).
_MATCH_THRESHOLD_RATIO = 0.6  # e.g. role importance=4, need proficiency ≥ 2.4


class MatchResult(NamedTuple):
    match_percentage: float          # 0.0 – 100.0
    matched_skills: list[str]        # have it, proficiency OK
    developing_skills: list[str]     # have it, proficiency below threshold
    missing_skills: list[str]        # not in student profile at all


def _build_skill_vector(
    skills: dict[str, float],
    skill_order: list[str],
) -> list[float]:
    """Build a numeric vector over ``skill_order`` from a skill→value dict."""
    return [skills.get(s, 0.0) for s in skill_order]


def _cosine_similarity(a: list[float], b: list[float]) -> float:
    """
    Compute cosine similarity between two equal-length vectors.
    Returns 0.0 if either vector is zero.
    """
    dot = sum(x * y for x, y in zip(a, b))
    mag_a = math.sqrt(sum(x * x for x in a))
    mag_b = math.sqrt(sum(y * y for y in b))
    if mag_a == 0.0 or mag_b == 0.0:
        return 0.0
    return dot / (mag_a * mag_b)


def match_student_to_role(
    student_skills: list[dict],
    role_required_skills: list[dict],
) -> MatchResult:
    """
    Compute career match between student and role.

    Args:
        student_skills:
            List of {"name": str, "proficiency": int 1–5} dicts from the DB.
        role_required_skills:
            List of {"name": str, "importance": int 1–5} dicts from career_roles.json.

    Returns:
        MatchResult named tuple.

    Algorithm:
      1. Normalize all skill names on both sides.
      2. Build two vectors over the union of role-required skills:
           student_vec[i] = student proficiency for skill i (0 if missing)
           role_vec[i]    = role importance for skill i
      3. Match percentage = cosine_similarity(student_vec, role_vec) × 100
      4. Classify each role skill into matched / developing / missing.
    """
    # Normalize student skills: canonical_name → proficiency
    student_map: dict[str, float] = {}
    for s in student_skills:
        canon = normalize(s["name"])
        student_map[canon] = float(s.get("proficiency", 1))

    # Normalize role skills: canonical_name → importance
    role_map: dict[str, float] = {}
    for r in role_required_skills:
        canon = normalize(r["name"])
        role_map[canon] = float(r.get("importance", 1))

    if not role_map:
        return MatchResult(
            match_percentage=0.0,
            matched_skills=[],
            developing_skills=[],
            missing_skills=[],
        )

    skill_order = sorted(role_map.keys())

    # Build vectors (role is truth, student is prediction)
    role_vec = _build_skill_vector(role_map, skill_order)
    student_vec = _build_skill_vector(student_map, skill_order)

    # Cosine similarity → percentage
    sim = _cosine_similarity(student_vec, role_vec)
    match_pct = round(sim * 100, 1)

    # Classify each skill
    matched: list[str] = []
    developing: list[str] = []
    missing: list[str] = []

    for skill in skill_order:
        importance = role_map[skill]
        threshold = importance * _MATCH_THRESHOLD_RATIO
        student_prof = student_map.get(skill, 0.0)

        if student_prof == 0.0:
            missing.append(skill)
        elif student_prof >= threshold:
            matched.append(skill)
        else:
            developing.append(skill)

    # Sort each list alphabetically for deterministic output
    matched.sort()
    developing.sort()
    missing.sort()

    return MatchResult(
        match_percentage=match_pct,
        matched_skills=matched,
        developing_skills=developing,
        missing_skills=missing,
    )
