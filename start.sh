#!/bin/bash
set -e

echo "==> Running ingest.py..."
python backend/ingest.py

echo "==> Running ingest_research.py..."
python backend/ingest_research.py

echo "==> Starting uvicorn..."
cd backend && uvicorn main:app --host 0.0.0.0 --port "${PORT:-8000}"
