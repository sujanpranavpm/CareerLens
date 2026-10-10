"""
onet_loader.py — Load and process O*NET 31.0 CSV files.

Ported and adapted from the original train_model.py helpers.
Used to build role-skill profiles from real occupational data.
"""

import os
import functools
import pandas as pd

ONET_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data", "onet")
_ONET_DIR_ABS = os.path.abspath(ONET_DIR)


def _onet_path(filename: str) -> str:
    return os.path.join(_ONET_DIR_ABS, filename)


# ──────────────────────────────────────────────────────────────────────────────
# RAW LOADERS  (cached so CSVs are only read once per process)
# ──────────────────────────────────────────────────────────────────────────────

@functools.lru_cache(maxsize=1)
def load_occupation_data() -> pd.DataFrame:
    """Load occupation_data.csv → columns: O*NET-SOC Code, Title, Description."""
    path = _onet_path("occupation_data.csv")
    df = pd.read_csv(path, usecols=["O*NET-SOC Code", "Title", "Description"])
    return df


@functools.lru_cache(maxsize=1)
def load_job_zones() -> pd.DataFrame:
    """Load job_zones.csv → columns: O*NET-SOC Code, Title, Job Zone."""
    path = _onet_path("job_zones.csv")
    df = pd.read_csv(path, usecols=["O*NET-SOC Code", "Title", "Job Zone"])
    df["Job Zone"] = pd.to_numeric(df["Job Zone"], errors="coerce")
    df = df.dropna(subset=["Job Zone"])
    df["Job Zone"] = df["Job Zone"].astype(int)
    return df.drop_duplicates(subset=["O*NET-SOC Code"])


@functools.lru_cache(maxsize=1)
def load_software_skills() -> pd.DataFrame:
    """
    Load software_skills.csv → full table.
    Columns: O*NET-SOC Code, Title, Workplace Example, Element ID,
             Element Name, Hot Technology, In Demand
    """
    path = _onet_path("software_skills.csv")
    df = pd.read_csv(
        path,
        usecols=["O*NET-SOC Code", "Title", "Workplace Example",
                 "Element Name", "Hot Technology", "In Demand"],
    )
    return df


@functools.lru_cache(maxsize=1)
def load_essential_skills() -> pd.DataFrame:
    """
    Load essential_skills.csv filtered to Importance (IM) scale.
    Columns: O*NET-SOC Code, Title, Element Name, Data Value
    """
    path = _onet_path("essential_skills.csv")
    df = pd.read_csv(
        path,
        usecols=["O*NET-SOC Code", "Title", "Element Name", "Scale ID", "Data Value"],
    )
    df = df[df["Scale ID"] == "IM"].copy()
    df["Data Value"] = pd.to_numeric(df["Data Value"], errors="coerce")
    df = df.dropna(subset=["Data Value"])
    return df.drop(columns=["Scale ID"])


# ──────────────────────────────────────────────────────────────────────────────
# DERIVED / PROCESSED VIEWS
# ──────────────────────────────────────────────────────────────────────────────

def get_it_occupations() -> pd.DataFrame:
    """
    Return occupations in the Computer & Mathematical SOC group (15-xxxx)
    joined with their job zones.
    """
    occ = load_occupation_data()
    jz = load_job_zones()
    it = occ[occ["O*NET-SOC Code"].str.startswith("15-")].copy()
    it = it.merge(jz[["O*NET-SOC Code", "Job Zone"]], on="O*NET-SOC Code", how="left")
    return it.reset_index(drop=True)


def get_software_skills_for_code(onet_code: str) -> pd.DataFrame:
    """
    Return all software/tech skills for a specific O*NET occupation code.
    Adds a demand_score column: Hot=Y + InDemand=Y → 3, one Y → 2, none → 1.
    """
    sw = load_software_skills()
    subset = sw[sw["O*NET-SOC Code"] == onet_code].copy()
    subset["demand_score"] = subset.apply(
        lambda r: 3 if r["Hot Technology"] == "Y" and r["In Demand"] == "Y"
                  else (2 if r["Hot Technology"] == "Y" or r["In Demand"] == "Y"
                        else 1),
        axis=1,
    )
    return subset.reset_index(drop=True)


def get_role_skill_demand(onet_codes: list[str]) -> pd.DataFrame:
    """
    Aggregate software skills across multiple O*NET codes.
    Returns a DataFrame with columns:
      skill_name, total_demand, avg_demand_score, hot_tech_count, in_demand_count
    sorted by total_demand desc.
    """
    sw = load_software_skills()
    subset = sw[sw["O*NET-SOC Code"].isin(onet_codes)].copy()
    if subset.empty:
        return pd.DataFrame(columns=["skill_name", "total_demand", "avg_demand_score",
                                     "hot_tech_count", "in_demand_count"])
    subset["hot_int"] = (subset["Hot Technology"] == "Y").astype(int)
    subset["demand_int"] = (subset["In Demand"] == "Y").astype(int)
    subset["demand_score"] = subset.apply(
        lambda r: 3 if r["Hot Technology"] == "Y" and r["In Demand"] == "Y"
                  else (2 if r["Hot Technology"] == "Y" or r["In Demand"] == "Y"
                        else 1),
        axis=1,
    )
    agg = (
        subset.groupby("Workplace Example")
        .agg(
            total_demand=("demand_score", "sum"),
            avg_demand_score=("demand_score", "mean"),
            hot_tech_count=("hot_int", "sum"),
            in_demand_count=("demand_int", "sum"),
        )
        .reset_index()
        .rename(columns={"Workplace Example": "skill_name"})
        .sort_values("total_demand", ascending=False)
        .reset_index(drop=True)
    )
    return agg
