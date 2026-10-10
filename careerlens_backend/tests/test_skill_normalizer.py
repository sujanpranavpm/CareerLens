"""
test_skill_normalizer.py — Unit tests for skill_normalizer.py
"""

import sys
import os

# Allow imports from parent package
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import pytest
from modules.skill_normalizer import normalize, normalize_list, is_known_skill


class TestNormalize:
    """Tests for the normalize() function."""

    def test_exact_canonical_passthrough(self):
        """Known canonical names pass through unchanged."""
        assert normalize("Python") == "Python"
        assert normalize("JavaScript") == "JavaScript"
        assert normalize("Docker") == "Docker"
        assert normalize("React") == "React"

    def test_alias_py_to_python(self):
        assert normalize("py") == "Python"

    def test_alias_js_to_javascript(self):
        assert normalize("js") == "JavaScript"

    def test_alias_k8s_to_kubernetes(self):
        assert normalize("k8s") == "Kubernetes"
        assert normalize("K8s") == "Kubernetes"

    def test_alias_aws_variants(self):
        assert normalize("amazon web services") == "AWS"
        assert normalize("Amazon Web Services") == "AWS"
        assert normalize("aws") == "AWS"

    def test_alias_sql_variants(self):
        assert normalize("sql") == "SQL"
        assert normalize("transact-sql") == "SQL"
        assert normalize("t-sql") == "SQL"
        assert normalize("structured query language") == "SQL"

    def test_alias_git_variants(self):
        assert normalize("github") == "Git"
        assert normalize("gitlab") == "Git"
        assert normalize("git") == "Git"

    def test_alias_linux_variants(self):
        assert normalize("ubuntu") == "Linux"
        assert normalize("centos") == "Linux"
        assert normalize("unix") == "Linux"

    def test_alias_react_variants(self):
        assert normalize("reactjs") == "React"
        assert normalize("react.js") == "React"
        assert normalize("react js") == "React"

    def test_alias_node_variants(self):
        assert normalize("node") == "Node.js"
        assert normalize("nodejs") == "Node.js"
        assert normalize("node.js") == "Node.js"

    def test_alias_cicd_variants(self):
        assert normalize("jenkins") == "CI/CD"
        assert normalize("github actions") == "CI/CD"
        assert normalize("cicd") == "CI/CD"

    def test_alias_ml_variants(self):
        assert normalize("ml") == "Machine Learning"
        assert normalize("deep learning") == "Machine Learning"

    def test_alias_sklearn(self):
        assert normalize("sklearn") == "Scikit-learn"
        assert normalize("scikit learn") == "Scikit-learn"

    def test_alias_postgres(self):
        assert normalize("postgres") == "PostgreSQL"

    def test_alias_mongo(self):
        assert normalize("mongo") == "MongoDB"

    def test_whitespace_stripping(self):
        assert normalize("  Python  ") == "Python"
        assert normalize("\tDocker\n") == "Docker"

    def test_case_insensitive_alias(self):
        assert normalize("PYTHON3") == "Python"
        assert normalize("Pandas") == "Pandas"

    def test_unknown_skill_title_cased(self):
        """Unknown lowercase skills are title-cased."""
        result = normalize("myunknowntool")
        assert result == "Myunknowntool"

    def test_unknown_skill_mixed_case_preserved(self):
        """Unknown skills with mixed case are returned as-is."""
        result = normalize("MyCustomLib")
        assert result == "MyCustomLib"

    def test_empty_string(self):
        """Empty string returns empty string (after title-case)."""
        assert normalize("") == ""

    def test_rest_api_variants(self):
        assert normalize("rest") == "REST APIs"
        assert normalize("restful api") == "REST APIs"
        assert normalize("api") == "REST APIs"


class TestNormalizeList:
    def test_basic_list(self):
        result = normalize_list(["py", "js", "docker"])
        assert "Python" in result
        assert "JavaScript" in result
        assert "Docker" in result

    def test_empty_strings_removed(self):
        result = normalize_list(["Python", "", "   ", "Docker"])
        assert "" not in result
        assert len(result) == 2

    def test_order_preserved(self):
        result = normalize_list(["Docker", "Python", "SQL"])
        assert result == ["Docker", "Python", "SQL"]


class TestIsKnownSkill:
    def test_known_skills(self):
        assert is_known_skill("Python") is True
        assert is_known_skill("py") is True
        assert is_known_skill("k8s") is True

    def test_unknown_skill(self):
        assert is_known_skill("myrandomtool123") is False
