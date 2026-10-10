"""
main.py — FastAPI application and API routes for CareerLens V2.

V1 Endpoints:
  POST /api/profile                     — Create student profile
  PUT  /api/profile/{id}                — Update student profile
  GET  /api/profile/{id}                — Get student profile
  GET  /api/roles                       — List all 8 career roles
  GET  /api/roles/{role_id}             — Get role details + required skills
  GET  /api/industry-demand             — Aggregated skill demand from mock JDs
  GET  /api/industry-demand/{role_id}   — Demand filtered by specific role
  POST /api/match                       — Career match (cosine similarity)
  GET  /api/gap/{student_id}/{role_id}  — Skill gap analysis
  GET  /api/roadmap/{role_id}           — Rule-based learning roadmap

V2 New Endpoints:
  POST /api/explain/match               — Gemini AI match narrative explanation
  POST /api/explain/gap                 — Gemini AI skill gap rationale
  POST /api/explain/roadmap             — Gemini AI personalized study advice
  GET  /api/resources/videos/{skill}    — YouTube Data API tutorials (cached & fallback)
  GET  /api/progress/{student_id}/{role_id} — Get milestone progress & completion %
  POST /api/progress/{student_id}/{role_id}/toggle — Toggle milestone completion
  GET  /api/industry-trends             — Industry trends with delta changes
  GET  /api/industry-trends/{role_id}   — Role-specific industry trends
"""

from __future__ import annotations

import json
import os
from contextlib import asynccontextmanager
from typing import List, Optional

# Load .env file automatically (if python-dotenv is installed)
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass  # python-dotenv not installed; rely on OS environment variables

from fastapi import FastAPI, HTTPException, Query, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
from pydantic import BaseModel, Field

import database
from modules import (
    career_matcher,
    gap_analyzer,
    gemini_service,
    roadmap_engine,
    skill_extractor,
    skill_normalizer,
    trend_analyzer,
    youtube_service,
)

# ──────────────────────────────────────────────────────────────────────────────
# LIFESPAN & APP INIT
# ──────────────────────────────────────────────────────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Initialize DB tables on startup
    database.init_db()
    yield


app = FastAPI(
    title="CareerLens V2 API",
    description="Industry-Skill Demand Aggregator & Automated Career Path Mapping with Gemini AI & YouTube Learning",
    version="2.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/", response_class=HTMLResponse)
def root_dashboard():
    return """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>CareerLens V2 — API Dashboard</title>
        <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700;800&display=swap" rel="stylesheet">
        <style>
            * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Plus Jakarta Sans', sans-serif; }
            body { background: #0b0f19; color: #f8fafc; display: flex; justify-content: center; align-items: center; min-height: 100vh; padding: 24px; }
            .card { background: #131b2e; border: 1px solid #1e293b; border-radius: 24px; max-width: 720px; width: 100%; padding: 40px; box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5); }
            .badge { display: inline-flex; align-items: center; gap: 6px; background: rgba(37, 99, 235, 0.15); color: #60a5fa; border: 1px solid rgba(96, 165, 250, 0.3); padding: 4px 12px; border-radius: 20px; font-size: 13px; font-weight: 700; margin-bottom: 16px; }
            h1 { font-size: 32px; font-weight: 800; letter-spacing: -0.5px; margin-bottom: 8px; background: linear-gradient(135deg, #ffffff, #94a3b8); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
            p.sub { color: #94a3b8; font-size: 15px; line-height: 1.5; margin-bottom: 32px; }
            .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin-bottom: 28px; }
            .btn { display: flex; align-items: center; justify-content: space-between; padding: 16px 20px; border-radius: 14px; text-decoration: none; font-weight: 700; font-size: 14px; transition: all 0.2s; }
            .btn-primary { background: #2563eb; color: #ffffff; }
            .btn-primary:hover { background: #1d4ed8; transform: translateY(-2px); }
            .btn-secondary { background: #1e293b; color: #f8fafc; border: 1px solid #334155; }
            .btn-secondary:hover { background: #334155; border-color: #475569; transform: translateY(-2px); }
            .endpoints { background: #0f172a; border-radius: 16px; padding: 20px; border: 1px solid #1e293b; }
            .endpoints h3 { font-size: 14px; color: #64748b; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 12px; }
            .link-row { display: flex; justify-content: space-between; align-items: center; padding: 8px 0; border-bottom: 1px solid #1e293b; font-size: 13px; }
            .link-row:last-child { border-bottom: none; }
            .link-row a { color: #38bdf8; text-decoration: none; font-family: monospace; font-size: 13px; }
            .link-row a:hover { text-decoration: underline; }
            .status-dot { width: 8px; height: 8px; background: #22c55e; border-radius: 50%; display: inline-block; box-shadow: 0 0 10px #22c55e; }
        </style>
    </head>
    <body>
        <div class="card">
            <div class="badge"><span class="status-dot"></span> Backend Live & Operational</div>
            <h1>CareerLens V2 API</h1>
            <p class="sub">Industry-Skill Demand Aggregator with Automated Career Path Mapping, Gemini AI Insights, and YouTube Tutorials for Engineering Graduates.</p>
            
            <div class="grid">
                <a href="/docs" class="btn btn-primary">
                    <span>Interactive Swagger Docs</span>
                    <span>→</span>
                </a>
                <a href="/redoc" class="btn btn-secondary">
                    <span>ReDoc Documentation</span>
                    <span>→</span>
                </a>
            </div>

            <div class="endpoints">
                <h3>Quick Test Endpoints</h3>
                <div class="link-row">
                    <span>All 8 O*NET Career Roles:</span>
                    <a href="/api/roles" target="_blank">/api/roles</a>
                </div>
                <div class="link-row">
                    <span>Industry Skill Demand:</span>
                    <a href="/api/industry-demand" target="_blank">/api/industry-demand</a>
                </div>
                <div class="link-row">
                    <span>Industry Skill Trends (V2):</span>
                    <a href="/api/industry-trends" target="_blank">/api/industry-trends</a>
                </div>
                <div class="link-row">
                    <span>Backend Developer Roadmap:</span>
                    <a href="/api/roadmap/backend_developer" target="_blank">/api/roadmap/backend_developer</a>
                </div>
                <div class="link-row">
                    <span>YouTube Video Learning (V2):</span>
                    <a href="/api/resources/videos/Docker" target="_blank">/api/resources/videos/Docker</a>
                </div>
            </div>
        </div>
    </body>
    </html>
    """


# Data paths
_DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")
_ROLES_FILE = os.path.join(_DATA_DIR, "career_roles.json")
_MOCK_JDS_FILE = os.path.join(_DATA_DIR, "mock_job_descriptions.json")


def _load_career_roles() -> list[dict]:
    with open(_ROLES_FILE, "r", encoding="utf-8") as f:
        return json.load(f)


def _load_mock_jds() -> list[dict]:
    with open(_MOCK_JDS_FILE, "r", encoding="utf-8") as f:
        data = json.load(f)
        if isinstance(data, dict):
            return data.get("job_descriptions", [])
        return data


# ──────────────────────────────────────────────────────────────────────────────
# PYDANTIC SCHEMAS
# ──────────────────────────────────────────────────────────────────────────────

class SkillIn(BaseModel):
    name: str
    proficiency: int = Field(ge=1, le=5)


class ProjectIn(BaseModel):
    title: str
    description: Optional[str] = ""


class CertificationIn(BaseModel):
    name: str
    issuer: Optional[str] = ""
    year: Optional[int] = None


class ProfileCreateRequest(BaseModel):
    name: str
    degree: str
    branch: str
    year: int = Field(ge=1, le=5)
    cgpa: float = Field(ge=0.0, le=10.0)
    skills: List[SkillIn] = []
    projects: List[ProjectIn] = []
    certifications: List[CertificationIn] = []


class ProfileUpdateRequest(BaseModel):
    name: Optional[str] = None
    degree: Optional[str] = None
    branch: Optional[str] = None
    year: Optional[int] = Field(default=None, ge=1, le=5)
    cgpa: Optional[float] = Field(default=None, ge=0.0, le=10.0)
    skills: Optional[List[SkillIn]] = None
    projects: Optional[List[ProjectIn]] = None
    certifications: Optional[List[CertificationIn]] = None


class MatchRequest(BaseModel):
    student_id: Optional[int] = None
    role_id: str
    skills: Optional[List[SkillIn]] = None


class ExplainMatchRequest(BaseModel):
    student_id: int
    role_id: str


class ExplainGapRequest(BaseModel):
    role_id: str
    skill_name: str


class ExplainRoadmapRequest(BaseModel):
    role_id: str
    student_id: Optional[int] = None


class ToggleProgressRequest(BaseModel):
    skill_name: str
    completed: Optional[bool] = None


# ──────────────────────────────────────────────────────────────────────────────
# ROUTES: STUDENT PROFILE
# ──────────────────────────────────────────────────────────────────────────────

@app.post("/api/profile", status_code=status.HTTP_201_CREATED)
def create_profile(payload: ProfileCreateRequest):
    student_id = database.create_student(
        name=payload.name,
        degree=payload.degree,
        branch=payload.branch,
        year=payload.year,
        cgpa=payload.cgpa,
    )

    if payload.skills:
        database.upsert_skills(
            student_id,
            [{"name": s.name, "proficiency": s.proficiency} for s in payload.skills],
        )

    if payload.projects:
        database.replace_projects(
            student_id,
            [{"title": p.title, "description": p.description} for p in payload.projects],
        )

    if payload.certifications:
        database.replace_certifications(
            student_id,
            [{"name": c.name, "issuer": c.issuer, "year": c.year} for c in payload.certifications],
        )

    return get_profile(student_id)


@app.put("/api/profile/{student_id}")
def update_profile(student_id: int, payload: ProfileUpdateRequest):
    existing = database.get_student(student_id)
    if not existing:
        raise HTTPException(status_code=404, detail=f"Student profile #{student_id} not found")

    fields = {}
    if payload.name is not None:
        fields["name"] = payload.name
    if payload.degree is not None:
        fields["degree"] = payload.degree
    if payload.branch is not None:
        fields["branch"] = payload.branch
    if payload.year is not None:
        fields["year"] = payload.year
    if payload.cgpa is not None:
        fields["cgpa"] = payload.cgpa

    if fields:
        database.update_student(student_id, **fields)

    if payload.skills is not None:
        database.upsert_skills(
            student_id,
            [{"name": s.name, "proficiency": s.proficiency} for s in payload.skills],
        )

    if payload.projects is not None:
        database.replace_projects(
            student_id,
            [{"title": p.title, "description": p.description} for p in payload.projects],
        )

    if payload.certifications is not None:
        database.replace_certifications(
            student_id,
            [{"name": c.name, "issuer": c.issuer, "year": c.year} for c in payload.certifications],
        )

    return get_profile(student_id)


@app.get("/api/profile/{student_id}")
def get_profile(student_id: int):
    student = database.get_student(student_id)
    if not student:
        raise HTTPException(status_code=404, detail=f"Student profile #{student_id} not found")

    skills = database.get_skills(student_id)
    projects = database.get_projects(student_id)
    certs = database.get_certifications(student_id)

    return {
        "id": student["id"],
        "name": student["name"],
        "degree": student["degree"],
        "branch": student["branch"],
        "year": student["year"],
        "cgpa": student["cgpa"],
        "created_at": student.get("created_at"),
        "updated_at": student.get("updated_at"),
        "skills": skills,
        "projects": projects,
        "certifications": certs,
    }


# ──────────────────────────────────────────────────────────────────────────────
# ROUTES: CAREER ROLES
# ──────────────────────────────────────────────────────────────────────────────

@app.get("/api/roles")
def list_roles():
    roles = _load_career_roles()
    return [
        {
            "id": r["id"],
            "title": r["title"],
            "onet_code": r.get("onet_code", ""),
            "description": r.get("description", ""),
            "skill_count": len(r.get("required_skills", [])),
        }
        for r in roles
    ]


@app.get("/api/roles/{role_id}")
def get_role_detail(role_id: str):
    roles = _load_career_roles()
    for r in roles:
        if r["id"] == role_id:
            return r
    raise HTTPException(status_code=404, detail=f"Role '{role_id}' not found")


# ──────────────────────────────────────────────────────────────────────────────
# ROUTES: INDUSTRY DEMAND & TRENDS (V2)
# ──────────────────────────────────────────────────────────────────────────────

@app.get("/api/industry-demand")
def get_industry_demand():
    jds = _load_mock_jds()
    demand = skill_extractor.compute_demand_from_jds(jds)
    result = []
    for skill_name, stats in demand.items():
        result.append({
            "skill": skill_name,
            "demand_level": stats["demand_level"],
            "frequency": stats["frequency"],
            "percentage": stats["percentage"],
        })
    result.sort(key=lambda x: (-x["frequency"], x["skill"]))
    return {
        "total_jds_analyzed": len(jds),
        "skills": result,
    }


@app.get("/api/industry-demand/{role_id}")
def get_role_industry_demand(role_id: str):
    jds = _load_mock_jds()
    role_jds = [j for j in jds if j.get("role_id") == role_id]
    if not role_jds:
        roles = _load_career_roles()
        if not any(r["id"] == role_id for r in roles):
            raise HTTPException(status_code=404, detail=f"Role '{role_id}' not found")

    demand = skill_extractor.compute_demand_from_jds(role_jds)
    result = []
    for skill_name, stats in demand.items():
        result.append({
            "skill": skill_name,
            "demand_level": stats["demand_level"],
            "frequency": stats["frequency"],
            "percentage": stats["percentage"],
        })
    result.sort(key=lambda x: (-x["frequency"], x["skill"]))
    return {
        "role_id": role_id,
        "total_jds_analyzed": len(role_jds),
        "skills": result,
    }


@app.get("/api/industry-trends")
def get_industry_trends(role_id: Optional[str] = Query(None)):
    jds = _load_mock_jds()
    trends = trend_analyzer.analyze_industry_trends(jds, role_id=role_id)
    return {
        "role_id": role_id or "all",
        "total_jds_analyzed": len(jds) if not role_id else len([j for j in jds if j.get("role_id") == role_id]),
        "trends": trends,
    }


# ──────────────────────────────────────────────────────────────────────────────
# ROUTES: CAREER MATCH & GAP ANALYSIS
# ──────────────────────────────────────────────────────────────────────────────

@app.post("/api/match")
def match_career(payload: MatchRequest):
    roles = _load_career_roles()
    role = next((r for r in roles if r["id"] == payload.role_id), None)
    if not role:
        raise HTTPException(status_code=404, detail=f"Role '{payload.role_id}' not found")

    if payload.skills is not None:
        student_skills = [{"name": s.name, "proficiency": s.proficiency} for s in payload.skills]
    elif payload.student_id is not None:
        student = database.get_student(payload.student_id)
        if not student:
            raise HTTPException(status_code=404, detail=f"Student #{payload.student_id} not found")
        db_skills = database.get_skills(payload.student_id)
        student_skills = [{"name": s["skill_name"], "proficiency": s["proficiency"]} for s in db_skills]
    else:
        raise HTTPException(status_code=400, detail="Must provide either student_id or skills list")

    match_result = career_matcher.match_student_to_role(
        student_skills=student_skills,
        role_required_skills=role.get("required_skills", []),
    )

    return {
        "role_id": payload.role_id,
        "role_title": role["title"],
        "match_percentage": match_result.match_percentage,
        "matched_skills": match_result.matched_skills,
        "developing_skills": match_result.developing_skills,
        "missing_skills": match_result.missing_skills,
    }


@app.get("/api/gap/{student_id}/{role_id}")
def get_skill_gap(student_id: int, role_id: str):
    student = database.get_student(student_id)
    if not student:
        raise HTTPException(status_code=404, detail=f"Student #{student_id} not found")

    roles = _load_career_roles()
    role = next((r for r in roles if r["id"] == role_id), None)
    if not role:
        raise HTTPException(status_code=404, detail=f"Role '{role_id}' not found")

    db_skills = database.get_skills(student_id)
    student_skills = [{"name": s["skill_name"], "proficiency": s["proficiency"]} for s in db_skills]

    # Incorporate user-toggled roadmap completions into student skills
    progress = database.get_roadmap_progress(student_id, role_id)
    completed_skills = {p["skill_name"].lower() for p in progress if p["completed"] == 1}

    # Add dynamically completed roadmap skills to student skills with max proficiency
    for s_name in completed_skills:
        if not any(s["name"].lower() == s_name for s in student_skills):
            student_skills.append({"name": s_name, "proficiency": 5})

    jds = _load_mock_jds()
    demand = skill_extractor.compute_demand_from_jds(jds)

    gaps = gap_analyzer.compute_skill_gaps(
        student_skills=student_skills,
        role_required_skills=role.get("required_skills", []),
        industry_demand=demand,
    )

    return {
        "student_id": student_id,
        "role_id": role_id,
        "role_title": role["title"],
        "total_gaps": len(gaps),
        "gaps": gap_analyzer.gaps_to_dict(gaps),
    }


# ──────────────────────────────────────────────────────────────────────────────
# ROUTES: ROADMAP & PROGRESS TRACKING (V2)
# ──────────────────────────────────────────────────────────────────────────────

@app.get("/api/roadmap/{role_id}")
def get_career_roadmap(role_id: str, student_id: Optional[int] = Query(None)):
    roles = _load_career_roles()
    role = next((r for r in roles if r["id"] == role_id), None)
    if not role:
        raise HTTPException(status_code=404, detail=f"Role '{role_id}' not found")

    if student_id is not None:
        student = database.get_student(student_id)
        if not student:
            raise HTTPException(status_code=404, detail=f"Student #{student_id} not found")

        db_skills = database.get_skills(student_id)
        student_skills = [{"name": s["skill_name"], "proficiency": s["proficiency"]} for s in db_skills]

        # Check user-toggled progress
        progress = database.get_roadmap_progress(student_id, role_id)
        toggled_completed = {p["skill_name"].lower() for p in progress if p["completed"] == 1}

        match_res = career_matcher.match_student_to_role(
            student_skills=student_skills,
            role_required_skills=role.get("required_skills", []),
        )

        roadmap = roadmap_engine.get_personalized_roadmap(
            role_id=role_id,
            missing_skills=match_res.missing_skills,
            developing_skills=match_res.developing_skills,
        )

        # Merge toggled completions
        for step in roadmap.get("steps", []):
            if step["skill"].lower() in toggled_completed:
                step["status"] = "completed"

        completed_count = sum(1 for s in roadmap.get("steps", []) if s["status"] == "completed")
        roadmap["pending_steps"] = len(roadmap.get("steps", [])) - completed_count
        roadmap["completion_percentage"] = round((completed_count / max(1, len(roadmap.get("steps", [])))) * 100, 1)
    else:
        roadmap = roadmap_engine.get_roadmap(role_id)
        roadmap["completion_percentage"] = 0.0

    roadmap["role_title"] = role["title"]
    return roadmap


@app.get("/api/progress/{student_id}/{role_id}")
def get_student_progress(student_id: int, role_id: str):
    student = database.get_student(student_id)
    if not student:
        raise HTTPException(status_code=404, detail=f"Student #{student_id} not found")

    progress = database.get_roadmap_progress(student_id, role_id)
    roadmap = roadmap_engine.get_roadmap(role_id)
    total_steps = roadmap.get("total_steps", 0)

    completed_skills = [p["skill_name"] for p in progress if p["completed"] == 1]
    completed_count = len(completed_skills)

    pct = round((completed_count / max(1, total_steps)) * 100, 1) if total_steps > 0 else 0.0

    return {
        "student_id": student_id,
        "role_id": role_id,
        "total_steps": total_steps,
        "completed_count": completed_count,
        "completion_percentage": min(100.0, pct),
        "completed_skills": completed_skills,
        "progress_records": progress,
    }


@app.post("/api/progress/{student_id}/{role_id}/toggle")
def toggle_student_progress(student_id: int, role_id: str, payload: ToggleProgressRequest):
    student = database.get_student(student_id)
    if not student:
        raise HTTPException(status_code=404, detail=f"Student #{student_id} not found")

    result = database.toggle_roadmap_skill(
        student_id=student_id,
        role_id=role_id,
        skill_name=payload.skill_name,
        completed=payload.completed,
    )

    # Return updated progress status
    updated_progress = get_student_progress(student_id, role_id)
    result["total_completed"] = updated_progress["completed_count"]
    result["completion_percentage"] = updated_progress["completion_percentage"]
    return result


# ──────────────────────────────────────────────────────────────────────────────
# ROUTES: YOUTUBE LEARNING RESOURCES (V2)
# ──────────────────────────────────────────────────────────────────────────────

@app.get("/api/resources/videos/{skill_name}")
def get_skill_videos(skill_name: str, max_results: int = Query(3, ge=1, le=10)):
    videos = youtube_service.search_youtube_videos(skill_name=skill_name, max_results=max_results)
    return {
        "skill": skill_name,
        "total_videos": len(videos),
        "videos": videos,
    }


# ──────────────────────────────────────────────────────────────────────────────
# ROUTES: GEMINI AI EXPLANATIONS (V2)
# ──────────────────────────────────────────────────────────────────────────────

@app.post("/api/explain/match")
def explain_match(payload: ExplainMatchRequest):
    student = database.get_student(payload.student_id)
    if not student:
        raise HTTPException(status_code=404, detail=f"Student #{payload.student_id} not found")

    roles = _load_career_roles()
    role = next((r for r in roles if r["id"] == payload.role_id), None)
    if not role:
        raise HTTPException(status_code=404, detail=f"Role '{payload.role_id}' not found")

    db_skills = database.get_skills(payload.student_id)
    student_skills = [{"name": s["skill_name"], "proficiency": s["proficiency"]} for s in db_skills]

    match_res = career_matcher.match_student_to_role(
        student_skills=student_skills,
        role_required_skills=role.get("required_skills", []),
    )

    narrative = gemini_service.explain_career_match(
        student_name=student["name"],
        role_title=role["title"],
        match_percentage=match_res.match_percentage,
        matched_skills=match_res.matched_skills,
        missing_skills=match_res.missing_skills,
    )

    return {
        "role_id": payload.role_id,
        "role_title": role["title"],
        "match_percentage": match_res.match_percentage,
        "explanation": narrative,
    }


@app.post("/api/explain/gap")
def explain_gap(payload: ExplainGapRequest):
    roles = _load_career_roles()
    role = next((r for r in roles if r["id"] == payload.role_id), None)
    if not role:
        raise HTTPException(status_code=404, detail=f"Role '{payload.role_id}' not found")

    # Find importance in role
    importance = 3.0
    for s in role.get("required_skills", []):
        if s["name"].lower() == payload.skill_name.lower():
            importance = float(s.get("importance", 3.0))
            break

    jds = _load_mock_jds()
    demand = skill_extractor.compute_demand_from_jds(jds)
    demand_info = demand.get(payload.skill_name, {})
    demand_level = demand_info.get("demand_level", "Medium")

    explanation = gemini_service.explain_skill_gap(
        role_title=role["title"],
        skill_name=payload.skill_name,
        role_importance=importance,
        demand_level=demand_level,
    )

    return {
        "skill": payload.skill_name,
        "role_title": role["title"],
        "importance": importance,
        "demand_level": demand_level,
        "explanation": explanation,
    }


@app.post("/api/explain/roadmap")
def explain_roadmap(payload: ExplainRoadmapRequest):
    roles = _load_career_roles()
    role = next((r for r in roles if r["id"] == payload.role_id), None)
    if not role:
        raise HTTPException(status_code=404, detail=f"Role '{payload.role_id}' not found")

    pending_skills: list[str] = []
    if payload.student_id:
        roadmap = get_career_roadmap(payload.role_id, student_id=payload.student_id)
        pending_skills = [s["skill"] for s in roadmap.get("steps", []) if s.get("status") != "completed"]
    else:
        roadmap = roadmap_engine.get_roadmap(payload.role_id)
        pending_skills = [s["skill"] for s in roadmap.get("steps", [])]

    advice = gemini_service.generate_study_advice(
        role_title=role["title"],
        pending_skills=pending_skills,
    )

    return {
        "role_id": payload.role_id,
        "role_title": role["title"],
        "pending_skills_count": len(pending_skills),
        "advice": advice,
    }
