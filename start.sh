#!/bin/bash
set -e

# Vector data now lives in Qdrant Cloud (persists across restarts and
# Render's free-tier cold starts), so ingestion is handled lazily and only
# once by main.py's lifespan — no unconditional ingest step here anymore.

echo "==> Starting uvicorn..."
cd backend && uvicorn main:app --host 0.0.0.0 --port "${PORT:-8000}"
