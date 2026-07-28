import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.tsx'
import './index.css'
import './i18n'
import { LanguageProvider } from './contexts/LanguageContext.tsx'

// Handle dynamic import asset failure automatically on new deployments
window.addEventListener('vite:preloadError', () => {
  window.location.reload();
});

window.addEventListener('error', (e) => {
  if (e.message && (e.message.includes('Failed to fetch dynamically imported module') || e.message.includes('Importing a module script failed'))) {
    const hasReloaded = sessionStorage.getItem('chunk_reload_attempted');
    if (!hasReloaded) {
      sessionStorage.setItem('chunk_reload_attempted', 'true');
      window.location.reload();
    }
  }
});

// Clear reload flag on successful script execution
sessionStorage.removeItem('chunk_reload_attempted');

// Every /api/data/* request now requires a signed session token (server.ts's
// requireAuth middleware) — but the app has ~34 call sites that fetch it
// directly (src/lib/localDb.ts plus many components/hooks that bypass that
// abstraction), so rather than editing each one, patch fetch itself once,
// here, before anything else in the app runs. Only requests to /api/data/*
// are touched; every other fetch (Gemini/OpenRouter, avatar images, etc.)
// passes through unchanged.
const nativeFetch = window.fetch.bind(window);

let sessionExpiryHandled = false;
let loginInProgress = false;
let lastSuccessfulLoginTime = 0;

let loginProgressTimeout: NodeJS.Timeout | null = null;
(window as Window & { __setLoginInProgress?: (v: boolean) => void }).__setLoginInProgress = (v: boolean) => {
  if (loginProgressTimeout) clearTimeout(loginProgressTimeout);
  loginInProgress = v;
  if (v) {
    loginProgressTimeout = setTimeout(() => {
      loginInProgress = false;
      loginProgressTimeout = null;
    }, 10000);
  }
};

setInterval(() => {
  const win = window as Window & { __loginTime?: number };
  if (win.__loginTime && win.__loginTime > lastSuccessfulLoginTime) {
    lastSuccessfulLoginTime = win.__loginTime;
    sessionExpiryHandled = false;
  }
}, 100);

function handleSessionExpired() {
  if (sessionExpiryHandled) return;
  if (loginInProgress) return;
  const timeSinceLogin = Date.now() - lastSuccessfulLoginTime;
  if (timeSinceLogin < 10000) {
    return;
  }
  if (sessionExpiryHandled) return;
  sessionExpiryHandled = true;
  sessionStorage.removeItem('sd_token');
}

window.fetch = async (input: RequestInfo | URL, init?: RequestInit) => {
  const url = typeof input === "string" ? input : input instanceof URL ? input.pathname : (input as Request).url;
  const isDataCall = !!url && url.includes("/api/data");
  const isAuthCall = !!url && url.includes("/api/session");
  if (isDataCall && !isAuthCall) {
    const token = sessionStorage.getItem('sd_token');
    if (token) {
      const headers = new Headers(init?.headers || (input instanceof Request ? input.headers : undefined));
      headers.set('Authorization', `Bearer ${token}`);
      init = { ...init, headers };
    }
  }
  const response = await nativeFetch(input, init);
  if (isDataCall && !isAuthCall && response.status === 401 && sessionStorage.getItem('sd_token') && !loginInProgress) {
    handleSessionExpired();
  }
  return response;
};

// Suppress ResizeObserver loop limit exceeded error
const resizeObserverError = "ResizeObserver loop completed with undelivered notifications.";
const originalError = window.console.error;
window.console.error = (...args) => {
  if (args[0]?.includes?.(resizeObserverError) || args[0] === resizeObserverError) {
    return;
  }
  originalError.apply(window.console, args);
};

// Shim process.env for browser compatibility
if (typeof window !== 'undefined' && !window.process) {
  // @ts-expect-error: process is not defined in the browser
  window.process = { env: {
    GEMINI_API_KEY: import.meta.env.VITE_GEMINI_API_KEY || "",
    OPENROUTER_API_KEY: import.meta.env.VITE_OPENROUTER_API_KEY || "",
  } };
} else if (typeof window !== 'undefined' && window.process && !window.process.env) {
  const shimEnv = { GEMINI_API_KEY: import.meta.env.VITE_GEMINI_API_KEY || "", OPENROUTER_API_KEY: import.meta.env.VITE_OPENROUTER_API_KEY || "" };
  window.process.env = shimEnv;
} else if (typeof window !== 'undefined' && window.process && window.process.env) {
  // @ts-expect-error: GEMINI_API_KEY is not defined in the browser
  window.process.env.GEMINI_API_KEY = window.process.env.GEMINI_API_KEY || import.meta.env.VITE_GEMINI_API_KEY || "";
  // @ts-expect-error: OPENROUTER_API_KEY is not defined in the browser
  window.process.env.OPENROUTER_API_KEY = window.process.env.OPENROUTER_API_KEY || import.meta.env.VITE_OPENROUTER_API_KEY || "";
}

window.addEventListener('error', (e) => {
  if (e.message === resizeObserverError || e.message.includes(resizeObserverError)) {
    e.stopImmediatePropagation();
  }
});

// Auto-clear stale service workers and caches to prevent white-screen crashes
if ("serviceWorker" in navigator) {
  navigator.serviceWorker.getRegistrations().then((regs) => {
    regs.forEach((r) => r.unregister());
  });
  caches.keys().then((keys) => {
    keys.forEach((k) => caches.delete(k));
  });
}

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <LanguageProvider>
      <App />
    </LanguageProvider>
  </React.StrictMode>,
)
