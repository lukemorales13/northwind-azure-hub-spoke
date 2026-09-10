#!/usr/bin/env python3
"""Simple RAG demo (mock mode).

Searches `sample-documents/` for the query using simple keyword matching
and returns a mock answer citing the most relevant documents.
"""
import argparse
import json
from pathlib import Path
import re


def load_documents(base_path: Path):
    docs = []
    for p in sorted(base_path.rglob("*.txt")):
        try:
            text = p.read_text(encoding="utf-8")
        except Exception:
            text = ""
        docs.append({"path": str(p.relative_to(base_path)), "text": text})
    return docs


def rank_documents(query: str, docs):
    qwords = [w for w in re.findall(r"\w+", query.lower()) if len(w) > 1]
    results = []
    for d in docs:
        text = d["text"].lower()
        score = sum(text.count(w) for w in qwords)
        # snippet: show surrounding context of first match if any
        snippet = d["text"][:200].strip()
        for w in qwords:
            idx = text.find(w)
            if idx >= 0:
                start = max(0, idx - 30)
                snippet = d["text"][start : start + 200].strip()
                break
        results.append({"doc": d["path"], "score": score, "snippet": snippet})
    results.sort(key=lambda x: x["score"], reverse=True)
    return results


def mock_answer(query: str, top_doc):
    return f"(Mock) Respuesta a '{query}' basada en {top_doc['doc']}"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--mock", action="store_true", help="Run in mock mode (no Azure)")
    parser.add_argument("--query", type=str, default="¿Cuál es la política?", help="Query text")
    args = parser.parse_args()

    base = Path(__file__).resolve().parents[1] / "sample-documents"
    if not base.exists():
        print(json.dumps({"error": "sample-documents not found", "path": str(base)}))
        return

    docs = load_documents(base)
    if not docs:
        print(json.dumps({"error": "no documents found in sample-documents"}))
        return

    if args.mock:
        results = rank_documents(args.query, docs)
        top = results[0]
        out = {"query": args.query, "results": results[:5], "answer": mock_answer(args.query, top)}
        print(json.dumps(out, ensure_ascii=False, indent=2))
        return

    # Real mode placeholder: implement Azure/OpenAI integration here
    print(json.dumps({"error": "real mode not implemented in this demo. Use --mock"}))


if __name__ == "__main__":
    main()
