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
//# sourceMappingURL=data:application/json;base64,ewogICJ2ZXJzaW9uIjogMywKICAic291cmNlcyI6IFsidml0ZS5jb25maWcudHMiXSwKICAic291cmNlc0NvbnRlbnQiOiBbImNvbnN0IF9fdml0ZV9pbmplY3RlZF9vcmlnaW5hbF9kaXJuYW1lID0gXCJDOlxcXFxVc2Vyc1xcXFxhYmlzaFxcXFxEb3dubG9hZHNcXFxcZGl3YW4tbWFpblxcXFxkaXdhbi1tYWluXCI7Y29uc3QgX192aXRlX2luamVjdGVkX29yaWdpbmFsX2ZpbGVuYW1lID0gXCJDOlxcXFxVc2Vyc1xcXFxhYmlzaFxcXFxEb3dubG9hZHNcXFxcZGl3YW4tbWFpblxcXFxkaXdhbi1tYWluXFxcXHZpdGUuY29uZmlnLnRzXCI7Y29uc3QgX192aXRlX2luamVjdGVkX29yaWdpbmFsX2ltcG9ydF9tZXRhX3VybCA9IFwiZmlsZTovLy9DOi9Vc2Vycy9hYmlzaC9Eb3dubG9hZHMvZGl3YW4tbWFpbi9kaXdhbi1tYWluL3ZpdGUuY29uZmlnLnRzXCI7aW1wb3J0IHsgZGVmaW5lQ29uZmlnIH0gZnJvbSBcInZpdGVcIjtcbmltcG9ydCByZWFjdCBmcm9tIFwiQHZpdGVqcy9wbHVnaW4tcmVhY3Qtc3djXCI7XG5pbXBvcnQgdGFpbHdpbmRjc3MgZnJvbSBcIkB0YWlsd2luZGNzcy92aXRlXCI7XG5pbXBvcnQgcGF0aCBmcm9tIFwicGF0aFwiO1xuaW1wb3J0IHsgY29tcG9uZW50VGFnZ2VyIH0gZnJvbSBcImxvdmFibGUtdGFnZ2VyXCI7XG5cbi8vIGh0dHBzOi8vdml0ZWpzLmRldi9jb25maWcvXG5leHBvcnQgZGVmYXVsdCBkZWZpbmVDb25maWcoKHsgbW9kZSB9KSA9PiAoe1xuICBzZXJ2ZXI6IHtcbiAgICBob3N0OiBcIjo6XCIsXG4gICAgcG9ydDogMzAwMCxcbiAgICBobXI6IHtcbiAgICAgIG92ZXJsYXk6IGZhbHNlLFxuICAgIH0sXG4gICAgcHJveHk6IHtcbiAgICAgIC8vIEZvcndhcmQgYWxsIC9hcGkgYW5kIC9zb2NrZXQuaW8gcmVxdWVzdHMgdG8gdGhlIEV4cHJlc3MgQVBJIHNlcnZlclxuICAgICAgLy8gcnVubmluZyBvbiBwb3J0IDMwMDEuIFdpdGhvdXQgdGhpcyBwcm94eSwgVml0ZSBpbnRlcmNlcHRzIC9hcGkgY2FsbHNcbiAgICAgIC8vIGFuZCByZXR1cm5zIGFuIEhUTUwgcGFnZSBcdTIwMTQgY2F1c2luZyB0aGUgXCJVbmV4cGVjdGVkIHRva2VuICdBJ1wiIEpTT05cbiAgICAgIC8vIHBhcnNlIGVycm9yIG9uIGV2ZXJ5IEFQSSByZXF1ZXN0IGluY2x1ZGluZyBsb2dpbi5cbiAgICAgICcvYXBpJzoge1xuICAgICAgICB0YXJnZXQ6ICdodHRwOi8vbG9jYWxob3N0OjMwMDEnLFxuICAgICAgICBjaGFuZ2VPcmlnaW46IHRydWUsXG4gICAgICAgIHNlY3VyZTogZmFsc2UsXG4gICAgICB9LFxuICAgICAgJy9zb2NrZXQuaW8nOiB7XG4gICAgICAgIHRhcmdldDogJ2h0dHA6Ly9sb2NhbGhvc3Q6MzAwMScsXG4gICAgICAgIGNoYW5nZU9yaWdpbjogdHJ1ZSxcbiAgICAgICAgd3M6IHRydWUsXG4gICAgICB9LFxuICAgIH0sXG4gIH0sXG4gIHBsdWdpbnM6IFtcbiAgICB0YWlsd2luZGNzcygpLFxuICAgIHJlYWN0KCksXG4gICAgbW9kZSA9PT0gXCJkZXZlbG9wbWVudFwiICYmIGNvbXBvbmVudFRhZ2dlcigpLFxuICBdLmZpbHRlcihCb29sZWFuKSxcbiAgZGVmaW5lOiB7XG4gICAgXCJwcm9jZXNzLmVudi5HRU1JTklfQVBJX0tFWVwiOiBKU09OLnN0cmluZ2lmeShwcm9jZXNzLmVudi5HRU1JTklfQVBJX0tFWSB8fCBcIlwiKSxcbiAgICAvLyBWZXJjZWwncyBzZXJ2ZXJsZXNzIGludm9jYXRpb24gbW9kZWwgKGFwaS9pbmRleC50cyBjYWxsaW5nIHRoZSBFeHByZXNzXG4gICAgLy8gYXBwIGRpcmVjdGx5LCBwZXItcmVxdWVzdCwgd2l0aCBubyBwZXJzaXN0ZW50IGh0dHBTZXJ2ZXIpIG1lYW5zIHRoZVxuICAgIC8vIFNvY2tldC5JTyBzZXJ2ZXIgaW4gc2VydmVyLnRzIG5ldmVyIGFjdHVhbGx5IGF0dGFjaGVzIHRoZXJlIFx1MjAxNCBvbmx5IHRoZVxuICAgIC8vIHRyYWRpdGlvbmFsIGBodHRwU2VydmVyLmxpc3RlbigpYCBwYXRoIGRvZXMuIFN1cmZhY2luZyB0aGF0IGF0IGJ1aWxkXG4gICAgLy8gdGltZSBsZXRzIHRoZSBjbGllbnQgc2tpcCB0cnlpbmcgdG8gb3BlbiBhIHNvY2tldCBjb25uZWN0aW9uIHRoYXQgY2FuXG4gICAgLy8gbmV2ZXIgc3VjY2VlZCwgaW5zdGVhZCBvZiByZXRyeWluZyBpbiBhIHRpZ2h0LCBjb25uZWN0aW9uLXN0YXJ2aW5nIGxvb3AuXG4gICAgXCJpbXBvcnQubWV0YS5lbnYuVklURV9JU19WRVJDRUxcIjogSlNPTi5zdHJpbmdpZnkoISFwcm9jZXNzLmVudi5WRVJDRUwpLFxuICB9LFxuICByZXNvbHZlOiB7XG4gICAgYWxpYXM6IHtcbiAgICAgIFwiQFwiOiBwYXRoLnJlc29sdmUoX19kaXJuYW1lLCBcIi4vc3JjXCIpLFxuICAgIH0sXG4gICAgZGVkdXBlOiBbXCJyZWFjdFwiLCBcInJlYWN0LWRvbVwiLCBcInJlYWN0L2pzeC1ydW50aW1lXCIsIFwicmVhY3QvanN4LWRldi1ydW50aW1lXCJdLFxuICB9LFxuICBidWlsZDoge1xuICAgIHJvbGx1cE9wdGlvbnM6IHtcbiAgICAgIG91dHB1dDoge1xuICAgICAgICAvLyBTcGxpdCB2ZW5kb3IgbGlicmFyaWVzIGFuZCBoZWF2eSBleHBvcnQgbW9kdWxlcyBpbnRvIHNlcGFyYXRlIGNodW5rc1xuICAgICAgICAvLyB0byBlbmFibGUgYmV0dGVyIGNhY2hpbmcgYW5kIHBhcmFsbGVsIGxvYWRpbmcuIE9ubHkgaW5jbHVkZSBwYWNrYWdlc1xuICAgICAgICAvLyB0aGF0IGFyZSBhY3R1YWxseSBpbXBvcnRlZCB0byBhdm9pZCByb2xsdXAgZXJyb3JzLlxuICAgICAgICBtYW51YWxDaHVua3M6IHtcbiAgICAgICAgICAvLyBQREYgZXhwb3J0IGxpYnJhcmllcyBcdTIwMTQgbGF6eSBsb2FkZWQgb24gZGVtYW5kXG4gICAgICAgICAgcGRmRXhwb3J0OiBbXCJqc3BkZlwiLCBcImh0bWwyY2FudmFzXCJdLFxuICAgICAgICAgIC8vIEV4Y2VsIGltcG9ydC9leHBvcnQgbGlicmFyeSBcdTIwMTQgbGF6eSBsb2FkZWRcbiAgICAgICAgICBleGNlbEV4cG9ydDogW1wieGxzeFwiXSxcbiAgICAgICAgICAvLyBNYXBwaW5nIGxpYnJhcnkgXHUyMDE0IGxhenkgbG9hZGVkXG4gICAgICAgICAgbWFwczogW1wibGVhZmxldFwiXSxcbiAgICAgICAgfSxcbiAgICAgIH0sXG4gICAgfSxcbiAgICAvLyBTZXQgYSBoaWdoZXIgbGltaXQgdG8gYXZvaWQgd2FybmluZ3MgZm9yIG5lY2Vzc2FyeSBsYXJnZSBjaHVua3NcbiAgICBjaHVua1NpemVXYXJuaW5nTGltaXQ6IDYwMCxcbiAgICAvLyBUYXJnZXQgbW9kZXJuIGJyb3dzZXJzIGZvciBzbWFsbGVyIG91dHB1dFxuICAgIHRhcmdldDogXCJlczIwMjBcIixcbiAgfSxcbiAgb3B0aW1pemVEZXBzOiB7XG4gICAgZW50cmllczogW1wiaW5kZXguaHRtbFwiXSxcbiAgICBpbmNsdWRlOiBbXCJyZWFjdFwiLCBcInJlYWN0LWRvbVwiLCBcInJlYWN0L2pzeC1ydW50aW1lXCIsIFwicmVhY3QvanN4LWRldi1ydW50aW1lXCIsIFwibGVhZmxldFwiXSxcbiAgICBleGNsdWRlOiBbXCJyZWFjdC1sZWFmbGV0XCIsIFwiQHJlYWN0LWxlYWZsZXQvY29yZVwiXSxcbiAgfSxcbn0pKTtcbiJdLAogICJtYXBwaW5ncyI6ICI7QUFBd1UsU0FBUyxvQkFBb0I7QUFDclcsT0FBTyxXQUFXO0FBQ2xCLE9BQU8saUJBQWlCO0FBQ3hCLE9BQU8sVUFBVTtBQUNqQixTQUFTLHVCQUF1QjtBQUpoQyxJQUFNLG1DQUFtQztBQU96QyxJQUFPLHNCQUFRLGFBQWEsQ0FBQyxFQUFFLEtBQUssT0FBTztBQUFBLEVBQ3pDLFFBQVE7QUFBQSxJQUNOLE1BQU07QUFBQSxJQUNOLE1BQU07QUFBQSxJQUNOLEtBQUs7QUFBQSxNQUNILFNBQVM7QUFBQSxJQUNYO0FBQUEsSUFDQSxPQUFPO0FBQUE7QUFBQTtBQUFBO0FBQUE7QUFBQSxNQUtMLFFBQVE7QUFBQSxRQUNOLFFBQVE7QUFBQSxRQUNSLGNBQWM7QUFBQSxRQUNkLFFBQVE7QUFBQSxNQUNWO0FBQUEsTUFDQSxjQUFjO0FBQUEsUUFDWixRQUFRO0FBQUEsUUFDUixjQUFjO0FBQUEsUUFDZCxJQUFJO0FBQUEsTUFDTjtBQUFBLElBQ0Y7QUFBQSxFQUNGO0FBQUEsRUFDQSxTQUFTO0FBQUEsSUFDUCxZQUFZO0FBQUEsSUFDWixNQUFNO0FBQUEsSUFDTixTQUFTLGlCQUFpQixnQkFBZ0I7QUFBQSxFQUM1QyxFQUFFLE9BQU8sT0FBTztBQUFBLEVBQ2hCLFFBQVE7QUFBQSxJQUNOLDhCQUE4QixLQUFLLFVBQVUsUUFBUSxJQUFJLGtCQUFrQixFQUFFO0FBQUE7QUFBQTtBQUFBO0FBQUE7QUFBQTtBQUFBO0FBQUEsSUFPN0Usa0NBQWtDLEtBQUssVUFBVSxDQUFDLENBQUMsUUFBUSxJQUFJLE1BQU07QUFBQSxFQUN2RTtBQUFBLEVBQ0EsU0FBUztBQUFBLElBQ1AsT0FBTztBQUFBLE1BQ0wsS0FBSyxLQUFLLFFBQVEsa0NBQVcsT0FBTztBQUFBLElBQ3RDO0FBQUEsSUFDQSxRQUFRLENBQUMsU0FBUyxhQUFhLHFCQUFxQix1QkFBdUI7QUFBQSxFQUM3RTtBQUFBLEVBQ0EsT0FBTztBQUFBLElBQ0wsZUFBZTtBQUFBLE1BQ2IsUUFBUTtBQUFBO0FBQUE7QUFBQTtBQUFBLFFBSU4sY0FBYztBQUFBO0FBQUEsVUFFWixXQUFXLENBQUMsU0FBUyxhQUFhO0FBQUE7QUFBQSxVQUVsQyxhQUFhLENBQUMsTUFBTTtBQUFBO0FBQUEsVUFFcEIsTUFBTSxDQUFDLFNBQVM7QUFBQSxRQUNsQjtBQUFBLE1BQ0Y7QUFBQSxJQUNGO0FBQUE7QUFBQSxJQUVBLHVCQUF1QjtBQUFBO0FBQUEsSUFFdkIsUUFBUTtBQUFBLEVBQ1Y7QUFBQSxFQUNBLGNBQWM7QUFBQSxJQUNaLFNBQVMsQ0FBQyxZQUFZO0FBQUEsSUFDdEIsU0FBUyxDQUFDLFNBQVMsYUFBYSxxQkFBcUIseUJBQXlCLFNBQVM7QUFBQSxJQUN2RixTQUFTLENBQUMsaUJBQWlCLHFCQUFxQjtBQUFBLEVBQ2xEO0FBQ0YsRUFBRTsiLAogICJuYW1lcyI6IFtdCn0K
