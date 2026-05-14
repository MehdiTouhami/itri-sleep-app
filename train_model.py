"""
Itri Sleep — RF Model Retraining Script
Run from MehdiTouhamiFinal/ root:
    python3 train_model.py
Outputs: backend/sleep_score_model.pkl
Requires: pip install scikit-learn joblib pandas numpy
"""

import os
import re
import glob
import joblib
import warnings
import numpy as np
import pandas as pd
from datetime import datetime

from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score

warnings.filterwarnings("ignore")

CSV_DIR  = os.path.join(os.path.dirname(__file__), "sleepapp", "assets", "data")
OUT_PATH = os.path.join(os.path.dirname(__file__), "backend", "sleep_score_model.pkl")
MIN_SLEEP_MINUTES = 60  # filter watch-error nights


# ── helpers ──────────────────────────────────────────────────────────────────

def duration_to_minutes(x):
    if pd.isna(x):
        return np.nan
    x = str(x).strip().lower()
    if x in ("nan", "", "none"):
        return np.nan
    h = re.search(r"(\d+)\s*h", x)
    m = re.search(r"(\d+)\s*m", x)
    return (int(h.group(1)) if h else 0) * 60 + (int(m.group(1)) if m else 0)


def parse_csv(path):
    """Parse a single key-value CSV → dict row."""
    try:
        df = pd.read_csv(path, header=None)
    except Exception:
        return None

    row = {}
    for _, r in df.iterrows():
        if len(r) < 2:
            continue
        key = str(r.iloc[0]).strip() if pd.notna(r.iloc[0]) else None
        val = r.iloc[1]
        if key and key not in ("", "nan"):
            row[key] = val
    return row if row else None


# ── load all CSVs ─────────────────────────────────────────────────────────────

files = sorted(glob.glob(os.path.join(CSV_DIR, "Sleep-*.csv")),
               key=lambda p: int(re.search(r"Sleep-(\d+)", p).group(1)))

print(f"Found {len(files)} CSV files")

rows = []
for path in files:
    r = parse_csv(path)
    if r:
        r["_file"] = os.path.basename(path)
        rows.append(r)

data = pd.DataFrame(rows)
print(f"Parsed {len(data)} rows, columns: {list(data.columns)}")


# ── feature engineering ───────────────────────────────────────────────────────

# Duration columns → minutes
for col in ["Sleep Duration", "Deep Sleep Duration", "Light Sleep Duration",
            "REM Duration", "Awake Time"]:
    if col in data.columns:
        data[col] = data[col].apply(duration_to_minutes)

# Quality → ordinal
quality_map = {"poor": 0, "fair": 1, "good": 2, "excellent": 3}
if "Quality" in data.columns:
    data["Quality"] = data["Quality"].astype(str).str.strip().str.lower().map(quality_map)

# Date → day-of-week (0=Mon … 6=Sun)
if "Date" in data.columns:
    def parse_date(s):
        try:
            return datetime.strptime(str(s).strip(), "%m/%d/%y")
        except Exception:
            return None
    data["DayOfWeek"] = data["Date"].apply(lambda s: parse_date(s).weekday()
                                            if parse_date(s) else np.nan)

# Numeric coercion
numeric_cols = [
    "Sleep Score", "Stress Avg", "Restless Moments",
    "Avg Overnight Heart Rate", "Resting Heart Rate",
    "Body Battery Change", "Avg Respiration",
    "Avg Overnight HRV", "7d Avg HRV", "DayOfWeek",
]
for col in numeric_cols:
    if col in data.columns:
        data[col] = pd.to_numeric(data[col], errors="coerce")


# ── filter watch-error nights (<60 min) ───────────────────────────────────────

pre = len(data)
data = data[data["Sleep Duration"].fillna(0) >= MIN_SLEEP_MINUTES].copy()
print(f"Filtered {pre - len(data)} watch-error nights (<{MIN_SLEEP_MINUTES} min)")


# ── drop non-ML columns ───────────────────────────────────────────────────────

drop_cols = [
    "Date", "Sleep Score 1 Day", "Sleep Score Factors",
    "Sleep Timeline Metrics", "Quality",   # Quality duplicates Sleep Score signal
    "_file",
]
data = data.drop(columns=[c for c in drop_cols if c in data.columns], errors="ignore")
data = data.loc[:, ~data.columns.duplicated()]


# ── fill missing values ────────────────────────────────────────────────────────

print("\nMissing values before fill:")
print(data.isna().sum()[data.isna().sum() > 0])

for col in data.columns:
    if data[col].dtype in (np.float64, np.int64):
        data[col] = data[col].fillna(data[col].median())

print(f"\nFinal dataset: {data.shape[0]} nights × {data.shape[1]} features")
print("Features:", list(data.columns))


# ── train / test split + model ────────────────────────────────────────────────

target = "Sleep Score"
X = data.drop(columns=[target])
y = data[target]

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

model = RandomForestRegressor(n_estimators=300, max_depth=8, random_state=42)
model.fit(X_train, y_train)


# ── evaluation ────────────────────────────────────────────────────────────────

preds = model.predict(X_test)
mae  = mean_absolute_error(y_test, preds)
rmse = np.sqrt(mean_squared_error(y_test, preds))
r2   = r2_score(y_test, preds)

print(f"\n── Hold-out test ──")
print(f"  MAE : {mae:.3f}")
print(f"  RMSE: {rmse:.3f}")
print(f"  R²  : {r2:.3f}")

cv_r2 = cross_val_score(model, X, y, cv=5, scoring="r2")
print(f"\n── 5-fold CV R² ──")
print(f"  {cv_r2.round(3)}  →  mean {cv_r2.mean():.3f} ± {cv_r2.std():.3f}")


# ── feature importance ────────────────────────────────────────────────────────

imp = pd.DataFrame({"Feature": X.columns, "Importance": model.feature_importances_})
imp = imp.sort_values("Importance", ascending=False)
print("\n── Feature Importance ──")
print(imp.to_string(index=False))


# ── save model ────────────────────────────────────────────────────────────────

joblib.dump(model, OUT_PATH)
print(f"\n✓ Model saved to {OUT_PATH}")
