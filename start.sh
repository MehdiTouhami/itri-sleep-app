#!/bin/bash
set -e

echo "==> Running ingest.py..."
python backend/ingest.py

# small buffer so the personal-nights and research embedding runs don't share
# the same Gemini free-tier per-minute quota window
sleep 5

echo "==> Running ingest_research.py..."
python backend/ingest_research.py

echo "==> Starting uvicorn..."
cd backend && uvicorn main:app --host 0.0.0.0 --port "${PORT:-8000}"
