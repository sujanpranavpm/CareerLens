"""
skill_normalizer.py — Canonical skill name normalization for CareerLens V1.

Responsibilities:
  1. Lower-case and strip whitespace
  2. Resolve common aliases / abbreviations to a canonical name
  3. Used by both skill_extractor (NLP pipeline) and career_matcher (profile comparison)
"""

from __future__ import annotations

# ──────────────────────────────────────────────────────────────────────────────
# ALIAS MAP  alias (lowercase) → canonical display name
# ──────────────────────────────────────────────────────────────────────────────
_ALIAS_MAP: dict[str, str] = {
    # Python ecosystem
    "py": "Python",
    "python3": "Python",
    "python 3": "Python",
    "flask": "Python",      # Flask implies Python; keep Flask separate below
    "django": "Python",     # Same pattern
    # JavaScript
    "js": "JavaScript",
    "javascript": "JavaScript",
    "ecmascript": "JavaScript",
    "es6": "JavaScript",
    "es2015": "JavaScript",
    "vanilla js": "JavaScript",
    "node": "Node.js",
    "nodejs": "Node.js",
    "node.js": "Node.js",
    "node js": "Node.js",
    # TypeScript
    "ts": "TypeScript",
    "typescript": "TypeScript",
    # React
    "react": "React",
    "reactjs": "React",
    "react.js": "React",
    "react js": "React",
    "redux": "React",       # Redux is React-adjacent; treat as React skill signal
    # Vue
    "vue": "Vue.js",
    "vuejs": "Vue.js",
    "vue.js": "Vue.js",
    "vue js": "Vue.js",
    # Angular
    "angular": "Angular",
    "angularjs": "Angular",
    "angular.js": "Angular",
    # Java
    "java": "Java",
    "jvm": "Java",
    "oracle java": "Java",
    "openjdk": "Java",
    # SQL
    "sql": "SQL",
    "structured query language": "SQL",
    "structured query language sql": "SQL",
    "transact-sql": "SQL",
    "t-sql": "SQL",
    "pl/sql": "SQL",
    "oracle pl/sql": "SQL",
    # PostgreSQL
    "postgres": "PostgreSQL",
    "postgresql": "PostgreSQL",
    # MySQL
    "mysql": "MySQL",
    # MongoDB
    "mongo": "MongoDB",
    "mongodb": "MongoDB",
    # Redis
    "redis": "Redis",
    # AWS
    "aws": "AWS",
    "amazon web services": "AWS",
    "amazon web services aws": "AWS",
    "amazon web services aws software": "AWS",
    "aws software": "AWS",
    # Azure
    "azure": "Azure",
    "microsoft azure": "Azure",
    "microsoft azure software": "Azure",
    # Google Cloud
    "gcp": "Google Cloud",
    "google cloud": "Google Cloud",
    "google cloud platform": "Google Cloud",
    "google cloud software": "Google Cloud",
    # Docker
    "docker": "Docker",
    "dockerfile": "Docker",
    # Kubernetes
    "k8s": "Kubernetes",
    "kubernetes": "Kubernetes",
    # Git
    "git": "Git",
    "github": "Git",
    "gitlab": "Git",
    "bitbucket": "Git",
    # Linux
    "linux": "Linux",
    "unix": "Linux",
    "ubuntu": "Linux",
    "debian": "Linux",
    "centos": "Linux",
    "red hat": "Linux",
    "red hat enterprise linux": "Linux",
    # CI/CD
    "ci/cd": "CI/CD",
    "cicd": "CI/CD",
    "ci cd": "CI/CD",
    "jenkins": "CI/CD",
    "github actions": "CI/CD",
    "gitlab ci": "CI/CD",
    "circleci": "CI/CD",
    # Machine Learning
    "ml": "Machine Learning",
    "machine learning": "Machine Learning",
    "deep learning": "Machine Learning",
    "dl": "Machine Learning",
    # Scikit-learn
    "sklearn": "Scikit-learn",
    "scikit-learn": "Scikit-learn",
    "scikit learn": "Scikit-learn",
    # TensorFlow
    "tensorflow": "TensorFlow",
    "tf": "TensorFlow",
    # PyTorch
    "pytorch": "PyTorch",
    "torch": "PyTorch",
    # Pandas
    "pandas": "Pandas",
    # NumPy
    "numpy": "NumPy",
    "np": "NumPy",
    # FastAPI
    "fastapi": "FastAPI",
    "fast api": "FastAPI",
    # Spring Boot
    "spring boot": "Spring Boot",
    "spring": "Spring Boot",
    "spring framework": "Spring Boot",
    # Terraform
    "terraform": "Terraform",
    "hcl": "Terraform",
    # Ansible
    "ansible": "Ansible",
    # Bash
    "bash": "Bash",
    "shell": "Bash",
    "shell scripting": "Bash",
    "bash scripting": "Bash",
    # Penetration Testing
    "pentesting": "Penetration Testing",
    "pen testing": "Penetration Testing",
    "penetration testing": "Penetration Testing",
    "metasploit": "Penetration Testing",
    "burp suite": "Penetration Testing",
    # REST APIs
    "rest": "REST APIs",
    "rest api": "REST APIs",
    "rest apis": "REST APIs",
    "restful": "REST APIs",
    "restful api": "REST APIs",
    "api": "REST APIs",
    # HTML/CSS
    "html": "HTML",
    "html5": "HTML",
    "css": "CSS",
    "css3": "CSS",
    # R
    "r programming": "R",
    "r language": "R",
    # Others kept as-is (canonical form)
    "c++": "C++",
    "c plus plus": "C++",
    "golang": "Go",
    "rust": "Rust",
    "kotlin": "Kotlin",
    "swift": "Swift",
    "nginx": "Nginx",
    "kafka": "Kafka",
    "elasticsearch": "Elasticsearch",
    "graphql": "GraphQL",
    "webpack": "Webpack",
    "figma": "Figma",
    "jupyter": "Jupyter",
    "matlab": "MATLAB",
    "sas": "SAS",
    "tableau": "Tableau",
    "power bi": "Power BI",
}

# Build a reverse lookup from canonical → canonical (identity) as well
_CANONICAL_SET: set[str] = set(_ALIAS_MAP.values())


def normalize(skill: str) -> str:
    """
    Return the canonical skill name for a given raw skill string.

    Steps:
      1. Strip whitespace
      2. Lowercase lookup in alias map
      3. If not found, title-case the stripped input and return as-is

    >>> normalize("py")
    'Python'
    >>> normalize("K8s")
    'Kubernetes'
    >>> normalize("  JavaScript  ")
    'JavaScript'
    >>> normalize("unknown_tool")
    'Unknown_tool'
    """
    stripped = skill.strip()
    key = stripped.lower()
    if key in _ALIAS_MAP:
        return _ALIAS_MAP[key]
    # Preserve casing if already canonical
    if stripped in _CANONICAL_SET:
        return stripped
    # Title-case unknown skills for consistent display
    return stripped.title() if stripped.islower() else stripped


def normalize_list(skills: list[str]) -> list[str]:
    """Normalize a list of skill strings, preserving order and removing empty entries."""
    return [normalize(s) for s in skills if s.strip()]


def is_known_skill(skill: str) -> bool:
    """Return True if the skill (after normalization) is in the known canonical set."""
    return normalize(skill) in _CANONICAL_SET
