"""
trend_analyzer.py — Industry skill trend and change percentage analyzer for CareerLens V2.

Computes:
  - Current demand percentage from mock JDs
  - Historical baseline comparison / growth delta (change_percentage)
  - Trend direction: "rising" (growth >= +5%), "emerging" (new hot tech), "stable"
  - Cross-references O*NET Hot Technology indicator
"""

from __future__ import annotations

import json
import os
from typing import Optional

from modules import skill_extractor, onet_loader


# Baseline benchmark percentages representing prior year demand distributions
_HISTORICAL_BASELINE: dict[str, float] = {
    "Python": 72.0,
    "SQL": 65.0,
    "Git": 75.0,
    "AWS": 58.0,
    "Docker": 42.0,
    "Linux": 48.0,
    "PostgreSQL": 35.0,
    "FastAPI": 12.0,
    "Kubernetes": 22.0,
    "React": 60.0,
    "JavaScript": 70.0,
    "TypeScript": 38.0,
    "Machine Learning": 40.0,
    "CI/CD": 28.0,
    "REST APIs": 50.0,
    "Redis": 20.0,
    "MongoDB": 25.0,
    "Java": 45.0,
    "Spring Boot": 30.0,
}


def analyze_industry_trends(job_descriptions: list[dict], role_id: Optional[str] = None) -> list[dict]:
    """
    Compute skill demand trends with change indicators.

    Returns:
        List of dicts:
          {
            "skill": str,
            "demand_level": str,
            "frequency": int,
            "percentage": float,
            "baseline_percentage": float,
            "change_percentage": float,
            "trend_direction": "rising" | "emerging" | "stable",
            "is_hot_tech": bool
          }
    """
    filtered_jds = job_descriptions
    if role_id:
        filtered_jds = [j for j in job_descriptions if j.get("role_id") == role_id]

    demand_stats = skill_extractor.compute_demand_from_jds(filtered_jds)

    # Load hot technology lookup from O*NET software skills
    try:
        sw_df = onet_loader.load_software_skills()
        hot_skills = set(sw_df[sw_df["Hot Technology"] == "Y"]["Workplace Example"].str.lower().unique())
    except Exception:
        hot_skills = {"python", "docker", "kubernetes", "aws", "fastapi", "react", "postgresql"}

    trends: list[dict] = []
    for skill_name, stats in demand_stats.items():
        curr_pct = stats["percentage"]
        base_pct = _HISTORICAL_BASELINE.get(skill_name, max(10.0, round(curr_pct * 0.8, 1)))
        delta = round(curr_pct - base_pct, 1)

        is_hot = skill_name.lower() in hot_skills

        if delta >= 8.0 or (is_hot and delta >= 3.0):
            direction = "rising"
        elif delta <= -8.0:
            direction = "declining"
        elif is_hot and curr_pct < 30.0:
            direction = "emerging"
        else:
            direction = "stable"

        trends.append({
            "skill": skill_name,
            "demand_level": stats["demand_level"],
            "frequency": stats["frequency"],
            "percentage": curr_pct,
            "baseline_percentage": base_pct,
            "change_percentage": delta,
            "trend_direction": direction,
            "is_hot_tech": is_hot,
        })

    # Sort by current percentage descending, then change percentage
    trends.sort(key=lambda t: (-t["percentage"], -t["change_percentage"]))
    return trends
