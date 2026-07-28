// vite.config.ts
import { defineConfig } from "file:///C:/Users/abish/Downloads/diwan-main/diwan-main/node_modules/vite/dist/node/index.js";
import react from "file:///C:/Users/abish/Downloads/diwan-main/diwan-main/node_modules/@vitejs/plugin-react-swc/index.js";
import tailwindcss from "file:///C:/Users/abish/Downloads/diwan-main/diwan-main/node_modules/@tailwindcss/vite/dist/index.mjs";
import path from "path";
import { componentTagger } from "file:///C:/Users/abish/Downloads/diwan-main/diwan-main/node_modules/lovable-tagger/dist/index.js";
var __vite_injected_original_dirname = "C:\\Users\\abish\\Downloads\\diwan-main\\diwan-main";
var vite_config_default = defineConfig(({ mode }) => ({
  server: {
    host: "::",
    port: 3e3,
    hmr: {
      overlay: false
    },
    proxy: {
      // Forward all /api and /socket.io requests to the Express API server
      // running on port 3001. Without this proxy, Vite intercepts /api calls
      // and returns an HTML page — causing the "Unexpected token 'A'" JSON
      // parse error on every API request including login.
      "/api": {
        target: "http://localhost:3001",
        changeOrigin: true,
        secure: false
      },
      "/socket.io": {
        target: "http://localhost:3001",
        changeOrigin: true,
        ws: true
      }
    }
  },
  plugins: [
    tailwindcss(),
    react(),
    mode === "development" && componentTagger()
  ].filter(Boolean),
  define: {
    "process.env.GEMINI_API_KEY": JSON.stringify(process.env.GEMINI_API_KEY || ""),
    "process.env.OPENROUTER_API_KEY": JSON.stringify(process.env.OPENROUTER_API_KEY || ""),
    // Vercel's serverless invocation model (api/index.ts calling the Express
    // app directly, per-request, with no persistent httpServer) means the
    // Socket.IO server in server.ts never actually attaches there — only the
    // traditional `httpServer.listen()` path does. Surfacing that at build
    // time lets the client skip trying to open a socket connection that can
    // never succeed, instead of retrying in a tight, connection-starving loop.
    "import.meta.env.VITE_IS_VERCEL": JSON.stringify(!!process.env.VERCEL)
  },
  resolve: {
    alias: {
      "@": path.resolve(__vite_injected_original_dirname, "./src")
    },
    dedupe: ["react", "react-dom", "react/jsx-runtime", "react/jsx-dev-runtime"]
  },
  build: {
    rollupOptions: {
      output: {
        // Split vendor libraries and heavy export modules into separate chunks
        // to enable better caching and parallel loading. Only include packages
        // that are actually imported to avoid rollup errors.
        manualChunks: {
          // PDF export libraries — lazy loaded on demand
          pdfExport: ["jspdf", "html2canvas"],
          // Excel import/export library — lazy loaded
          excelExport: ["xlsx"],
          // Mapping library — lazy loaded
          maps: ["leaflet"]
        }
      }
    },
    // Set a higher limit to avoid warnings for necessary large chunks
    chunkSizeWarningLimit: 600,
    // Target modern browsers for smaller output
    target: "es2020"
  },
  optimizeDeps: {
    entries: ["index.html"],
    include: ["react", "react-dom", "react/jsx-runtime", "react/jsx-dev-runtime", "leaflet"],
    exclude: ["react-leaflet", "@react-leaflet/core"]
  }
}));
export {
  vite_config_default as default
};
//# sourceMappingURL=data:application/json;base64,ewogICJ2ZXJzaW9uIjogMywKICAic291cmNlcyI6IFsidml0ZS5jb25maWcudHMiXSwKICAic291cmNlc0NvbnRlbnQiOiBbImNvbnN0IF9fdml0ZV9pbmplY3RlZF9vcmlnaW5hbF9kaXJuYW1lID0gXCJDOlxcXFxVc2Vyc1xcXFxhYmlzaFxcXFxEb3dubG9hZHNcXFxcZGl3YW4tbWFpblxcXFxkaXdhbi1tYWluXCI7Y29uc3QgX192aXRlX2luamVjdGVkX29yaWdpbmFsX2ZpbGVuYW1lID0gXCJDOlxcXFxVc2Vyc1xcXFxhYmlzaFxcXFxEb3dubG9hZHNcXFxcZGl3YW4tbWFpblxcXFxkaXdhbi1tYWluXFxcXHZpdGUuY29uZmlnLnRzXCI7Y29uc3QgX192aXRlX2luamVjdGVkX29yaWdpbmFsX2ltcG9ydF9tZXRhX3VybCA9IFwiZmlsZTovLy9DOi9Vc2Vycy9hYmlzaC9Eb3dubG9hZHMvZGl3YW4tbWFpbi9kaXdhbi1tYWluL3ZpdGUuY29uZmlnLnRzXCI7aW1wb3J0IHsgZGVmaW5lQ29uZmlnIH0gZnJvbSBcInZpdGVcIjtcbmltcG9ydCByZWFjdCBmcm9tIFwiQHZpdGVqcy9wbHVnaW4tcmVhY3Qtc3djXCI7XG5pbXBvcnQgdGFpbHdpbmRjc3MgZnJvbSBcIkB0YWlsd2luZGNzcy92aXRlXCI7XG5pbXBvcnQgcGF0aCBmcm9tIFwicGF0aFwiO1xuaW1wb3J0IHsgY29tcG9uZW50VGFnZ2VyIH0gZnJvbSBcImxvdmFibGUtdGFnZ2VyXCI7XG5cbi8vIGh0dHBzOi8vdml0ZWpzLmRldi9jb25maWcvXG5leHBvcnQgZGVmYXVsdCBkZWZpbmVDb25maWcoKHsgbW9kZSB9KSA9PiAoe1xuICBzZXJ2ZXI6IHtcbiAgICBob3N0OiBcIjo6XCIsXG4gICAgcG9ydDogMzAwMCxcbiAgICBobXI6IHtcbiAgICAgIG92ZXJsYXk6IGZhbHNlLFxuICAgIH0sXG4gICAgcHJveHk6IHtcbiAgICAgIC8vIEZvcndhcmQgYWxsIC9hcGkgYW5kIC9zb2NrZXQuaW8gcmVxdWVzdHMgdG8gdGhlIEV4cHJlc3MgQVBJIHNlcnZlclxuICAgICAgLy8gcnVubmluZyBvbiBwb3J0IDMwMDEuIFdpdGhvdXQgdGhpcyBwcm94eSwgVml0ZSBpbnRlcmNlcHRzIC9hcGkgY2FsbHNcbiAgICAgIC8vIGFuZCByZXR1cm5zIGFuIEhUTUwgcGFnZSBcdTIwMTQgY2F1c2luZyB0aGUgXCJVbmV4cGVjdGVkIHRva2VuICdBJ1wiIEpTT05cbiAgICAgIC8vIHBhcnNlIGVycm9yIG9uIGV2ZXJ5IEFQSSByZXF1ZXN0IGluY2x1ZGluZyBsb2dpbi5cbiAgICAgICcvYXBpJzoge1xuICAgICAgICB0YXJnZXQ6ICdodHRwOi8vbG9jYWxob3N0OjMwMDEnLFxuICAgICAgICBjaGFuZ2VPcmlnaW46IHRydWUsXG4gICAgICAgIHNlY3VyZTogZmFsc2UsXG4gICAgICB9LFxuICAgICAgJy9zb2NrZXQuaW8nOiB7XG4gICAgICAgIHRhcmdldDogJ2h0dHA6Ly9sb2NhbGhvc3Q6MzAwMScsXG4gICAgICAgIGNoYW5nZU9yaWdpbjogdHJ1ZSxcbiAgICAgICAgd3M6IHRydWUsXG4gICAgICB9LFxuICAgIH0sXG4gIH0sXG4gIHBsdWdpbnM6IFtcbiAgICB0YWlsd2luZGNzcygpLFxuICAgIHJlYWN0KCksXG4gICAgbW9kZSA9PT0gXCJkZXZlbG9wbWVudFwiICYmIGNvbXBvbmVudFRhZ2dlcigpLFxuICBdLmZpbHRlcihCb29sZWFuKSxcbiAgZGVmaW5lOiB7XG4gICAgXCJwcm9jZXNzLmVudi5HRU1JTklfQVBJX0tFWVwiOiBKU09OLnN0cmluZ2lmeShwcm9jZXNzLmVudi5HRU1JTklfQVBJX0tFWSB8fCBcIlwiKSxcbiAgICBcInByb2Nlc3MuZW52Lk9QRU5ST1VURVJfQVBJX0tFWVwiOiBKU09OLnN0cmluZ2lmeShwcm9jZXNzLmVudi5PUEVOUk9VVEVSX0FQSV9LRVkgfHwgXCJcIiksXG4gICAgLy8gVmVyY2VsJ3Mgc2VydmVybGVzcyBpbnZvY2F0aW9uIG1vZGVsIChhcGkvaW5kZXgudHMgY2FsbGluZyB0aGUgRXhwcmVzc1xuICAgIC8vIGFwcCBkaXJlY3RseSwgcGVyLXJlcXVlc3QsIHdpdGggbm8gcGVyc2lzdGVudCBodHRwU2VydmVyKSBtZWFucyB0aGVcbiAgICAvLyBTb2NrZXQuSU8gc2VydmVyIGluIHNlcnZlci50cyBuZXZlciBhY3R1YWxseSBhdHRhY2hlcyB0aGVyZSBcdTIwMTQgb25seSB0aGVcbiAgICAvLyB0cmFkaXRpb25hbCBgaHR0cFNlcnZlci5saXN0ZW4oKWAgcGF0aCBkb2VzLiBTdXJmYWNpbmcgdGhhdCBhdCBidWlsZFxuICAgIC8vIHRpbWUgbGV0cyB0aGUgY2xpZW50IHNraXAgdHJ5aW5nIHRvIG9wZW4gYSBzb2NrZXQgY29ubmVjdGlvbiB0aGF0IGNhblxuICAgIC8vIG5ldmVyIHN1Y2NlZWQsIGluc3RlYWQgb2YgcmV0cnlpbmcgaW4gYSB0aWdodCwgY29ubmVjdGlvbi1zdGFydmluZyBsb29wLlxuICAgIFwiaW1wb3J0Lm1ldGEuZW52LlZJVEVfSVNfVkVSQ0VMXCI6IEpTT04uc3RyaW5naWZ5KCEhcHJvY2Vzcy5lbnYuVkVSQ0VMKSxcbiAgfSxcbiAgcmVzb2x2ZToge1xuICAgIGFsaWFzOiB7XG4gICAgICBcIkBcIjogcGF0aC5yZXNvbHZlKF9fZGlybmFtZSwgXCIuL3NyY1wiKSxcbiAgICB9LFxuICAgIGRlZHVwZTogW1wicmVhY3RcIiwgXCJyZWFjdC1kb21cIiwgXCJyZWFjdC9qc3gtcnVudGltZVwiLCBcInJlYWN0L2pzeC1kZXYtcnVudGltZVwiXSxcbiAgfSxcbiAgYnVpbGQ6IHtcbiAgICByb2xsdXBPcHRpb25zOiB7XG4gICAgICBvdXRwdXQ6IHtcbiAgICAgICAgLy8gU3BsaXQgdmVuZG9yIGxpYnJhcmllcyBhbmQgaGVhdnkgZXhwb3J0IG1vZHVsZXMgaW50byBzZXBhcmF0ZSBjaHVua3NcbiAgICAgICAgLy8gdG8gZW5hYmxlIGJldHRlciBjYWNoaW5nIGFuZCBwYXJhbGxlbCBsb2FkaW5nLiBPbmx5IGluY2x1ZGUgcGFja2FnZXNcbiAgICAgICAgLy8gdGhhdCBhcmUgYWN0dWFsbHkgaW1wb3J0ZWQgdG8gYXZvaWQgcm9sbHVwIGVycm9ycy5cbiAgICAgICAgbWFudWFsQ2h1bmtzOiB7XG4gICAgICAgICAgLy8gUERGIGV4cG9ydCBsaWJyYXJpZXMgXHUyMDE0IGxhenkgbG9hZGVkIG9uIGRlbWFuZFxuICAgICAgICAgIHBkZkV4cG9ydDogW1wianNwZGZcIiwgXCJodG1sMmNhbnZhc1wiXSxcbiAgICAgICAgICAvLyBFeGNlbCBpbXBvcnQvZXhwb3J0IGxpYnJhcnkgXHUyMDE0IGxhenkgbG9hZGVkXG4gICAgICAgICAgZXhjZWxFeHBvcnQ6IFtcInhsc3hcIl0sXG4gICAgICAgICAgLy8gTWFwcGluZyBsaWJyYXJ5IFx1MjAxNCBsYXp5IGxvYWRlZFxuICAgICAgICAgIG1hcHM6IFtcImxlYWZsZXRcIl0sXG4gICAgICAgIH0sXG4gICAgICB9LFxuICAgIH0sXG4gICAgLy8gU2V0IGEgaGlnaGVyIGxpbWl0IHRvIGF2b2lkIHdhcm5pbmdzIGZvciBuZWNlc3NhcnkgbGFyZ2UgY2h1bmtzXG4gICAgY2h1bmtTaXplV2FybmluZ0xpbWl0OiA2MDAsXG4gICAgLy8gVGFyZ2V0IG1vZGVybiBicm93c2VycyBmb3Igc21hbGxlciBvdXRwdXRcbiAgICB0YXJnZXQ6IFwiZXMyMDIwXCIsXG4gIH0sXG4gIG9wdGltaXplRGVwczoge1xuICAgIGVudHJpZXM6IFtcImluZGV4Lmh0bWxcIl0sXG4gICAgaW5jbHVkZTogW1wicmVhY3RcIiwgXCJyZWFjdC1kb21cIiwgXCJyZWFjdC9qc3gtcnVudGltZVwiLCBcInJlYWN0L2pzeC1kZXYtcnVudGltZVwiLCBcImxlYWZsZXRcIl0sXG4gICAgZXhjbHVkZTogW1wicmVhY3QtbGVhZmxldFwiLCBcIkByZWFjdC1sZWFmbGV0L2NvcmVcIl0sXG4gIH0sXG59KSk7XG4iXSwKICAibWFwcGluZ3MiOiAiO0FBQXdVLFNBQVMsb0JBQW9CO0FBQ3JXLE9BQU8sV0FBVztBQUNsQixPQUFPLGlCQUFpQjtBQUN4QixPQUFPLFVBQVU7QUFDakIsU0FBUyx1QkFBdUI7QUFKaEMsSUFBTSxtQ0FBbUM7QUFPekMsSUFBTyxzQkFBUSxhQUFhLENBQUMsRUFBRSxLQUFLLE9BQU87QUFBQSxFQUN6QyxRQUFRO0FBQUEsSUFDTixNQUFNO0FBQUEsSUFDTixNQUFNO0FBQUEsSUFDTixLQUFLO0FBQUEsTUFDSCxTQUFTO0FBQUEsSUFDWDtBQUFBLElBQ0EsT0FBTztBQUFBO0FBQUE7QUFBQTtBQUFBO0FBQUEsTUFLTCxRQUFRO0FBQUEsUUFDTixRQUFRO0FBQUEsUUFDUixjQUFjO0FBQUEsUUFDZCxRQUFRO0FBQUEsTUFDVjtBQUFBLE1BQ0EsY0FBYztBQUFBLFFBQ1osUUFBUTtBQUFBLFFBQ1IsY0FBYztBQUFBLFFBQ2QsSUFBSTtBQUFBLE1BQ047QUFBQSxJQUNGO0FBQUEsRUFDRjtBQUFBLEVBQ0EsU0FBUztBQUFBLElBQ1AsWUFBWTtBQUFBLElBQ1osTUFBTTtBQUFBLElBQ04sU0FBUyxpQkFBaUIsZ0JBQWdCO0FBQUEsRUFDNUMsRUFBRSxPQUFPLE9BQU87QUFBQSxFQUNoQixRQUFRO0FBQUEsSUFDTiw4QkFBOEIsS0FBSyxVQUFVLFFBQVEsSUFBSSxrQkFBa0IsRUFBRTtBQUFBLElBQzdFLGtDQUFrQyxLQUFLLFVBQVUsUUFBUSxJQUFJLHNCQUFzQixFQUFFO0FBQUE7QUFBQTtBQUFBO0FBQUE7QUFBQTtBQUFBO0FBQUEsSUFPckYsa0NBQWtDLEtBQUssVUFBVSxDQUFDLENBQUMsUUFBUSxJQUFJLE1BQU07QUFBQSxFQUN2RTtBQUFBLEVBQ0EsU0FBUztBQUFBLElBQ1AsT0FBTztBQUFBLE1BQ0wsS0FBSyxLQUFLLFFBQVEsa0NBQVcsT0FBTztBQUFBLElBQ3RDO0FBQUEsSUFDQSxRQUFRLENBQUMsU0FBUyxhQUFhLHFCQUFxQix1QkFBdUI7QUFBQSxFQUM3RTtBQUFBLEVBQ0EsT0FBTztBQUFBLElBQ0wsZUFBZTtBQUFBLE1BQ2IsUUFBUTtBQUFBO0FBQUE7QUFBQTtBQUFBLFFBSU4sY0FBYztBQUFBO0FBQUEsVUFFWixXQUFXLENBQUMsU0FBUyxhQUFhO0FBQUE7QUFBQSxVQUVsQyxhQUFhLENBQUMsTUFBTTtBQUFBO0FBQUEsVUFFcEIsTUFBTSxDQUFDLFNBQVM7QUFBQSxRQUNsQjtBQUFBLE1BQ0Y7QUFBQSxJQUNGO0FBQUE7QUFBQSxJQUVBLHVCQUF1QjtBQUFBO0FBQUEsSUFFdkIsUUFBUTtBQUFBLEVBQ1Y7QUFBQSxFQUNBLGNBQWM7QUFBQSxJQUNaLFNBQVMsQ0FBQyxZQUFZO0FBQUEsSUFDdEIsU0FBUyxDQUFDLFNBQVMsYUFBYSxxQkFBcUIseUJBQXlCLFNBQVM7QUFBQSxJQUN2RixTQUFTLENBQUMsaUJBQWlCLHFCQUFxQjtBQUFBLEVBQ2xEO0FBQ0YsRUFBRTsiLAogICJuYW1lcyI6IFtdCn0K
