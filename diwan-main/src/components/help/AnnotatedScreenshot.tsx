import { useState } from "react";
import { ImageOff, ZoomIn, X } from "lucide-react";
import type { ScreenshotAnnotation } from "@/lib/userGuides/types";

interface AnnotatedScreenshotProps {
  src: string;
  caption: string;
  alt: string;
  annotations: ScreenshotAnnotation[];
}

export function AnnotatedScreenshot({ src, caption, alt, annotations }: AnnotatedScreenshotProps) {
  const [imgError, setImgError] = useState(false);
  const [activePin, setActivePin] = useState<number | null>(null);
  const [lightboxOpen, setLightboxOpen] = useState(false);

  return (
    <div className="my-8 space-y-3 not-prose">
      {/* Image container */}
      <div
        className="relative rounded-2xl overflow-hidden border border-slate-200 dark:border-slate-700 bg-slate-900 shadow-xl cursor-zoom-in group"
        onClick={() => !imgError && setLightboxOpen(true)}
      >
        {imgError ? (
          /* Placeholder when screenshot not yet captured */
          <div className="aspect-video flex flex-col items-center justify-center gap-3 bg-gradient-to-br from-slate-800 to-slate-900 text-slate-400">
            <ImageOff className="h-10 w-10 opacity-40" />
            <div className="text-center">
              <p className="text-sm font-semibold text-slate-300">Screenshot pending</p>
              <p className="text-xs text-slate-500 mt-0.5 font-mono">{src}</p>
            </div>
            <div className="mt-2 text-xs text-slate-500 text-center max-w-xs leading-relaxed">
              Run <code className="bg-slate-700 px-1.5 py-0.5 rounded text-slate-300">node scripts/capture-guide-screenshots.cjs</code> to auto-capture all screenshots
            </div>
          </div>
        ) : (
          <>
            <img
              src={src}
              alt={alt}
              className="w-full object-cover"
              onError={() => setImgError(true)}
            />
            {/* Zoom hint */}
            <div className="absolute top-3 right-3 opacity-0 group-hover:opacity-100 transition-opacity bg-black/60 text-white text-xs font-semibold px-2.5 py-1.5 rounded-lg flex items-center gap-1.5 backdrop-blur-sm pointer-events-none">
              <ZoomIn className="h-3.5 w-3.5" /> Click to enlarge
            </div>
          </>
        )}

        {/* Annotation pins — shown even on placeholder */}
        {annotations.map((a) => (
          <AnnotationPin
            key={a.id}
            annotation={a}
            active={activePin === a.id}
            onClick={(e) => {
              e.stopPropagation();
              setActivePin(activePin === a.id ? null : a.id);
            }}
          />
        ))}
      </div>

      {/* Caption */}
      {caption && (
        <p className="text-center text-xs font-semibold text-slate-500 dark:text-slate-400 italic">
          {caption}
        </p>
      )}

      {/* Annotation Legend */}
      {annotations.length > 0 && (
        <div className="grid gap-1.5 sm:grid-cols-2">
          {annotations.map((a) => (
            <button
              key={a.id}
              onClick={() => setActivePin(activePin === a.id ? null : a.id)}
              className={`flex items-start gap-3 px-3.5 py-2.5 rounded-xl text-left transition-all border text-xs
                ${activePin === a.id
                  ? "border-violet-400 bg-violet-50 dark:bg-violet-950/30"
                  : "border-slate-200 dark:border-slate-700 hover:border-violet-300 hover:bg-slate-50 dark:hover:bg-slate-800/50"
                }`}
            >
              <span className={`flex-shrink-0 w-5 h-5 rounded-full flex items-center justify-center font-black text-[10px] text-white transition-colors
                ${activePin === a.id ? "bg-violet-600" : "bg-slate-600"}`}>
                {a.id}
              </span>
              <div>
                <div className="font-bold text-slate-700 dark:text-slate-200">{a.label}</div>
                <div className="text-slate-500 dark:text-slate-400 leading-relaxed mt-0.5">{a.description}</div>
              </div>
            </button>
          ))}
        </div>
      )}

      {/* Lightbox */}
      {lightboxOpen && !imgError && (
        <div
          className="fixed inset-0 bg-black/90 z-[100] flex items-center justify-center p-4 backdrop-blur-sm"
          onClick={() => setLightboxOpen(false)}
        >
          <button
            onClick={() => setLightboxOpen(false)}
            className="absolute top-4 right-4 h-10 w-10 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center text-white transition-colors"
          >
            <X className="h-5 w-5" />
          </button>
          <img
            src={src}
            alt={alt}
            className="max-w-full max-h-[90vh] object-contain rounded-xl shadow-2xl"
            onClick={(e) => e.stopPropagation()}
          />
          {caption && (
            <p className="absolute bottom-4 left-0 right-0 text-center text-sm text-white/70 font-medium">
              {caption}
            </p>
          )}
        </div>
      )}
    </div>
  );
}

function AnnotationPin({
  annotation,
  active,
  onClick,
}: {
  annotation: ScreenshotAnnotation;
  active: boolean;
  onClick: (e: React.MouseEvent) => void;
}) {
  return (
    <div
      className="absolute"
      style={{ left: `${annotation.x}%`, top: `${annotation.y}%`, transform: "translate(-50%, -50%)" }}
    >
      {/* Pulse ring */}
      {active && (
        <div className="absolute inset-0 rounded-full bg-violet-500/30 animate-ping scale-150" />
      )}

      {/* Pin button */}
      <button
        onClick={onClick}
        className={`relative w-6 h-6 rounded-full border-2 border-white shadow-lg flex items-center justify-center font-black text-[10px] text-white transition-all z-10
          ${active ? "bg-violet-600 scale-125 shadow-violet-500/50 shadow-xl" : "bg-slate-800 hover:bg-violet-600 hover:scale-110"}`}
      >
        {annotation.id}
      </button>

      {/* Tooltip */}
      {active && (
        <div
          className="absolute z-20 bg-slate-900 text-white rounded-xl shadow-2xl p-3 w-44 border border-slate-700 pointer-events-none"
          style={{
            left: annotation.x > 75 ? "auto" : "120%",
            right: annotation.x > 75 ? "120%" : "auto",
            top: annotation.y > 75 ? "auto" : "0",
            bottom: annotation.y > 75 ? "0" : "auto",
          }}
        >
          <div className="text-[10px] font-black text-violet-400 uppercase tracking-wider mb-1">
            {annotation.id}. {annotation.label}
          </div>
          <div className="text-xs text-slate-300 leading-relaxed">{annotation.description}</div>
        </div>
      )}
    </div>
  );
}
