"""
test_api.py — Integration tests for CareerLens V1 FastAPI routes.
"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import pytest
from fastapi.testclient import TestClient
from main import app
import database

client = TestClient(app)


@pytest.fixture(autouse=True)
def setup_db():
    database.init_db()


def test_create_and_get_profile():
    payload = {
        "name": "Jane Doe",
        "degree": "B.Tech",
        "branch": "Computer Science",
        "year": 3,
        "cgpa": 8.8,
        "skills": [
            {"name": "Python", "proficiency": 4},
            {"name": "SQL", "proficiency": 3},
            {"name": "FastAPI", "proficiency": 3}
        ],
        "projects": [
            {"title": "E-Commerce API", "description": "REST API in FastAPI"}
        ],
        "certifications": [
            {"name": "AWS Certified Cloud Practitioner", "issuer": "Amazon", "year": 2024}
        ]
    }
    res = client.post("/api/profile", json=payload)
    assert res.status_code == 201
    data = res.json()
    assert data["name"] == "Jane Doe"
    student_id = data["id"]

    # GET profile
    get_res = client.get(f"/api/profile/{student_id}")
    assert get_res.status_code == 200
    pdata = get_res.json()
    assert pdata["degree"] == "B.Tech"
    assert len(pdata["skills"]) == 3
    assert len(pdata["projects"]) == 1
    assert len(pdata["certifications"]) == 1


def test_update_profile():
    payload = {
        "name": "John Smith",
        "degree": "B.E.",
        "branch": "IT",
        "year": 2,
        "cgpa": 7.5,
        "skills": [{"name": "Java", "proficiency": 3}]
    }
    res = client.post("/api/profile", json=payload)
    student_id = res.json()["id"]

    update_payload = {
        "cgpa": 8.0,
        "year": 3,
        "skills": [
            {"name": "Java", "proficiency": 4},
            {"name": "Spring Boot", "proficiency": 3}
        ]
    }
    up_res = client.put(f"/api/profile/{student_id}", json=update_payload)
    assert up_res.status_code == 200
    updated = up_res.json()
    assert updated["cgpa"] == 8.0
    assert updated["year"] == 3
    assert len(updated["skills"]) == 2


def test_list_and_get_roles():
    res = client.get("/api/roles")
    assert res.status_code == 200
    roles = res.json()
    assert len(roles) == 8
    role_ids = [r["id"] for r in roles]
    assert "backend_developer" in role_ids
    assert "frontend_developer" in role_ids

    # Detail
    detail_res = client.get("/api/roles/backend_developer")
    assert detail_res.status_code == 200
    detail = detail_res.json()
    assert detail["title"] == "Backend Developer"
    assert len(detail["required_skills"]) > 0


def test_industry_demand():
    res = client.get("/api/industry-demand")
    assert res.status_code == 200
    data = res.json()
    assert "total_jds_analyzed" in data
    assert len(data["skills"]) > 0
    assert data["skills"][0]["demand_level"] in ["High", "Medium", "Low"]

    role_res = client.get("/api/industry-demand/backend_developer")
    assert role_res.status_code == 200
    role_data = role_res.json()
    assert role_data["role_id"] == "backend_developer"


def test_career_match_and_gap():
    # Create student
    payload = {
        "name": "Alex Match",
        "degree": "B.Tech",
        "branch": "CSE",
        "year": 4,
        "cgpa": 9.0,
        "skills": [
            {"name": "Python", "proficiency": 5},
            {"name": "SQL", "proficiency": 4},
            {"name": "REST APIs", "proficiency": 4}
        ]
    }
    c_res = client.post("/api/profile", json=payload)
    student_id = c_res.json()["id"]

    # Match by student_id
    match_payload = {"student_id": student_id, "role_id": "backend_developer"}
    m_res = client.post("/api/match", json=match_payload)
    assert m_res.status_code == 200
    mdata = m_res.json()
    assert mdata["match_percentage"] > 0
    assert "Python" in mdata["matched_skills"]
    assert "Docker" in mdata["missing_skills"]

    # Gap analysis
    g_res = client.get(f"/api/gap/{student_id}/backend_developer")
    assert g_res.status_code == 200
    gdata = g_res.json()
    assert gdata["total_gaps"] > 0
    # Highest priority gaps first
    priorities = [g["gap_priority"] for g in gdata["gaps"]]
    assert priorities == sorted(priorities, reverse=True)


def test_roadmap_endpoint():
    res = client.get("/api/roadmap/backend_developer")
    assert res.status_code == 200
    data = res.json()
    assert data["role_id"] == "backend_developer"
    assert len(data["steps"]) > 0
    assert "resources" in data["steps"][0]
