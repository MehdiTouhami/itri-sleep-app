FROM python:3.12-slim

WORKDIR /app

# Install backend dependencies
COPY backend/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend code and CSV assets
COPY backend/ ./backend/
COPY sleepapp/assets/data/ ./sleepapp/assets/data/

# start.sh: ingest then serve (env vars like OPENAI_API_KEY are available at runtime, not build time)
COPY start.sh ./start.sh
RUN chmod +x ./start.sh

CMD ["./start.sh"]
