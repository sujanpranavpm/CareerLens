"""
test_career_matcher.py — Unit tests for career_matcher.py
"""

import sys
import os
import math

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import pytest
from modules.career_matcher import match_student_to_role, _cosine_similarity, MatchResult


class TestCosineSimilarity:
    """Tests for the internal cosine similarity helper."""

    def test_identical_vectors(self):
        """Identical vectors should give similarity 1.0."""
        v = [3.0, 4.0, 0.0]
        assert math.isclose(_cosine_similarity(v, v), 1.0, rel_tol=1e-9)

    def test_orthogonal_vectors(self):
        """Perpendicular vectors give similarity 0.0."""
        a = [1.0, 0.0]
        b = [0.0, 1.0]
        assert math.isclose(_cosine_similarity(a, b), 0.0, abs_tol=1e-9)

    def test_zero_vector_a(self):
        """Zero vector returns 0.0 (no division by zero)."""
        assert _cosine_similarity([0.0, 0.0], [1.0, 2.0]) == 0.0

    def test_zero_vector_b(self):
        assert _cosine_similarity([1.0, 2.0], [0.0, 0.0]) == 0.0

    def test_both_zero(self):
        assert _cosine_similarity([0.0], [0.0]) == 0.0

    def test_partial_overlap(self):
        """Some overlap → similarity between 0 and 1."""
        a = [1.0, 1.0, 0.0]
        b = [1.0, 0.0, 0.0]
        sim = _cosine_similarity(a, b)
        assert 0.0 < sim < 1.0


class TestMatchStudentToRole:
    """Tests for the full matching pipeline."""

    def _student(self, skills: dict) -> list[dict]:
        return [{"name": name, "proficiency": prof} for name, prof in skills.items()]

    def _role(self, skills: dict) -> list[dict]:
        return [{"name": name, "importance": imp} for name, imp in skills.items()]

    def test_perfect_match(self):
        """Student with all required skills at max proficiency → high match %."""
        student = self._student({"Python": 5, "SQL": 5, "Docker": 5})
        role = self._role({"Python": 5, "SQL": 5, "Docker": 5})
        result = match_student_to_role(student, role)
        assert result.match_percentage == 100.0
        assert "Python" in result.matched_skills
        assert len(result.missing_skills) == 0
        assert len(result.developing_skills) == 0

    def test_complete_mismatch(self):
        """Student has none of the role skills → 0% match."""
        student = self._student({"Java": 5})
        role = self._role({"Python": 5, "SQL": 5})
        result = match_student_to_role(student, role)
        assert result.match_percentage == 0.0
        assert "Python" in result.missing_skills
        assert "SQL" in result.missing_skills

    def test_partial_match(self):
        """Student has some but not all skills."""
        student = self._student({"Python": 5, "SQL": 5})
        role = self._role({"Python": 5, "SQL": 5, "Docker": 5, "AWS": 5})
        result = match_student_to_role(student, role)
        assert 0 < result.match_percentage < 100
        assert "Python" in result.matched_skills
        assert "SQL" in result.matched_skills
        assert "Docker" in result.missing_skills
        assert "AWS" in result.missing_skills

    def test_developing_classification(self):
        """Skill present but below threshold → developing."""
        # Importance=5, threshold=5*0.6=3.0, student has 2 → developing
        student = self._student({"Python": 2})
        role = self._role({"Python": 5})
        result = match_student_to_role(student, role)
        assert "Python" in result.developing_skills
        assert "Python" not in result.matched_skills
        assert "Python" not in result.missing_skills

    def test_alias_normalization_in_match(self):
        """Aliases in student profile are normalized before matching."""
        student = [{"name": "py", "proficiency": 5}]  # 'py' → 'Python'
        role = self._role({"Python": 5})
        result = match_student_to_role(student, role)
        assert "Python" in result.matched_skills

    def test_empty_role(self):
        """Empty role → 0% match."""
        student = self._student({"Python": 5})
        result = match_student_to_role(student, [])
        assert result.match_percentage == 0.0

    def test_empty_student(self):
        """Empty student → all skills missing."""
        role = self._role({"Python": 5, "SQL": 5})
        result = match_student_to_role([], role)
        assert result.match_percentage == 0.0
        assert set(result.missing_skills) == {"Python", "SQL"}

    def test_deterministic(self):
        """Same input always gives same output."""
        student = self._student({"Python": 4, "SQL": 3, "Docker": 1})
        role = self._role({"Python": 5, "SQL": 4, "Docker": 5, "AWS": 5})
        r1 = match_student_to_role(student, role)
        r2 = match_student_to_role(student, role)
        assert r1.match_percentage == r2.match_percentage
        assert r1.matched_skills == r2.matched_skills
        assert r1.missing_skills == r2.missing_skills

    def test_result_lists_sorted(self):
        """Output skill lists are sorted alphabetically."""
        student = self._student({"Python": 5, "SQL": 5, "Docker": 5})
        role = self._role({"Python": 5, "SQL": 5, "Docker": 5})
        result = match_student_to_role(student, role)
        assert result.matched_skills == sorted(result.matched_skills)

    def test_match_percentage_range(self):
        """Match percentage is always between 0 and 100."""
        student = self._student({"Python": 3, "SQL": 2})
        role = self._role({"Python": 5, "SQL": 5, "Docker": 4})
        result = match_student_to_role(student, role)
        assert 0.0 <= result.match_percentage <= 100.0
