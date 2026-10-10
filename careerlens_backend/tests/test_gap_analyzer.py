"""
test_gap_analyzer.py — Unit tests for gap_analyzer.py
"""

import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import pytest
from modules.gap_analyzer import compute_skill_gaps, gaps_to_dict, SkillGapItem


def _student(skills: dict) -> list[dict]:
    return [{"name": name, "proficiency": prof} for name, prof in skills.items()]


def _role(skills: dict) -> list[dict]:
    return [{"name": name, "importance": imp} for name, imp in skills.items()]


class TestComputeSkillGaps:

    def test_all_missing(self):
        """Student has no skills → all role skills are gaps."""
        student = []
        role = _role({"Python": 5, "SQL": 4, "Docker": 3})
        gaps = compute_skill_gaps(student, role)
        skill_names = [g.skill for g in gaps]
        assert "Python" in skill_names
        assert "SQL" in skill_names
        assert "Docker" in skill_names

    def test_no_gaps_when_fully_matched(self):
        """Student meets/exceeds all skills → empty gaps list."""
        student = _student({"Python": 5, "SQL": 5, "Docker": 5})
        role = _role({"Python": 5, "SQL": 4, "Docker": 3})
        gaps = compute_skill_gaps(student, role)
        assert gaps == []

    def test_developing_status(self):
        """Skill present below threshold → status 'developing'."""
        # importance=5, threshold=3.0, proficiency=2 → developing
        student = _student({"Python": 2})
        role = _role({"Python": 5})
        gaps = compute_skill_gaps(student, role)
        assert len(gaps) == 1
        assert gaps[0].status == "developing"
        assert gaps[0].student_proficiency == 2.0

    def test_missing_status(self):
        """Skill completely absent → status 'missing'."""
        student = _student({"SQL": 5})
        role = _role({"Python": 5, "SQL": 5})
        gaps = compute_skill_gaps(student, role)
        assert len(gaps) == 1
        assert gaps[0].skill == "Python"
        assert gaps[0].status == "missing"
        assert gaps[0].student_proficiency == 0.0

    def test_priority_formula_no_demand(self):
        """Without demand data, priority = role_importance × 1."""
        student = []
        role = _role({"Python": 5, "SQL": 3})
        gaps = compute_skill_gaps(student, role)
        python_gap = next(g for g in gaps if g.skill == "Python")
        sql_gap = next(g for g in gaps if g.skill == "SQL")
        assert python_gap.gap_priority == 5.0 * 1   # importance=5, demand_score=1
        assert sql_gap.gap_priority == 3.0 * 1

    def test_priority_formula_with_demand(self):
        """High demand skill gets higher priority score."""
        student = []
        role = _role({"Python": 5, "SQL": 5})
        demand = {
            "Python": {"demand_level": "High"},    # score=3
            "SQL": {"demand_level": "Low"},         # score=1
        }
        gaps = compute_skill_gaps(student, role, industry_demand=demand)
        python_gap = next(g for g in gaps if g.skill == "Python")
        sql_gap = next(g for g in gaps if g.skill == "SQL")
        assert python_gap.gap_priority == 5.0 * 3  # = 15
        assert sql_gap.gap_priority == 5.0 * 1     # = 5
        assert python_gap.gap_priority > sql_gap.gap_priority

    def test_sorted_descending_by_priority(self):
        """Gaps are sorted by gap_priority descending."""
        student = []
        role = _role({"Python": 5, "Docker": 2, "SQL": 4})
        gaps = compute_skill_gaps(student, role)
        priorities = [g.gap_priority for g in gaps]
        assert priorities == sorted(priorities, reverse=True)

    def test_alphabetical_tiebreaker(self):
        """Equal priority → alphabetical order by skill name."""
        student = []
        role = _role({"Zebra": 3, "Apple": 3, "Mango": 3})
        gaps = compute_skill_gaps(student, role)
        # All priority=3*1=3, so alphabetical
        skill_names = [g.skill for g in gaps]
        # "Apple" < "Mango" < "Zebra" after normalize (title-cased)
        assert skill_names == sorted(skill_names)

    def test_demand_level_scores(self):
        """Demand levels map to correct numeric scores."""
        student = []
        role = _role({"Python": 1})
        for level, expected_score in [("High", 3), ("Medium", 2), ("Low", 1)]:
            demand = {"Python": {"demand_level": level}}
            gaps = compute_skill_gaps(student, role, industry_demand=demand)
            assert gaps[0].demand_score == expected_score

    def test_alias_normalized_in_demand(self):
        """Student skill alias is normalized before comparison."""
        student = [{"name": "py", "proficiency": 5}]  # 'py' → 'Python'
        role = _role({"Python": 5})
        gaps = compute_skill_gaps(student, role)
        assert gaps == []  # No gap — Python is matched

    def test_deterministic_output(self):
        """Same input always produces the same output."""
        student = _student({"Python": 3})
        role = _role({"Python": 5, "SQL": 4, "Docker": 5})
        demand = {"Python": {"demand_level": "High"}, "SQL": {"demand_level": "Medium"}}
        r1 = compute_skill_gaps(student, role, industry_demand=demand)
        r2 = compute_skill_gaps(student, role, industry_demand=demand)
        assert [g.skill for g in r1] == [g.skill for g in r2]
        assert [g.gap_priority for g in r1] == [g.gap_priority for g in r2]

    def test_empty_role(self):
        """Empty role skills → empty gaps list."""
        student = _student({"Python": 5})
        gaps = compute_skill_gaps(student, [])
        assert gaps == []

    def test_empty_student_all_missing(self):
        """Empty student → all skills missing."""
        role = _role({"Python": 5, "SQL": 4})
        gaps = compute_skill_gaps([], role)
        for g in gaps:
            assert g.status == "missing"
            assert g.student_proficiency == 0.0


class TestGapsToDict:
    def test_serialization(self):
        student = []
        role = _role({"Python": 5})
        gaps = compute_skill_gaps(student, role)
        result = gaps_to_dict(gaps)
        assert isinstance(result, list)
        assert len(result) == 1
        assert isinstance(result[0], dict)
        assert "skill" in result[0]
        assert "gap_priority" in result[0]
        assert "demand_level" in result[0]
        assert "status" in result[0]
