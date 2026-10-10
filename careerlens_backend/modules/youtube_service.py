"""
youtube_service.py — YouTube Data API v3 integration with SQLite caching and fallback.

Responsibilities:
  1. Check database.get_cached_youtube_videos(skill_name)
  2. If miss, query YouTube Data API v3 (if YOUTUBE_API_KEY is available)
  3. Format top educational videos {title, video_id, channel, thumbnail, url}
  4. Cache in database.cache_youtube_videos
  5. Fall back gracefully to curated search links if key is absent or quota is exceeded
"""

from __future__ import annotations

import json
import os
import urllib.parse
import urllib.request
from typing import Optional

import database


def _get_api_key() -> Optional[str]:
    return os.environ.get("YOUTUBE_API_KEY")


def _get_fallback_videos(skill_name: str) -> list[dict]:
    """Generate high-quality default video learning resources for a skill."""
    clean_name = skill_name.strip()
    encoded_query = urllib.parse.quote(f"{clean_name} full tutorial for beginners")
    search_url = f"https://www.youtube.com/results?search_query={encoded_query}"

    return [
        {
            "title": f"{clean_name} — Complete Crash Course & Hands-on Tutorial",
            "video_id": "search_fallback_1",
            "channel": f"{clean_name} Community Learning",
            "thumbnail": "https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=300&q=80",
            "url": search_url,
        },
        {
            "title": f"Learn {clean_name} from Zero to Production in 2026",
            "video_id": "search_fallback_2",
            "channel": "Engineering Career Academy",
            "thumbnail": "https://images.unsplash.com/photo-1587620962725-abab7fe55159?w=300&q=80",
            "url": search_url,
        },
    ]


def search_youtube_videos(skill_name: str, max_results: int = 3) -> list[dict]:
    """
    Fetch top learning videos for a skill with persistent caching and fallback.

    Args:
        skill_name: Canonical or display skill name (e.g. "Docker", "Python").
        max_results: Number of videos to retrieve (default 3).

    Returns:
        List of dicts:
          [{"title": str, "video_id": str, "channel": str, "thumbnail": str, "url": str}]
    """
    skill_clean = skill_name.strip()
    if not skill_clean:
        return []

    # 1. Check SQLite Cache
    cached = database.get_cached_youtube_videos(skill_clean)
    if cached:
        return cached

    api_key = _get_api_key()
    query = f"{skill_clean} tutorial beginner practical"

    # 2. Try YouTube Data API v3 if key exists
    if api_key:
        try:
            params = urllib.parse.urlencode({
                "part": "snippet",
                "q": query,
                "type": "video",
                "maxResults": max_results,
                "relevanceLanguage": "en",
                "key": api_key,
            })
            url = f"https://www.googleapis.com/youtube/v3/search?{params}"

            req = urllib.request.Request(url, headers={"User-Agent": "CareerLens/2.0"})
            with urllib.request.urlopen(req, timeout=6) as res:
                payload = json.loads(res.read().decode("utf-8"))
                items = payload.get("items", [])

                videos: list[dict] = []
                for item in items:
                    vid_id = item.get("id", {}).get("videoId", "")
                    snippet = item.get("snippet", {})
                    if vid_id:
                        videos.append({
                            "title": snippet.get("title", f"{skill_clean} Tutorial"),
                            "video_id": vid_id,
                            "channel": snippet.get("channelTitle", "YouTube Educational"),
                            "thumbnail": snippet.get("thumbnails", {}).get("medium", {}).get("url", ""),
                            "url": f"https://www.youtube.com/watch?v={vid_id}",
                        })

                if videos:
                    database.cache_youtube_videos(skill_clean, query, videos)
                    return videos
        except Exception:
            # On quota error, network timeout or parsing issue, proceed to fallback
            pass

    # 3. Fallback
    fallback_videos = _get_fallback_videos(skill_clean)
    database.cache_youtube_videos(skill_clean, query, fallback_videos)
    return fallback_videos
