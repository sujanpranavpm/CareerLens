"""
test_v2_features.py — Unit and integration tests for CareerLens V2 features.
"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import pytest
from fastapi.testclient import TestClient
from main import app
import database
from modules import gemini_service, youtube_service, trend_analyzer

client = TestClient(app)


@pytest.fixture(autouse=True)
def setup_db():
    database.init_db()


# ──────────────────────────────────────────────────────────────────────────────
# GEMINI SERVICE TESTS
# ──────────────────────────────────────────────────────────────────────────────

def test_gemini_explain_career_match():
    explanation = gemini_service.explain_career_match(
        student_name="Test Student",
        role_title="Backend Developer",
        match_percentage=75.0,
        matched_skills=["Python", "SQL"],
        missing_skills=["Docker", "AWS"],
    )
    assert isinstance(explanation, str)
    assert len(explanation) > 20
    assert "75.0" in explanation or "Backend Developer" in explanation


def test_gemini_explain_skill_gap():
    explanation = gemini_service.explain_skill_gap(
        role_title="Backend Developer",
        skill_name="Docker",
        role_importance=4.0,
        demand_level="High",
    )
    assert isinstance(explanation, str)
    assert "Docker" in explanation
    assert "Backend Developer" in explanation


def test_gemini_study_advice():
    advice = gemini_service.generate_study_advice(
        role_title="Backend Developer",
        pending_skills=["Docker", "Kubernetes"],
    )
    assert isinstance(advice, str)
    assert len(advice) > 15


# ──────────────────────────────────────────────────────────────────────────────
# YOUTUBE SERVICE TESTS
# ──────────────────────────────────────────────────────────────────────────────

def test_youtube_video_search_and_caching():
    skill = "Docker"
    videos = youtube_service.search_youtube_videos(skill, max_results=2)
    assert isinstance(videos, list)
    assert len(videos) >= 1
    assert "title" in videos[0]
    assert "url" in videos[0]

    # Verify cached in SQLite
    cached = database.get_cached_youtube_videos(skill)
    assert cached is not None
    assert len(cached) == len(videos)


# ──────────────────────────────────────────────────────────────────────────────
# TREND ANALYZER TESTS
# ──────────────────────────────────────────────────────────────────────────────

def test_trend_analyzer():
    mock_jds = [
        {"role_id": "backend_developer", "text": "We need Python, Docker, AWS, and Kubernetes."},
        {"role_id": "backend_developer", "text": "Strong Python and SQL required. Git experience."},
        {"role_id": "backend_developer", "text": "Python, Docker, Linux, and PostgreSQL expertise."}
    ]
    trends = trend_analyzer.analyze_industry_trends(mock_jds)
    assert isinstance(trends, list)
    assert len(trends) > 0
    assert "skill" in trends[0]
    assert "change_percentage" in trends[0]
    assert "trend_direction" in trends[0]
    assert trends[0]["trend_direction"] in ["rising", "emerging", "stable", "declining"]


# ──────────────────────────────────────────────────────────────────────────────
# PROGRESS TRACKING & RECALCULATION TESTS
# ──────────────────────────────────────────────────────────────────────────────

def test_roadmap_progress_toggle_and_gap_recalculation():
    # 1. Create a student with missing Docker skill
    p_res = client.post("/api/profile", json={
        "name": "Progress Tester",
        "degree": "B.Tech",
        "branch": "CSE",
        "year": 3,
        "cgpa": 8.5,
        "skills": [{"name": "Python", "proficiency": 4}]
    })
    student_id = p_res.json()["id"]

    # 2. Check initial gaps (Docker should be a gap)
    gaps_before = client.get(f"/api/gap/{student_id}/backend_developer").json()
    assert any(g["skill"] == "Docker" for g in gaps_before["gaps"])

    # 3. Toggle Docker to completed in roadmap
    toggle_res = client.post(
        f"/api/progress/{student_id}/backend_developer/toggle",
        json={"skill_name": "Docker", "completed": True}
    )
    assert toggle_res.status_code == 200
    assert toggle_res.json()["completed"] is True
    assert toggle_res.json()["total_completed"] >= 1

    # 4. Check updated progress endpoint
    prog_res = client.get(f"/api/progress/{student_id}/backend_developer").json()
    assert "Docker" in prog_res["completed_skills"]
    assert prog_res["completion_percentage"] > 0

    # 5. Check gaps after toggle (Docker should no longer be in gaps!)
    gaps_after = client.get(f"/api/gap/{student_id}/backend_developer").json()
    assert not any(g["skill"] == "Docker" for g in gaps_after["gaps"])
    assert gaps_after["total_gaps"] < gaps_before["total_gaps"]


# ──────────────────────────────────────────────────────────────────────────────
# V2 API ROUTE INTEGRATION TESTS
# ──────────────────────────────────────────────────────────────────────────────

def test_explain_endpoints():
    p_res = client.post("/api/profile", json={
        "name": "Explain Student",
        "degree": "B.Tech",
        "branch": "IT",
        "year": 4,
        "cgpa": 9.0,
        "skills": [{"name": "Python", "proficiency": 5}]
    })
    student_id = p_res.json()["id"]

    # Explain Match
    res1 = client.post("/api/explain/match", json={
        "student_id": student_id,
        "role_id": "backend_developer"
    })
    assert res1.status_code == 200
    assert "explanation" in res1.json()

    # Explain Gap
    res2 = client.post("/api/explain/gap", json={
        "role_id": "backend_developer",
        "skill_name": "Docker"
    })
    assert res2.status_code == 200
    assert "explanation" in res2.json()

    # Explain Roadmap
    res3 = client.post("/api/explain/roadmap", json={
        "role_id": "backend_developer",
        "student_id": student_id
    })
    assert res3.status_code == 200
    assert "advice" in res3.json()


def test_youtube_videos_endpoint():
    res = client.get("/api/resources/videos/PostgreSQL")
    assert res.status_code == 200
    data = res.json()
    assert data["skill"] == "PostgreSQL"
    assert len(data["videos"]) > 0


def test_industry_trends_endpoint():
    res = client.get("/api/industry-trends")
    assert res.status_code == 200
    data = res.json()
    assert len(data["trends"]) > 0
    assert "change_percentage" in data["trends"][0]
