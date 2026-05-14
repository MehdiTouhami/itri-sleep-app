"""
rag_chain.py — Dual-retrieval RAG chain for Itri Sleep Coach.

Retrieves from two ChromaDB collections:
  1. Personal Garmin sleep data (your actual nights)
  2. Curated sleep science research summaries

Every response is grounded in both your real data AND evidence-based research.
"""

from operator import itemgetter
from dotenv import load_dotenv
from langchain_openai import OpenAIEmbeddings, ChatOpenAI
from langchain_chroma import Chroma
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables import RunnableLambda

load_dotenv()

CHROMA_DATA_DIR     = "./chroma_db"
CHROMA_RESEARCH_DIR = "./chroma_research"

# --- Embeddings (shared across both collections) ---
embeddings = OpenAIEmbeddings(model="text-embedding-3-small")

# --- Personal sleep data retriever ---
personal_store = Chroma(
    persist_directory=CHROMA_DATA_DIR,
    embedding_function=embeddings,
)
personal_retriever = personal_store.as_retriever(search_kwargs={"k": 5})

# --- Sleep research retriever ---
research_store = Chroma(
    persist_directory=CHROMA_RESEARCH_DIR,
    embedding_function=embeddings,
)
research_retriever = research_store.as_retriever(search_kwargs={"k": 3})

# --- LLM ---
llm = ChatOpenAI(model="gpt-4o-mini", temperature=0.7)

# --- Prompt ---
SYSTEM_PROMPT = """You are Itri, an AI sleep coach inside the Itri Sleep mobile app.
You have access to two sources of information:

1. THE USER'S PERSONAL GARMIN SLEEP DATA — retrieved nights relevant to their question.
2. SLEEP SCIENCE RESEARCH — peer-reviewed findings relevant to their question.

Use BOTH sources in your response:
- Ground your advice in the user's real data (cite dates and scores where relevant).
- Back it up with research evidence where applicable (cite the topic/source).
- Keep responses concise and actionable (3–6 sentences).
- If the personal data does not contain enough information, be honest about it.
- Do not fabricate data or invent dates.

--- PERSONAL SLEEP DATA ---
{personal_context}

--- SLEEP RESEARCH ---
{research_context}
"""

prompt = ChatPromptTemplate.from_messages([
    ("system", SYSTEM_PROMPT),
    MessagesPlaceholder("chat_history"),
    ("human", "{question}"),
])


def _format_docs(docs) -> str:
    if not docs:
        return "No relevant data found."
    return "\n\n".join(doc.page_content for doc in docs)


def _retrieve_both(question: str) -> dict:
    """Run both retrievers in parallel for the same question."""
    personal_docs = personal_retriever.invoke(question)
    research_docs  = research_retriever.invoke(question)
    return {
        "personal_context": _format_docs(personal_docs),
        "research_context":  _format_docs(research_docs),
    }


# --- LCEL chain ---
chain = (
    {
        "personal_context": RunnableLambda(lambda x: _retrieve_both(x["question"])["personal_context"]),
        "research_context":  RunnableLambda(lambda x: _retrieve_both(x["question"])["research_context"]),
        "question":          itemgetter("question"),
        "chat_history":      itemgetter("chat_history"),
    }
    | prompt
    | llm
    | StrOutputParser()
)
