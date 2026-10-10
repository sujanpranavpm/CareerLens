"""Smoke test for all V1 + V2 API endpoints."""
import urllib.request
import json

BASE = "http://127.0.0.1:8000"
results = []

def get(path):
    with urllib.request.urlopen(BASE + path, timeout=10) as r:
        return json.loads(r.read())

def post(path, data):
    req = urllib.request.Request(
        BASE + path,
        data=json.dumps(data).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=10) as r:
        return json.loads(r.read())

def check(label, fn):
    try:
        result = fn()
        results.append((label, "PASS", result))
        return result
    except Exception as e:
        results.append((label, "FAIL", str(e)))
        return None

# ── V1 Endpoints ──────────────────────────────────────────────────────────────
roles = check("GET /api/roles", lambda: f"{len(get('/api/roles'))} roles")
demand = check("GET /api/industry-demand", lambda: f"{len(get('/api/industry-demand')['skills'])} skills")

# Create profile
profile_data = {
    "name": "Smoke Test Student",
    "degree": "B.Tech",
    "branch": "Computer Science",
    "year": 3,
    "cgpa": 8.0,
    "skills": [{"name": "Python", "proficiency": 4}, {"name": "SQL", "proficiency": 3}],
    "projects": [],
    "certifications": [],
}
profile = check("POST /api/profile", lambda: post("/api/profile", profile_data))
student_id = None
if profile and isinstance(profile, dict) and "id" in profile:
    student_id = None
    # result is string description; re-run to get actual id
    p2 = post("/api/profile", profile_data)
    student_id = p2.get("id")

if student_id:
    check("GET /api/profile/:id", lambda: f"name={get(f'/api/profile/{student_id}')['name']}")
    
    match = check("POST /api/match", lambda: (
        lambda r: f"{r['match_percentage']}%"
    )(post("/api/match", {"student_id": student_id, "role_id": "software_developer"})))
    
    check("GET /api/gap/:id/:role", lambda: (
        lambda r: f"{r['total_gaps']} gaps"
    )(get(f"/api/gap/{student_id}/software_developer")))
    
    check("GET /api/roadmap/:role?student_id", lambda: (
        lambda r: f"{len(r['steps'])} steps"
    )(get(f"/api/roadmap/software_developer?student_id={student_id}")))

# ── V2 Endpoints ──────────────────────────────────────────────────────────────
check("GET /api/industry-trends", lambda: f"{len(get('/api/industry-trends')['trends'])} trends")

check("GET /api/resources/videos/Python", lambda: (
    lambda r: f"{len(r['videos'])} videos (cached={r.get('cached', '?')})"
)(get("/api/resources/videos/Python")))

if student_id:
    check("POST /api/explain/match", lambda: (
        lambda r: f"explanation len={len(r['explanation'])}"
    )(post("/api/explain/match", {"student_id": student_id, "role_id": "software_developer"})))

    check("POST /api/explain/gap", lambda: (
        lambda r: f"explanation len={len(r['explanation'])}"
    )(post("/api/explain/gap", {"role_id": "software_developer", "skill_name": "Python"})))

    check("POST /api/explain/roadmap", lambda: (
        lambda r: f"advice len={len(r['advice'])}"
    )(post("/api/explain/roadmap", {"role_id": "software_developer", "student_id": student_id})))

    check("GET /api/progress/:id/:role", lambda: (
        lambda r: f"completion={r['completion_percentage']}%"
    )(get(f"/api/progress/{student_id}/software_developer")))

    check("POST /api/progress/toggle", lambda: (
        lambda r: f"toggled, completion={r.get('new_completion_percentage', '?')}%"
    )(post(f"/api/progress/{student_id}/software_developer/toggle", {"skill_name": "Python", "completed": True})))

# Print summary
print("\n========== SMOKE TEST RESULTS ==========")
passed = sum(1 for _, s, _ in results if s == "PASS")
failed = sum(1 for _, s, _ in results if s == "FAIL")
for label, status, detail in results:
    icon = "OK" if status == "PASS" else "!!"
    print(f"  [{icon}] {status:4} | {label}")
    print(f"           {detail}")
print(f"\n  Total: {passed} PASS | {failed} FAIL")
