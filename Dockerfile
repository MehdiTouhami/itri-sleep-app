FROM python:3.12-slim

WORKDIR /app

# Install backend dependencies
COPY backend/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend code
COPY backend/ ./backend/

# Copy Garmin CSV assets so ingest.py can read them
COPY sleepapp/assets/data/ ./sleepapp/assets/data/

# Build ChromaDB vector stores
RUN python backend/ingest.py && python backend/ingest_research.py

# Start the API
CMD bash -c "cd backend && uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}"
