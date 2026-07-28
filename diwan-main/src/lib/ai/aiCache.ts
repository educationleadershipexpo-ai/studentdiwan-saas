// ── AI Response & Intent Cache ──────────────────────────────────────────────
// Caches common query responses and tool outcomes to minimize OpenRouter token
// usage and prevent duplicate API hits.

interface CacheEntry<T> {
  value: T;
  expiresAt: number;
}

class AICache {
  private cache = new Map<string, CacheEntry<any>>();
  private defaultTTLMs = 3 * 60 * 1000; // 3 minutes

  get<T>(key: string): T | null {
    const entry = this.cache.get(key);
    if (!entry) return null;
    if (Date.now() > entry.expiresAt) {
      this.cache.delete(key);
      return null;
    }
    return entry.value;
  }

  set<T>(key: string, value: T, ttlMs?: number): void {
    const expiresAt = Date.now() + (ttlMs || this.defaultTTLMs);
    this.cache.set(key, { value, expiresAt });
  }

  clear(): void {
    this.cache.clear();
  }
}

export const aiCache = new AICache();
