"""
skill_extractor.py — Extract and normalize technical skills from job description text.

Uses spaCy for tokenization/lemmatization + the O*NET software_skills.csv taxonomy
as the primary lookup, augmented by the skill_normalizer alias map.

V1 Design Decisions:
  - Uses spaCy en_core_web_sm (small model, no GPU required)
  - Exact and bigram/trigram phrase matching against the taxonomy
  - Falls back to alias map for abbreviated terms
  - Returns a sorted list of unique canonical skill names found in the text
"""

from __future__ import annotations

import functools
import re
from collections import Counter
from typing import Optional

import spacy

from modules.skill_normalizer import normalize, _ALIAS_MAP

# ──────────────────────────────────────────────────────────────────────────────
# TAXONOMY LOADING
# ──────────────────────────────────────────────────────────────────────────────

# Canonical skills drawn from software_skills.csv + career_roles.json
# This is the lookup set used during extraction.
# Loaded once at module import.

_TAXONOMY_PHRASES: list[str] = [
    # Languages
    "Python", "Java", "JavaScript", "TypeScript", "Go", "Rust", "C++", "Kotlin",
    "Swift", "R", "MATLAB", "SAS", "Scala", "PHP", "Ruby", "Perl",
    # Web Frontend
    "React", "Vue.js", "Angular", "HTML", "CSS", "Webpack", "Figma",
    # Web Backend / Frameworks
    "Node.js", "FastAPI", "Django", "Flask", "Spring Boot", "Express",
    "Ruby on Rails", "Laravel",
    # Databases
    "SQL", "PostgreSQL", "MySQL", "MongoDB", "Redis", "SQLite",
    "Oracle", "Cassandra", "Elasticsearch", "DynamoDB",
    # Cloud
    "AWS", "Azure", "Google Cloud", "GCP",
    # DevOps / Infra
    "Docker", "Kubernetes", "Terraform", "Ansible", "Jenkins",
    "GitHub Actions", "GitLab CI", "Nginx", "Linux", "Bash",
    "CI/CD", "Git",
    # Data Science / ML
    "Machine Learning", "Deep Learning", "TensorFlow", "PyTorch",
    "Scikit-learn", "Pandas", "NumPy", "Jupyter",
    "Statistics", "Data Visualization", "Big Data",
    # Security
    "Cybersecurity", "Penetration Testing", "Cryptography",
    "Firewalls", "SIEM", "Networking",
    # Other
    "REST APIs", "GraphQL", "Kafka", "Tableau", "Power BI",
    "Agile", "Scrum", "Docker Compose", "Microservices",
]

# Build lowercase → canonical lookup for the taxonomy
_TAXONOMY_MAP: dict[str, str] = {}
for _phrase in _TAXONOMY_PHRASES:
    _TAXONOMY_MAP[_phrase.lower()] = _phrase

# Merge alias map into taxonomy lookup (alias keys → canonical values)
for _alias, _canon in _ALIAS_MAP.items():
    if _alias not in _TAXONOMY_MAP:
        _TAXONOMY_MAP[_alias] = _canon


@functools.lru_cache(maxsize=1)
def _load_nlp():
    """Load the spaCy model (cached, loaded once per process)."""
    try:
        return spacy.load("en_core_web_sm")
    except OSError:
        raise RuntimeError(
            "spaCy model 'en_core_web_sm' not found. "
            "Run: python -m spacy download en_core_web_sm"
        )


# ──────────────────────────────────────────────────────────────────────────────
# CORE EXTRACTION
# ──────────────────────────────────────────────────────────────────────────────

def _clean_text(text: str) -> str:
    """Light cleaning: collapse whitespace, normalize punctuation."""
    text = re.sub(r"\s+", " ", text)
    text = text.replace("\n", " ").replace("\r", " ")
    return text.strip()


def extract_skills(text: str, min_count: int = 1) -> list[str]:
    """
    Extract and normalize technical skills from raw text.

    Algorithm:
      1. Clean and tokenize with spaCy
      2. Try trigram, bigram, then unigram window matches against taxonomy
      3. Deduplicate, normalize, and return sorted canonical skill names

    Args:
        text:      Raw job description or profile text.
        min_count: Minimum number of times a skill must appear (default 1).

    Returns:
        Sorted list of unique canonical skill names found in the text.

    >>> "Python" in extract_skills("We need Python and SQL experience.")
    True
    >>> "JavaScript" in extract_skills("Strong JS and React skills required.")
    True
    """
    if not text or not text.strip():
        return []

    nlp = _load_nlp()
    text_clean = _clean_text(text)

    # Also run raw alias matching on the full text (handles "K8s", "py", etc.)
    found_counts: Counter = Counter()

    # Pass 1 — alias/phrase scan on raw text (case-insensitive)
    text_lower = text_clean.lower()
    for alias, canonical in _TAXONOMY_MAP.items():
        # Use word-boundary matching for short tokens to avoid false positives
        pattern = r"\b" + re.escape(alias) + r"\b"
        if re.search(pattern, text_lower):
            found_counts[canonical] += 1

    # Pass 2 — spaCy token lemma scan (catches inflected forms)
    doc = nlp(text_clean)
    tokens = [t.text for t in doc if not t.is_space]
    for i, tok in enumerate(tokens):
        # Try trigram
        if i + 2 < len(tokens):
            trigram = " ".join(tokens[i: i + 3]).lower()
            if trigram in _TAXONOMY_MAP:
                found_counts[_TAXONOMY_MAP[trigram]] += 1
        # Try bigram
        if i + 1 < len(tokens):
            bigram = " ".join(tokens[i: i + 2]).lower()
            if bigram in _TAXONOMY_MAP:
                found_counts[_TAXONOMY_MAP[bigram]] += 1
        # Unigram
        unigram = tok.lower()
        if unigram in _TAXONOMY_MAP:
            found_counts[_TAXONOMY_MAP[unigram]] += 1

    return sorted(
        skill for skill, count in found_counts.items() if count >= min_count
    )


def extract_skills_with_frequency(text: str) -> dict[str, int]:
    """
    Like extract_skills but returns a dict mapping canonical skill name → occurrence count.

    Useful for computing industry demand scores.
    """
    if not text or not text.strip():
        return {}

    nlp = _load_nlp()
    text_clean = _clean_text(text)
    text_lower = text_clean.lower()

    found_counts: Counter = Counter()

    for alias, canonical in _TAXONOMY_MAP.items():
        pattern = r"\b" + re.escape(alias) + r"\b"
        matches = re.findall(pattern, text_lower)
        if matches:
            found_counts[canonical] += len(matches)

    doc = nlp(text_clean)
    tokens = [t.text for t in doc if not t.is_space]
    for i, tok in enumerate(tokens):
        if i + 2 < len(tokens):
            trigram = " ".join(tokens[i: i + 3]).lower()
            if trigram in _TAXONOMY_MAP:
                found_counts[_TAXONOMY_MAP[trigram]] += 1
        if i + 1 < len(tokens):
            bigram = " ".join(tokens[i: i + 2]).lower()
            if bigram in _TAXONOMY_MAP:
                found_counts[_TAXONOMY_MAP[bigram]] += 1
        if tok.lower() in _TAXONOMY_MAP:
            found_counts[_TAXONOMY_MAP[tok.lower()]] += 1

    return dict(found_counts)


def compute_demand_from_jds(job_descriptions: list[dict]) -> dict[str, dict]:
    """
    Given a list of JD dicts (each with a 'text' key), aggregate skill frequency
    across all JDs and return demand level per skill.

    Demand levels:
      High   — skill appears in ≥50% of JDs
      Medium — skill appears in 25%–49% of JDs
      Low    — skill appears in 1%–24% of JDs

    Returns:
        dict mapping skill_name → {
            "demand_level": "High"|"Medium"|"Low",
            "frequency": int (number of JDs mentioning this skill),
            "percentage": float
        }
    """
    total_jds = len(job_descriptions)
    if total_jds == 0:
        return {}

    skill_jd_count: Counter = Counter()
    for jd in job_descriptions:
        skills_in_jd = set(extract_skills(jd.get("text", "")))
        for skill in skills_in_jd:
            skill_jd_count[skill] += 1

    result: dict[str, dict] = {}
    for skill, count in skill_jd_count.items():
        pct = count / total_jds
        if pct >= 0.50:
            level = "High"
        elif pct >= 0.25:
            level = "Medium"
        else:
            level = "Low"
        result[skill] = {
            "demand_level": level,
            "frequency": count,
            "percentage": round(pct * 100, 1),
        }

    return result
