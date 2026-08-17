"""
ingest.py — Parse all Garmin CSVs and embed into ChromaDB.
Run once before starting the server: python ingest.py
"""

import os
import csv
import time
from dotenv import load_dotenv
from langchain_google_genai import GoogleGenerativeAIEmbeddings
from langchain_chroma import Chroma
from langchain_core.documents import Document

load_dotenv()

# CSVs are at sleepapp/assets/data/ relative to the repo root.
# Works both locally (../sleepapp/assets/data from backend/) and in Docker (/app/sleepapp/assets/data).
_here = os.path.dirname(os.path.abspath(__file__))
CSV_DIR = os.environ.get(
    "CSV_DIR",
    os.path.join(_here, "../sleepapp/assets/data")
)
CHROMA_DIR = os.path.join(_here, "chroma_db")


def parse_csv(filepath: str) -> dict:
    """Parse one Garmin key-value CSV into a flat dict. First Sleep Duration wins."""
    data = {}
    seen_sleep_duration = False

    with open(filepath, newline="", encoding="utf-8") as f:
        reader = csv.reader(f)
        for row in reader:
            if len(row) < 2:
                continue
            key = row[0].strip()
            value = row[1].strip()

            if not key or not value:
                continue

            # CSV has Sleep Duration twice — first occurrence is the real one
            if key == "Sleep Duration":
                if not seen_sleep_duration:
                    data[key] = value
                    seen_sleep_duration = True
            else:
                data[key] = value

    return data


def build_document_text(data: dict) -> str:
    """Convert a night's dict into a readable string for embedding."""
    return (
        f"Date: {data.get('Date', 'N/A')} | "
        f"Sleep Score: {data.get('Sleep Score', 'N/A')} | "
        f"Quality: {data.get('Quality', 'N/A')} | "
        f"Duration: {data.get('Sleep Duration', 'N/A')} | "
        f"Deep Sleep: {data.get('Deep Sleep Duration', 'N/A')} | "
        f"REM: {data.get('REM Duration', 'N/A')} | "
        f"Light Sleep: {data.get('Light Sleep Duration', 'N/A')} | "
        f"Awake: {data.get('Awake Time', 'N/A')} | "
        f"HRV: {data.get('Avg Overnight HRV', 'N/A')} | "
        f"Resting HR: {data.get('Resting Heart Rate', 'N/A')} | "
        f"Stress: {data.get('Stress Avg', 'N/A')} | "
        f"Body Battery: {data.get('Body Battery Change', 'N/A')} | "
        f"Respiration: {data.get('Avg Respiration', 'N/A')}"
    )


def embed_with_rate_limit(vectorstore, documents, batch_size=10, pause=3):
    """Add documents in small batches with backoff for Gemini's free-tier quota (100 req/min)."""
    total = len(documents)
    for i in range(0, total, batch_size):
        batch = documents[i:i + batch_size]
        for attempt in range(6):
            try:
                vectorstore.add_documents(batch)
                break
            except Exception as e:
                if "RESOURCE_EXHAUSTED" in str(e) or "429" in str(e):
                    wait = 45
                    print(f"  Rate limited, waiting {wait}s (attempt {attempt + 1})...")
                    time.sleep(wait)
                else:
                    raise
        else:
            raise RuntimeError("Gave up after repeated rate-limit retries.")
        print(f"  Embedded {min(i + batch_size, total)}/{total} nights")
        time.sleep(pause)


def ingest():
    print(f"Loading CSVs from: {os.path.abspath(CSV_DIR)} (up to 279 nights)")

    documents = []

    for i in range(1, 280):
        path = os.path.join(CSV_DIR, f"Sleep-{i}.csv")
        if not os.path.exists(path):
            print(f"  ⚠ Missing: Sleep-{i}.csv — skipping")
            continue

        data = parse_csv(path)
        text = build_document_text(data)

        # Store date + score as metadata for potential future filtering
        doc = Document(
            page_content=text,
            metadata={
                "date": data.get("Date", "unknown"),
                "score": data.get("Sleep Score", "0"),
                "file": f"Sleep-{i}.csv",
            },
        )
        documents.append(doc)
        print(f"  ✓ Sleep-{i}.csv → {data.get('Date', '?')} | Score: {data.get('Sleep Score', '?')}")

    print(f"\nEmbedding {len(documents)} nights into ChromaDB (rate-limited for Gemini free tier)...")

    embeddings = GoogleGenerativeAIEmbeddings(model="models/gemini-embedding-001")
    vectorstore = Chroma(embedding_function=embeddings, persist_directory=CHROMA_DIR)
    embed_with_rate_limit(vectorstore, documents)

    print(f"\n✅ Done. {len(documents)} nights stored in {CHROMA_DIR}/")
    return vectorstore


if __name__ == "__main__":
    ingest()
