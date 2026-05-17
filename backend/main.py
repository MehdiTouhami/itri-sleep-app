"""
main.py — FastAPI server for Itri Sleep RAG coach.
Run with: uvicorn main:app --reload --port 8000
"""

import os
import joblib
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from langchain_core.messages import HumanMessage, AIMessage

# ---------------------------------------------------------------------------
# RF model — loaded once at startup
# ---------------------------------------------------------------------------
_MODEL_PATH = os.path.join(os.path.dirname(__file__), "sleep_score_model.pkl")
_rf_model = None

def _load_model():
    global _rf_model
    if _rf_model is None and os.path.exists(_MODEL_PATH):
        _rf_model = joblib.load(_MODEL_PATH)
    return _rf_model

# Feature names must match the exact training column order from the notebook
_FEATURE_NAMES = [
    "Sleep Duration", "Quality", "Stress Avg", "Deep Sleep Duration",
    "Light Sleep Duration", "REM Duration", "Awake Time", "Restless Moments",
    "Avg Overnight Heart Rate", "Resting Heart Rate", "Body Battery Change",
    "Avg Respiration", "Avg Overnight HRV", "7d Avg HRV",
]

# Human-readable display names for the Flutter UI
_DISPLAY_NAMES = {
    "Sleep Duration":          "Sleep Duration",
    "Quality":                 "Sleep Quality",
    "Stress Avg":              "Stress Level",
    "Deep Sleep Duration":     "Deep Sleep",
    "Light Sleep Duration":    "Light Sleep",
    "REM Duration":            "REM Sleep",
    "Awake Time":              "Awake Time",
    "Restless Moments":        "Restlessness",
    "Avg Overnight Heart Rate":"Overnight HR",
    "Resting Heart Rate":      "Resting HR",
    "Body Battery Change":     "Body Battery",
    "Avg Respiration":         "Respiration",
    "Avg Overnight HRV":       "HRV",
    "7d Avg HRV":              "7-Day HRV",
}

_load_model()  # eager load so first request is fast


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Run ingest if ChromaDB collections don't exist yet
    _here = os.path.dirname(os.path.abspath(__file__))
    chroma_dir = os.path.join(_here, "chroma_db")
    research_dir = os.path.join(_here, "chroma_research")

    if not os.path.exists(chroma_dir) or not os.listdir(chroma_dir):
        print("ChromaDB not found — running ingest.py...")
        from ingest import ingest
        ingest()

    if not os.path.exists(research_dir) or not os.listdir(research_dir):
        print("Research DB not found — running ingest_research.py...")
        from ingest_research import ingest_research
        ingest_research()

    from rag_chain import chain as _chain
    app.state.chain = _chain
    print("RAG chain ready.")
    yield


app = FastAPI(title="Itri Sleep RAG Backend", lifespan=lifespan)

# CORS — required for Flutter web (Chrome dev)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten this in production
    allow_methods=["POST", "GET"],
    allow_headers=["*"],
)


class ChatRequest(BaseModel):
    message: str
    history: list[list[str]] = []  # [[human_msg, ai_msg], ...]


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/feature-importance")
def feature_importance():
    model = _load_model()
    if model is None:
        raise HTTPException(
            status_code=503,
            detail="Model not found. Download sleep_score_model.pkl from Google Drive and place it in backend/",
        )
    importances = model.feature_importances_
    result = [
        {"feature": _DISPLAY_NAMES.get(name, name), "importance": round(float(imp), 4)}
        for name, imp in zip(_FEATURE_NAMES, importances)
    ]
    result.sort(key=lambda x: x["importance"], reverse=True)
    return {"features": result}


@app.post("/chat")
async def chat(request: Request, body: ChatRequest):
    if not body.message.strip():
        raise HTTPException(status_code=400, detail="Message cannot be empty")

    # Convert [[human, ai], ...] pairs into LangChain message objects
    chat_history = []
    for pair in body.history:
        if len(pair) == 2:
            chat_history.append(HumanMessage(content=pair[0]))
            chat_history.append(AIMessage(content=pair[1]))

    try:
        answer = request.app.state.chain.invoke({
            "question": body.message,
            "chat_history": chat_history,
        })
        return {"reply": answer}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
