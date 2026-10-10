"""
gemini_service.py — Gemini AI integration for CareerLens V2.

Provides qualitative insights:
  1. explain_career_match  — Narrative summary of student fit for target role
  2. explain_skill_gap     — Explains why a specific skill gap matters in industry
  3. generate_study_advice — Structured study plan guidance for pending roadmap skills

CRITICAL CONSTRAINTS:
  - Gemini AI provides narrative explanations and personalized guidance ONLY.
  - Gemini AI NEVER calculates or modifies numeric match percentages or formulas.
  - Fallback templates guarantee zero downtime when GEMINI_API_KEY is not configured.
"""

from __future__ import annotations

import os
from typing import Optional


def _get_api_key() -> Optional[str]:
    return os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")


def _call_gemini_api(prompt: str, system_instruction: str = "") -> Optional[str]:
    """Call Google Gemini API if key is available, else return None."""
    api_key = _get_api_key()
    if not api_key:
        return None

    try:
        from google import genai
        client = genai.Client(api_key=api_key)
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt,
            config={"system_instruction": system_instruction} if system_instruction else None,
        )
        if response and response.text:
            return response.text.strip()
    except Exception:
        # Fallback to direct REST call if google-genai SDK is not installed
        try:
            import urllib.request
            import json
            url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={api_key}"
            body = {
                "contents": [{"parts": [{"text": prompt}]}]
            }
            if system_instruction:
                body["systemInstruction"] = {"parts": [{"text": system_instruction}]}

            req = urllib.request.Request(
                url,
                data=json.dumps(body).encode("utf-8"),
                headers={"Content-Type": "application/json"}
            )
            with urllib.request.urlopen(req, timeout=10) as res:
                data = json.loads(res.read().decode("utf-8"))
                candidates = data.get("candidates", [])
                if candidates:
                    parts = candidates[0].get("content", {}).get("parts", [])
                    if parts:
                        return parts[0].get("text", "").strip()
        except Exception:
            pass

    return None


def explain_career_match(
    student_name: str,
    role_title: str,
    match_percentage: float,
    matched_skills: list[str],
    missing_skills: list[str],
) -> str:
    """
    Generate an AI explanation of the student's career match.
    Note: Numeric score is passed in as context for narration, not calculated.
    """
    system_instruction = (
        "You are an expert AI Career Advisor for engineering graduates. "
        "Provide encouraging, actionable, and concise narrative feedback on the student's match fit. "
        "Do NOT recalculate or invent any match scores or numbers."
    )

    prompt = (
        f"Student Name: {student_name}\n"
        f"Target Career Role: {role_title}\n"
        f"Calculated Match Fit: {match_percentage}%\n"
        f"Demonstrated Skills: {', '.join(matched_skills) if matched_skills else 'None yet'}\n"
        f"Key Skill Gaps: {', '.join(missing_skills[:5]) if missing_skills else 'None'}\n\n"
        f"Provide a 2-3 paragraph career analysis summarizing their current strengths, "
        f"the impact of their missing skills, and the best first step forward."
    )

    ai_response = _call_gemini_api(prompt, system_instruction)
    if ai_response:
        return ai_response

    # Fallback template
    matched_str = ", ".join(matched_skills) if matched_skills else "foundational academic skills"
    missing_str = ", ".join(missing_skills[:3]) if missing_skills else "advanced specialization topics"

    return (
        f"Great progress! With a {match_percentage}% alignment for the {role_title} role, "
        f"you have built strong competencies in {matched_str}. "
        f"To become production-ready for top engineering openings, prioritize bridging gaps in {missing_str}. "
        f"Following the milestone learning roadmap will give you hands-on practical depth."
    )


def explain_skill_gap(
    role_title: str,
    skill_name: str,
    role_importance: float,
    demand_level: str,
) -> str:
    """Explain why a specific skill gap is critical in the current software industry."""
    system_instruction = (
        "You are an industry technical lead explaining skill requirements to junior engineering students. "
        "Keep the explanation concise (2-3 sentences), practical, and motivating."
    )

    prompt = (
        f"Role: {role_title}\n"
        f"Skill: {skill_name}\n"
        f"Importance Rating: {role_importance}/5\n"
        f"Industry Demand Level: {demand_level}\n\n"
        f"Explain why {skill_name} is essential for a {role_title} in modern production environments."
    )

    ai_response = _call_gemini_api(prompt, system_instruction)
    if ai_response:
        return ai_response

    # Fallback template
    return (
        f"{skill_name} is in {demand_level.lower()} demand for {role_title} positions (importance {int(role_importance)}/5). "
        f"Mastering it enables you to build robust, scalable architectures and directly improves your employability."
    )


def generate_study_advice(
    role_title: str,
    pending_skills: list[str],
) -> str:
    """Generate personalized roadmap schedule guidance."""
    if not pending_skills:
        return f"Congratulations! You have completed all foundational milestones for the {role_title} roadmap. Consider building a capstone project to demonstrate full-stack mastery."

    system_instruction = (
        "You are a technical mentor. Provide a structured 2-step study tip for mastering pending skills."
    )

    prompt = (
        f"Target Role: {role_title}\n"
        f"Pending Skills to Learn: {', '.join(pending_skills)}\n\n"
        f"Provide a brief, practical recommendation on how to sequence and practice these skills effectively."
    )

    ai_response = _call_gemini_api(prompt, system_instruction)
    if ai_response:
        return ai_response

    # Fallback template
    top_skill = pending_skills[0]
    return (
        f"Start by focusing on {top_skill}. Spend 1-2 weeks building small standalone prototypes "
        f"before integrating it into a comprehensive project for {role_title}."
    )
