# CareerLens V2 — Project Status

> **Status:** Feature Complete · 92/92 Tests Passing · Ready for Demo
> **Last Updated:** 2026-09-20

---

## 1. Architecture Overview

```
CareerLens V2
├── careerlens_backend/          # FastAPI backend (Python 3.12)
│   ├── main.py                  # 18 REST API endpoints (V1 + V2)
│   ├── database.py              # SQLite ORM
│   ├── modules/
│   │   ├── career_matcher.py    # Cosine-similarity skill matching
│   │   ├── gap_analyzer.py      # Priority-scored skill gap computation
│   │   ├── gemini_service.py    # Gemini AI explanations (with fallback)
│   │   ├── roadmap_engine.py    # Rule-based learning roadmaps
│   │   ├── skill_extractor.py   # JD parsing and demand computation
│   │   ├── skill_normalizer.py  # Alias normalization (py->Python, k8s->Kubernetes)
│   │   ├── trend_analyzer.py    # Industry trend deltas (rising/stable/declining)
│   │   └── youtube_service.py   # YouTube Data API v3 + SQLite cache + fallback
│   └── tests/                   # 92 tests across 6 test files
│
└── careerlens_app/              # Flutter Android app (Dart 3, Material 3)
    └── lib/
        ├── main.dart            # Obsidian Neural theme + 3-tab navigation
        ├── screens/
        │   ├── profile_screen.dart      # Student profile CRUD
        │   ├── career_roles_screen.dart # 8 O*NET roles + detail modal
        │   ├── career_match_screen.dart # Match gauge + Gemini AI insights [V2]
        │   ├── skill_gap_screen.dart    # Priority gaps + AI explanation modal [V2]
        │   ├── roadmap_screen.dart      # Progress tracking + YouTube + AI advice [V2]
        │   └── skill_demand_screen.dart # Current demand + Industry Trends tab [V2]
        ├── models/              # Typed Dart models for all API responses
        ├── services/
        │   └── api_service.dart # HTTP client for all 18 endpoints
        └── widgets/
            ├── roadmap_step_card.dart  # Timeline card (status icon, expand/collapse)
            ├── video_card.dart         # YouTube thumbnail card
            ├── match_gauge.dart        # Circular arc progress gauge
            ├── skill_chip.dart         # Matched/Developing/Missing chips
            └── demand_badge.dart       # High/Medium/Low demand pill
```

---

## 2. V2 Feature Completion Matrix

| Feature | Backend | Flutter UI | Integration |
|---|---|---|---|
| Gemini AI match explanation | /api/explain/match | CareerMatchScreen AI card | Connected |
| Gemini AI skill-gap rationale | /api/explain/gap | SkillGapScreen bottom sheet | Connected |
| Gemini AI study advice | /api/explain/roadmap | RoadmapScreen advice banner | Connected |
| YouTube learning resources | /api/resources/videos/{skill} | Horizontal video carousel | Connected |
| Roadmap progress tracking | /api/progress/{student}/{role} | Checkbox per step + live % | Connected |
| Progress toggle (persist) | /api/progress/.../toggle | Checkbox -> API -> UI reload | Connected |
| Industry Trends (V2) | /api/industry-trends | SegmentedButton Trends tab | Connected |
| Role-filtered trends | /api/industry-trends?role_id=X | FilterChip role selector | Connected |
| Gap recalculation after toggle | Completed skills excluded from gaps | Roadmap -> SkillGap flow | Connected |

---

## 3. Test Results

```
======================== 92 passed, 1 warning in 6.18s ========================

tests/test_api.py             6 tests  -- V1 endpoints (profile, roles, match, gap, roadmap)
tests/test_career_matcher.py 14 tests  -- Cosine similarity, normalization, edge cases
tests/test_gap_analyzer.py   14 tests  -- Priority formula, sorting, alias, edge cases
tests/test_skill_extractor.py 21 tests -- JD parsing, demand computation, determinism
tests/test_skill_normalizer.py 26 tests-- Alias normalization, whitespace, unknown skills
tests/test_v2_features.py     9 tests  -- Gemini, YouTube, Trends, Progress toggle, Explain APIs
```

Warning (non-breaking): httpx deprecation notice from starlette.testclient; production code unaffected.

---

## 4. Run Instructions

### Backend (FastAPI)

```bash
cd careerlens_backend
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Optional environment variables (features degrade gracefully without them):

```bash
set GEMINI_API_KEY=your-key-here       # Enables real Gemini AI responses
set YOUTUBE_API_KEY=your-key-here      # Enables live YouTube search
```

- API dashboard: http://localhost:8000
- Swagger UI: http://localhost:8000/docs

### Run Tests

```bash
cd careerlens_backend
python -m pytest tests/ -v
```

### Flutter App

```bash
cd careerlens_app
flutter pub get
flutter run   # Android Emulator connects to http://10.0.2.2:8000 by default
```

Connect to backend (use the gear icon in the top-right corner of the app):

| Target | URL |
|---|---|
| Android Emulator | http://10.0.2.2:8000 (default) |
| Physical Device | http://<YOUR_PC_LAN_IP>:8000 |
| Desktop/Web | http://127.0.0.1:8000 |

---

## 5. End-to-End User Flow

1. Profile Tab  -> Enter name, degree, branch, year, CGPA, skills, projects, certs
                   -> Save Profile -> POST /api/profile -> stores student_id locally

2. Career Roles -> Browse 8 O*NET-aligned roles
                   -> Tap role -> detail modal (skills + importance scores)
                   -> "Analyze AI Match Fit" -> CareerMatchScreen

3. Career Match -> Cosine similarity gauge (0-100%)
                   -> Gemini AI narrative explanation (async, with fallback)
                   -> Matched / Developing / Missing skill chips
                   -> Buttons: Skill Gap Analysis | Learning Roadmap

4. Skill Gap    -> Prioritized gaps (Priority = Importance x Demand Score)
                   -> Tap any gap -> AI explanation bottom sheet (Gemini)
                   -> "Learn on Roadmap" -> RoadmapScreen

5. Roadmap      -> Timeline steps (completed/developing/missing icons)
                   -> Gemini AI study advice banner
                   -> YouTube video carousel (click any step or "Videos" button)
                   -> Checkbox per step -> toggles /api/progress -> live % update
                   -> Completed skills automatically excluded from gap analysis

6. Skill Demand -> "Current Demand" tab: bar chart of skill frequency across JDs
                   -> "Industry Trends (V2)" tab: rising/emerging/stable/declining
                   -> Role filter chips narrow data by specific career role

---

## 6. Known Issues

| Issue | Severity | Notes |
|---|---|---|
| httpx deprecation warning in tests | Low | Install httpx2 to silence; no code change needed |
| withOpacity() deprecation (Flutter 3.27+) | Low | Use withValues(alpha:) in a future cleanup pass |
| YouTube fallback thumbnails | Low | Unsplash stock images used when no API key is set |
| Gemini fallback text | Info | Template responses returned without GEMINI_API_KEY; HTTP 200 always returned |
| SQLite instead of PostgreSQL | Design | Single-user demo; migrate to PostgreSQL for production |
| No authentication | Design | Out of V2 scope; planned for V3 with Firebase Auth |

---

## 7. V1 Preservation

All V1 endpoints remain fully functional and unchanged. 6/6 V1 integration tests green.

---

## 8. Obsidian Neural Theme Palette

| Token | Hex | Usage |
|---|---|---|
| Deep Space Black | #090D16 | Scaffold background |
| Dark Obsidian | #111827 | Card surfaces |
| Midnight | #0B0F19 | Navigation bar |
| Border | #1E293B | Card borders, dividers |
| Electric Indigo | #6366F1 | Primary, buttons, accents |
| Neural Violet | #8B5CF6 | Secondary |
| Soft Indigo | #818CF8 | Selected icons, highlights |
| Lavender | #C7D2FE | AI card headings |
| Text Primary | #F8FAFC | Main text |
| Text Secondary | #94A3B8 | Subtitles, labels |
| Text Muted | #64748B | Captions, hints |
| Emerald | #10B981 | Completed state |
| Amber | #F59E0B | Developing / Warning |
| Rose | #EF4444 | Missing / YouTube |
| Cyan | #06B6D4 | O*NET codes |
