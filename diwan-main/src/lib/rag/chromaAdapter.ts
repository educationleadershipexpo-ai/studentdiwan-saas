// ── ChromaDB RAG Search Adapter ─────────────────────────────────────────────
// Queries ChromaDB REST endpoint (http://localhost:8000) for vector search,
// falling back smoothly to similarity chunk matching against POLICY_DOCUMENTS.

import { POLICY_DOCUMENTS, type DocumentChunk } from "./ragDocumentStore";

export interface RAGSearchResult {
  chunk: DocumentChunk;
  score: number;
  source: "ChromaDB" | "LocalVectorIndex";
}

export async function searchRAGDocuments(queryText: string, topK: number = 3): Promise<RAGSearchResult[]> {
  const normalizedQuery = queryText.toLowerCase();

  // Attempt 1: ChromaDB REST API Call
  try {
    const chromaEndpoint = "http://localhost:8000/api/v1/collections/school_docs/query";
    const chromaRes = await fetch(chromaEndpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        query_texts: [queryText],
        n_results: topK,
      }),
    });

    if (chromaRes.ok) {
      const chromaData = await chromaRes.json();
      if (chromaData && chromaData.documents && chromaData.documents[0]) {
        const results: RAGSearchResult[] = chromaData.documents[0].map((text: string, idx: number) => ({
          chunk: {
            id: chromaData.ids?.[0]?.[idx] || `chroma-${idx}`,
            category: "School Policies",
            title: chromaData.metadatas?.[0]?.[idx]?.title || "Retrieved Document",
            content: text,
            tags: [],
          },
          score: chromaData.distances?.[0]?.[idx] || 0.9,
          source: "ChromaDB" as const,
        }));
        return results;
      }
    }
  } catch {
    // ChromaDB REST endpoint unreachable; fallback to Local Vector Index
  }

  // Fallback 2: Local Vector Index Search
  const queryTokens = normalizedQuery.split(/\s+/).filter(t => t.length > 2);

  const scoredChunks = POLICY_DOCUMENTS.map(doc => {
    let score = 0;
    const fullText = `${doc.title} ${doc.category} ${doc.content} ${doc.tags.join(" ")}`.toLowerCase();

    queryTokens.forEach(token => {
      if (fullText.includes(token)) score += 1;
    });

    doc.tags.forEach(tag => {
      if (normalizedQuery.includes(tag)) score += 2;
    });

    return { chunk: doc, score, source: "LocalVectorIndex" as const };
  });

  scoredChunks.sort((a, b) => b.score - a.score);
  return scoredChunks.filter(c => c.score > 0).slice(0, topK);
}

export function formatRAGContext(results: RAGSearchResult[]): string {
  if (results.length === 0) {
    return "No specific school policy document matched the query.";
  }

  return results.map(r => 
    `[Source: ${r.chunk.category} — "${r.chunk.title}" (${r.source})]\n${r.chunk.content}`
  ).join("\n\n");
}
