"""
roadmap_engine.py — Rule-based career learning roadmap generator.

Produces a step-by-step roadmap for a given career role.
Steps are ordered by the role_roadmaps config in learning_resources.json.
Each step is enriched with curated learning resources.
"""

from __future__ import annotations

import json
import os
from typing import Optional

_DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data")
_RESOURCES_PATH = os.path.join(_DATA_DIR, "learning_resources.json")

_resources_cache: Optional[dict] = None


def _load_resources() -> dict:
    global _resources_cache
    if _resources_cache is None:
        with open(_RESOURCES_PATH, "r", encoding="utf-8") as f:
            _resources_cache = json.load(f)
    return _resources_cache



def _roadmap_step(skill: str, step_num: int, resources_for_skill: list) -> dict:
    return {
        "step": step_num,
        "skill": skill,
        "resources": resources_for_skill,
    }


def get_roadmap(role_id: str) -> dict:
    """
    Return the learning roadmap for a career role.

    Args:
        role_id: One of the 8 V1 role IDs (e.g. "backend_developer").

    Returns:
        dict with keys:
          - role_id
          - description
          - steps: list of {step, skill, resources}
          - total_steps

    If the role_id is not found, returns an empty roadmap dict.
    """
    data = _load_resources()
    roadmaps = data.get("role_roadmaps", {})
    resources = data.get("resources", {})

    if role_id not in roadmaps:
        return {
            "role_id": role_id,
            "description": "",
            "steps": [],
            "total_steps": 0,
        }

    role_roadmap = roadmaps[role_id]
    skill_steps = role_roadmap.get("steps", [])
    description = role_roadmap.get("description", "")

    steps = []
    for i, skill in enumerate(skill_steps, start=1):
        skill_resources = resources.get(skill, [])
        steps.append({
            "step": i,
            "skill": skill,
            "resources": skill_resources,
        })

    return {
        "role_id": role_id,
        "description": description,
        "steps": steps,
        "total_steps": len(steps),
    }


def get_personalized_roadmap(
    role_id: str,
    missing_skills: list[str],
    developing_skills: list[str],
) -> dict:
    """
    Return a roadmap filtered to skills the student still needs to learn,
    but preserving the original ordering from the role roadmap.

    Skills already matched by the student are marked as completed.

    Args:
        role_id:          The target career role.
        missing_skills:   Canonical skill names the student is missing.
        developing_skills: Canonical skill names being developed (partial).

    Returns:
        Same structure as get_roadmap() but each step has an additional
        ``status`` field: "completed" | "developing" | "missing"
    """
    full_roadmap = get_roadmap(role_id)
    needs_attention = set(missing_skills) | set(developing_skills)
    data = _load_resources()
    resources = data.get("resources", {})

    steps = []
    for i, skill in enumerate(
        full_roadmap.get("steps", []), start=1
    ):
        # full_roadmap steps are already dicts; extract skill name
        skill_name = skill["skill"] if isinstance(skill, dict) else skill

        if skill_name in set(missing_skills):
            status = "missing"
        elif skill_name in set(developing_skills):
            status = "developing"
        else:
            status = "completed"

        steps.append({
            "step": i,
            "skill": skill_name,
            "status": status,
            "resources": resources.get(skill_name, []),
        })

    return {
        "role_id": role_id,
        "description": full_roadmap.get("description", ""),
        "steps": steps,
        "total_steps": len(steps),
        "pending_steps": sum(1 for s in steps if s["status"] != "completed"),
    }
