"""
ingest.py — Parse all Garmin CSVs and embed into ChromaDB.
Run once before starting the server: python ingest.py
"""

import os
import csv
from dotenv import load_dotenv
from langchain_openai import OpenAIEmbeddings
from langchain_chroma import Chroma
from langchain.schema import Document

load_dotenv()

# Path to Flutter asset CSVs — adjust if running from a different directory
CSV_DIR = os.path.join(
    os.path.dirname(__file__),
    "../sleepapp/assets/data"
)
CHROMA_DIR = "./chroma_db"


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

    print(f"\nEmbedding {len(documents)} nights into ChromaDB...")

    embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
    vectorstore = Chroma.from_documents(
        documents=documents,
        embedding=embeddings,
        persist_directory=CHROMA_DIR,
    )

    print(f"\n✅ Done. {len(documents)} nights stored in {CHROMA_DIR}/")
    return vectorstore


if __name__ == "__main__":
    ingest()
