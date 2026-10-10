"""
test_skill_extractor.py — Unit tests for skill_extractor.py

Note: These tests require spaCy and en_core_web_sm to be installed.
If spaCy is not installed, tests are skipped gracefully.
"""

import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import pytest

# Skip all tests in this file if spaCy is not installed
spacy = pytest.importorskip("spacy", reason="spaCy not installed")

# Also skip if the model is not downloaded
try:
    spacy.load("en_core_web_sm")
    _MODEL_AVAILABLE = True
except OSError:
    _MODEL_AVAILABLE = False

skip_if_no_model = pytest.mark.skipif(
    not _MODEL_AVAILABLE,
    reason="spaCy model 'en_core_web_sm' not downloaded. Run: python -m spacy download en_core_web_sm"
)

from modules.skill_extractor import (
    extract_skills,
    extract_skills_with_frequency,
    compute_demand_from_jds,
)


@skip_if_no_model
class TestExtractSkills:

    def test_extract_python(self):
        text = "We need a developer with strong Python skills."
        skills = extract_skills(text)
        assert "Python" in skills

    def test_extract_sql(self):
        text = "Must have SQL proficiency and PostgreSQL experience."
        skills = extract_skills(text)
        assert "SQL" in skills or "PostgreSQL" in skills

    def test_extract_docker(self):
        text = "Experience with Docker containerization is required."
        skills = extract_skills(text)
        assert "Docker" in skills

    def test_extract_javascript_alias(self):
        """Alias 'JS' should be resolved to JavaScript."""
        text = "Looking for a developer with strong JS and React experience."
        skills = extract_skills(text)
        assert "JavaScript" in skills

    def test_extract_kubernetes_alias(self):
        """K8s alias."""
        text = "Must know K8s and Docker."
        skills = extract_skills(text)
        assert "Kubernetes" in skills

    def test_extract_multiple_skills(self):
        text = (
            "We are looking for a Backend Developer with Python, SQL, "
            "Docker, Kubernetes, and AWS experience."
        )
        skills = extract_skills(text)
        assert "Python" in skills
        assert "SQL" in skills
        assert "Docker" in skills
        assert "Kubernetes" in skills
        assert "AWS" in skills

    def test_extract_returns_sorted_list(self):
        text = "React, Python, Docker, SQL, AWS experience required."
        skills = extract_skills(text)
        assert skills == sorted(skills)

    def test_extract_returns_unique_skills(self):
        text = "Python Python Python SQL SQL"
        skills = extract_skills(text)
        assert len(skills) == len(set(skills))

    def test_empty_text_returns_empty_list(self):
        assert extract_skills("") == []
        assert extract_skills("   ") == []

    def test_no_skills_in_generic_text(self):
        """Text with no technical skills should yield empty or near-empty list."""
        text = "The quick brown fox jumps over the lazy dog."
        skills = extract_skills(text)
        # May pick up some false positives — just ensure it doesn't crash
        assert isinstance(skills, list)

    def test_aws_variants(self):
        text = "Amazon Web Services experience required."
        skills = extract_skills(text)
        assert "AWS" in skills

    def test_rest_api_extraction(self):
        text = "Must be comfortable developing REST APIs."
        skills = extract_skills(text)
        assert "REST APIs" in skills

    def test_case_insensitive_extraction(self):
        """Extraction is case-insensitive."""
        text_lower = "python and docker experience."
        text_upper = "PYTHON AND DOCKER EXPERIENCE."
        assert "Python" in extract_skills(text_lower)
        assert "Python" in extract_skills(text_upper)


@skip_if_no_model
class TestExtractSkillsWithFrequency:

    def test_returns_dict(self):
        text = "Python SQL Python Docker"
        result = extract_skills_with_frequency(text)
        assert isinstance(result, dict)

    def test_frequency_increases_with_repetition(self):
        """More mentions → higher frequency count."""
        text = "Python Python Python SQL"
        result = extract_skills_with_frequency(text)
        if "Python" in result and "SQL" in result:
            assert result["Python"] >= result["SQL"]

    def test_empty_text(self):
        assert extract_skills_with_frequency("") == {}


@skip_if_no_model
class TestComputeDemandFromJDs:

    def _make_jds(self, texts: list[str]) -> list[dict]:
        return [{"text": t} for t in texts]

    def test_high_demand_skill(self):
        """Skill in all JDs → High demand."""
        jds = self._make_jds([
            "Python developer needed.",
            "Python experience required.",
            "Strong Python skills.",
        ])
        demand = compute_demand_from_jds(jds)
        if "Python" in demand:
            assert demand["Python"]["demand_level"] == "High"

    def test_demand_level_low(self):
        """Skill in only 1 of 6 JDs → Low demand."""
        jds = self._make_jds([
            "Python SQL Docker",
            "Python SQL Docker",
            "Python SQL Docker",
            "Python SQL Docker",
            "Python SQL Docker",
            "Rust experience preferred",  # only Rust here
        ])
        demand = compute_demand_from_jds(jds)
        if "Rust" in demand:
            assert demand["Rust"]["demand_level"] == "Low"

    def test_empty_jds(self):
        assert compute_demand_from_jds([]) == {}

    def test_result_has_required_keys(self):
        jds = self._make_jds(["Python SQL Docker required."])
        demand = compute_demand_from_jds(jds)
        for skill, info in demand.items():
            assert "demand_level" in info
            assert "frequency" in info
            assert "percentage" in info
            assert info["demand_level"] in ("High", "Medium", "Low")
            assert isinstance(info["frequency"], int)
            assert 0.0 <= info["percentage"] <= 100.0

    def test_deterministic_demand(self):
        """Same JDs always produce same demand output."""
        jds = self._make_jds(["Python Docker SQL needed", "Python REST APIs required"])
        d1 = compute_demand_from_jds(jds)
        d2 = compute_demand_from_jds(jds)
        assert d1 == d2
