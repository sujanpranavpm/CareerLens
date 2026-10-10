# CareerLens V1 🔭
### Industry-Skill Demand Aggregator with Automated Career Path Mapping for Engineering Graduates

CareerLens V1 transforms traditional career advisory into an automated, data-grounded intelligence platform. It bridges the gap between engineering academia and industry requirements by analyzing real occupational taxonomy (**O*NET 31.0**), curating industry skill demand, determining cosine similarity career readiness, computing formula-weighted skill gaps, and generating milestone learning roadmaps.

---

## 🏗️ Architecture & Tech Stack

```
CareerLens/
├── careerlens_backend/          # FastAPI REST Backend & Intelligence Engines
│   ├── main.py                  # FastAPI routes & Pydantic models
│   ├── database.py              # SQLite schema, WAL mode, foreign keys, CRUD
│   ├── requirements.txt         # Backend dependencies
│   ├── modules/
│   │   ├── onet_loader.py       # O*NET 31.0 occupational & software skills loader
│   │   ├── skill_normalizer.py  # Canonical alias resolution & normalization
│   │   ├── skill_extractor.py   # spaCy NLP skill extractor & JD frequency aggregator
│   │   ├── career_matcher.py    # Deterministic Cosine Similarity matcher
│   │   ├── gap_analyzer.py      # Formula: Priority = Importance × Demand Score
│   │   └── roadmap_engine.py    # Milestone-based learning roadmap generator
│   ├── data/
│   │   ├── onet/                # Extracted O*NET 31.0 CSV dataset
│   │   ├── career_roles.json    # 8 target engineering roles & skill weights
│   │   ├── mock_job_descriptions.json # Industry mock JDs for demand aggregation
│   │   └── learning_resources.json    # Free curated learning resources per skill
│   └── tests/                   # 83+ Unit & API integration tests (100% passing)
│
└── careerlens_app/              # Flutter Android Mobile Application
    ├── lib/
    │   ├── main.dart            # Theme, Material 3 UI, bottom navigation
    │   ├── models/              # Dart data models (Profile, Role, Demand, Match, Gap)
    │   ├── services/            # ApiService client with environment-aware baseURL
    │   ├── screens/             # 6 Feature screens
    │   │   ├── profile_screen.dart
    │   │   ├── career_roles_screen.dart
    │   │   ├── skill_demand_screen.dart
    │   │   ├── career_match_screen.dart
    │   │   ├── skill_gap_screen.dart
    │   │   └── roadmap_screen.dart
    │   └── widgets/             # Reusable UI components
    │       ├── skill_chip.dart
    │       ├── match_gauge.dart
    │       ├── demand_badge.dart
    │       └── roadmap_step_card.dart
    └── android/                 # Android project manifest & configuration
```

---

## 🎯 V1 Core Features

1. **Student Profile Management**
   - Captures Name, Degree, Branch, Year of Study, CGPA.
   - Dynamic technical skill list with 1–5 proficiency ratings.
   - Project showcase (Title, description, tech stack) & Certifications (Issuer, Year).

2. **O*NET 31.0 Aligned Career Roles**
   - 8 core engineering roles (`Backend Developer`, `Frontend Developer`, `Full Stack Developer`, `Data Scientist`, `DevOps Engineer`, `Database Administrator`, `Information Security Engineer`, `Computer Systems Analyst`).
   - Mapped to official Standard Occupational Classification (SOC 15-xxxx) with required skill importance ratings (1–5).

3. **Industry Skill Demand Aggregation**
   - Natural language skill extraction via spaCy NLP and taxonomy phrase matching.
   - Aggregates frequency and classifies demand into **High** (≥50% JDs), **Medium** (25–49%), and **Low** (<25%).
   - Transparent mock data disclaimer for academic clarity.

4. **Deterministic Career Matching**
   - Computes student-to-role fit using vector cosine similarity ($0.0 - 100.0\%$).
   - Categorizes skills into **Matched** ($\ge 60\%$ importance threshold), **Developing** (present but below threshold), and **Missing** (unacquired).

5. **Impact-Weighted Skill Gap Analysis**
   - Prioritizes gaps using the formula:
     $$\text{Gap Priority} = \text{Role Importance} \times \text{Industry Demand Score}$$
   - Identifies highest-ROI skills to learn first.

6. **Milestone Learning Roadmap**
   - Ordered learning steps enriched with curated free learning resources (documentation, interactive courses, tutorials) with estimated completion times.

---

## 🚀 Getting Started

### 1. Running the FastAPI Backend

```bash
# Navigate to backend directory
cd careerlens_backend

# Install dependencies
pip install -r requirements.txt

# Download spaCy model
python -m spacy download en_core_web_sm

# Start FastAPI server
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

The interactive Swagger API documentation will be available at:
👉 **[http://localhost:8000/docs](http://localhost:8000/docs)**

### 2. Running Backend Tests

```bash
# Run the complete test suite (83 tests)
python -m pytest careerlens_backend/tests/ -v
```

### 3. Running the Flutter Android App

```bash
# Navigate to mobile app directory
cd careerlens_app

# Fetch Flutter dependencies
flutter pub get

# Run on connected Android device or emulator
flutter run
```

*Note: For Android emulators, the app automatically connects to `http://10.0.2.2:8000`. You can also tap the Settings icon in the app bar to customize the backend URL.*

---

## 📡 REST API Summary

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/profile` | Create student profile with skills, projects, and certifications |
| `PUT` | `/api/profile/{id}` | Update student profile and skill proficiencies |
| `GET` | `/api/profile/{id}` | Retrieve complete student profile |
| `GET` | `/api/roles` | List all 8 O*NET aligned career roles |
| `GET` | `/api/roles/{role_id}` | Get role details and weighted required skills |
| `GET` | `/api/industry-demand` | Get aggregated industry skill demand from JDs |
| `GET` | `/api/industry-demand/{role_id}` | Get skill demand filtered by career role |
| `POST` | `/api/match` | Compute cosine similarity career match percentage |
| `GET` | `/api/gap/{student_id}/{role_id}` | Compute prioritized skill gaps |
| `GET` | `/api/roadmap/{role_id}` | Generate milestone learning roadmap with resources |
