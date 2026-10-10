"""
database.py — SQLite schema and CRUD helpers for CareerLens V1.

Tables:
  students            — core profile fields
  student_skills      — (student_id, skill_name, proficiency 1–5)
  student_projects    — project list per student
  student_certifications — certification list per student
"""

import sqlite3
import os
from typing import Optional

DB_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "careerlens.db")


def get_connection() -> sqlite3.Connection:
    """Return a SQLite connection with row_factory set to Row."""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL;")
    conn.execute("PRAGMA foreign_keys=ON;")
    return conn


def init_db() -> None:
    """Create all tables if they do not already exist."""
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.executescript("""
            CREATE TABLE IF NOT EXISTS students (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                name        TEXT    NOT NULL,
                degree      TEXT    NOT NULL,
                branch      TEXT    NOT NULL,
                year        INTEGER NOT NULL CHECK(year BETWEEN 1 AND 5),
                cgpa        REAL    NOT NULL CHECK(cgpa BETWEEN 0.0 AND 10.0),
                created_at  TEXT    DEFAULT (datetime('now')),
                updated_at  TEXT    DEFAULT (datetime('now'))
            );

            CREATE TABLE IF NOT EXISTS student_skills (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                student_id  INTEGER NOT NULL REFERENCES students(id) ON DELETE CASCADE,
                skill_name  TEXT    NOT NULL,
                proficiency INTEGER NOT NULL CHECK(proficiency BETWEEN 1 AND 5),
                UNIQUE(student_id, skill_name)
            );

            CREATE TABLE IF NOT EXISTS student_projects (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                student_id  INTEGER NOT NULL REFERENCES students(id) ON DELETE CASCADE,
                title       TEXT    NOT NULL,
                description TEXT
            );

            CREATE TABLE IF NOT EXISTS student_certifications (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                student_id  INTEGER NOT NULL REFERENCES students(id) ON DELETE CASCADE,
                name        TEXT    NOT NULL,
                issuer      TEXT,
                year        INTEGER
            );

            CREATE TABLE IF NOT EXISTS student_roadmap_progress (
                id           INTEGER PRIMARY KEY AUTOINCREMENT,
                student_id   INTEGER NOT NULL REFERENCES students(id) ON DELETE CASCADE,
                role_id      TEXT    NOT NULL,
                skill_name   TEXT    NOT NULL,
                completed    INTEGER NOT NULL DEFAULT 0,
                completed_at TEXT,
                UNIQUE(student_id, role_id, skill_name)
            );

            CREATE TABLE IF NOT EXISTS youtube_video_cache (
                skill_name   TEXT PRIMARY KEY,
                query        TEXT NOT NULL,
                video_data   TEXT NOT NULL,
                fetched_at   TEXT DEFAULT (datetime('now'))
            );
        """)
        conn.commit()
    finally:
        conn.close()


# ──────────────────────────────────────────────────────────────────────────────
# STUDENT CRUD
# ──────────────────────────────────────────────────────────────────────────────

def create_student(name: str, degree: str, branch: str, year: int, cgpa: float) -> int:
    """Insert a new student and return their id."""
    conn = get_connection()
    try:
        cur = conn.execute(
            "INSERT INTO students (name, degree, branch, year, cgpa) VALUES (?,?,?,?,?)",
            (name, degree, branch, year, cgpa)
        )
        conn.commit()
        return cur.lastrowid
    finally:
        conn.close()


def get_student(student_id: int) -> Optional[dict]:
    """Return the student row as a dict, or None if not found."""
    conn = get_connection()
    try:
        row = conn.execute("SELECT * FROM students WHERE id = ?", (student_id,)).fetchone()
        return dict(row) if row else None
    finally:
        conn.close()


def update_student(student_id: int, **fields) -> bool:
    """Update allowed fields on a student row. Returns True if a row was changed."""
    allowed = {"name", "degree", "branch", "year", "cgpa"}
    updates = {k: v for k, v in fields.items() if k in allowed}
    if not updates:
        return False
    updates["updated_at"] = "datetime('now')"
    set_clause = ", ".join(f"{k} = ?" for k in updates if k != "updated_at")
    set_clause += ", updated_at = datetime('now')"
    values = [v for k, v in updates.items() if k != "updated_at"]
    values.append(student_id)
    conn = get_connection()
    try:
        cur = conn.execute(
            f"UPDATE students SET {set_clause} WHERE id = ?", values
        )
        conn.commit()
        return cur.rowcount > 0
    finally:
        conn.close()


# ──────────────────────────────────────────────────────────────────────────────
# SKILLS CRUD
# ──────────────────────────────────────────────────────────────────────────────

def upsert_skills(student_id: int, skills: list[dict]) -> None:
    """
    Insert or replace (student_id, skill_name, proficiency) rows.
    ``skills`` is a list of {"name": str, "proficiency": int} dicts.
    """
    conn = get_connection()
    try:
        conn.executemany(
            """INSERT INTO student_skills (student_id, skill_name, proficiency)
               VALUES (?, ?, ?)
               ON CONFLICT(student_id, skill_name) DO UPDATE SET proficiency=excluded.proficiency""",
            [(student_id, s["name"], s["proficiency"]) for s in skills]
        )
        conn.commit()
    finally:
        conn.close()


def get_skills(student_id: int) -> list[dict]:
    """Return list of {skill_name, proficiency} dicts for a student."""
    conn = get_connection()
    try:
        rows = conn.execute(
            "SELECT skill_name, proficiency FROM student_skills WHERE student_id = ?",
            (student_id,)
        ).fetchall()
        return [dict(r) for r in rows]
    finally:
        conn.close()


# ──────────────────────────────────────────────────────────────────────────────
# PROJECTS CRUD
# ──────────────────────────────────────────────────────────────────────────────

def replace_projects(student_id: int, projects: list[dict]) -> None:
    """Delete all existing projects for the student and insert the new list."""
    conn = get_connection()
    try:
        conn.execute("DELETE FROM student_projects WHERE student_id = ?", (student_id,))
        conn.executemany(
            "INSERT INTO student_projects (student_id, title, description) VALUES (?,?,?)",
            [(student_id, p.get("title", ""), p.get("description", "")) for p in projects]
        )
        conn.commit()
    finally:
        conn.close()


def get_projects(student_id: int) -> list[dict]:
    conn = get_connection()
    try:
        rows = conn.execute(
            "SELECT title, description FROM student_projects WHERE student_id = ?",
            (student_id,)
        ).fetchall()
        return [dict(r) for r in rows]
    finally:
        conn.close()


# ──────────────────────────────────────────────────────────────────────────────
# CERTIFICATIONS CRUD
# ──────────────────────────────────────────────────────────────────────────────

def replace_certifications(student_id: int, certs: list[dict]) -> None:
    """Delete all existing certs for the student and insert the new list."""
    conn = get_connection()
    try:
        conn.execute("DELETE FROM student_certifications WHERE student_id = ?", (student_id,))
        conn.executemany(
            "INSERT INTO student_certifications (student_id, name, issuer, year) VALUES (?,?,?,?)",
            [(student_id, c.get("name", ""), c.get("issuer"), c.get("year")) for c in certs]
        )
        conn.commit()
    finally:
        conn.close()


def get_certifications(student_id: int) -> list[dict]:
    conn = get_connection()
    try:
        rows = conn.execute(
            "SELECT name, issuer, year FROM student_certifications WHERE student_id = ?",
            (student_id,)
        ).fetchall()
        return [dict(r) for r in rows]
    finally:
        conn.close()


# ──────────────────────────────────────────────────────────────────────────────
# ROADMAP PROGRESS CRUD (V2)
# ──────────────────────────────────────────────────────────────────────────────

def get_roadmap_progress(student_id: int, role_id: str) -> list[dict]:
    """Return all progress records for a student and role."""
    conn = get_connection()
    try:
        rows = conn.execute(
            "SELECT skill_name, completed, completed_at FROM student_roadmap_progress WHERE student_id = ? AND role_id = ?",
            (student_id, role_id)
        ).fetchall()
        return [dict(r) for r in rows]
    finally:
        conn.close()


def toggle_roadmap_skill(student_id: int, role_id: str, skill_name: str, completed: Optional[bool] = None) -> dict:
    """
    Toggle or set completion status of a roadmap skill.
    If completed is None, inverts the existing status (defaults to True if not present).
    """
    conn = get_connection()
    try:
        row = conn.execute(
            "SELECT completed FROM student_roadmap_progress WHERE student_id = ? AND role_id = ? AND skill_name = ?",
            (student_id, role_id, skill_name)
        ).fetchone()

        if completed is None:
            new_status = 1 if (not row or row["completed"] == 0) else 0
        else:
            new_status = 1 if completed else 0

        completed_at = "datetime('now')" if new_status == 1 else None

        if row:
            conn.execute(
                f"UPDATE student_roadmap_progress SET completed = ?, completed_at = {completed_at if completed_at else 'NULL'} WHERE student_id = ? AND role_id = ? AND skill_name = ?",
                (new_status, student_id, role_id, skill_name)
            )
        else:
            conn.execute(
                f"INSERT INTO student_roadmap_progress (student_id, role_id, skill_name, completed, completed_at) VALUES (?, ?, ?, ?, {completed_at if completed_at else 'NULL'})",
                (student_id, role_id, skill_name, new_status)
            )
        conn.commit()

        return {
            "student_id": student_id,
            "role_id": role_id,
            "skill_name": skill_name,
            "completed": bool(new_status),
        }
    finally:
        conn.close()


# ──────────────────────────────────────────────────────────────────────────────
# YOUTUBE VIDEO CACHE CRUD (V2)
# ──────────────────────────────────────────────────────────────────────────────

def get_cached_youtube_videos(skill_name: str) -> Optional[list[dict]]:
    """Return cached YouTube videos JSON list if present, else None."""
    import json
    conn = get_connection()
    try:
        row = conn.execute(
            "SELECT video_data FROM youtube_video_cache WHERE skill_name = ?",
            (skill_name.lower().strip(),)
        ).fetchone()
        if row and row["video_data"]:
            return json.loads(row["video_data"])
        return None
    except Exception:
        return None
    finally:
        conn.close()


def cache_youtube_videos(skill_name: str, query: str, video_data: list[dict]) -> None:
    """Store YouTube videos list in SQLite cache."""
    import json
    conn = get_connection()
    try:
        conn.execute(
            """INSERT INTO youtube_video_cache (skill_name, query, video_data, fetched_at)
               VALUES (?, ?, ?, datetime('now'))
               ON CONFLICT(skill_name) DO UPDATE SET query=excluded.query, video_data=excluded.video_data, fetched_at=datetime('now')""",
            (skill_name.lower().strip(), query, json.dumps(video_data))
        )
        conn.commit()
    finally:
        conn.close()

