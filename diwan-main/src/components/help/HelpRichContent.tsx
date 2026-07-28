import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import { useState } from "react";
import { 
  Info, AlertTriangle, CheckCircle, Flame, Lightbulb, Copy, Check 
} from "lucide-react";
import { Badge } from "@/components/ui/badge";

interface HelpRichContentProps {
  content: string;
}

export function HelpRichContent({ content }: HelpRichContentProps) {
  // Pre-process callouts:
  // We parse :::info \n text \n ::: and wrap it in a custom block that can be rendered
  const processCallouts = (text: string) => {
    if (!text) return "";
    
    // Replace :::info ... :::
    const types = ["info", "warning", "success", "danger", "tip"];
    let processed = text;
    
    types.forEach(type => {
      const regex = new RegExp(`:::${type}\\s*\\n([\\s\\S]*?)\\n:::`, "g");
      processed = processed.replace(regex, (_, innerText) => {
        // Return a markdown block wrapped in custom identifiers
        return `\n<div class="callout-${type}">${innerText}</div>\n`;
      });
    });
    
    return processed;
  };

  const cleanContent = processCallouts(content);

  // Custom components for ReactMarkdown renderer
  const customRenderers = {
    // Custom HTML node renderer to parse our callout divs
    div: ({ node, className, children, ...props }: any) => {
      const cls = className || props.class || "";
      if (cls.startsWith("callout-")) {
        const type = cls.replace("callout-", "");
        return <CalloutBox type={type}>{children}</CalloutBox>;
      }
      return <div className={className} {...props}>{children}</div>;
    },
    // Code block copy button
    code: ({ node, inline, className, children, ...props }: any) => {
      const match = /language-(\w+)/.exec(className || "");
      const codeVal = String(children).replace(/\n$/, "");
      
      if (!inline && match) {
        return <CodeBlock code={codeVal} language={match[1]} />;
      }
      // Keyboard shortcut badge render [Ctrl] or similar
      if (inline && codeVal.startsWith("[") && codeVal.endsWith("]")) {
        return (
          <kbd className="px-1.5 py-0.5 text-[10px] font-black uppercase tracking-wider bg-slate-100 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded shadow-xs text-slate-600 dark:text-slate-300">
            {codeVal.slice(1, -1)}
          </kbd>
        );
      }
      return (
        <code className="px-1.5 py-0.5 rounded bg-slate-50 dark:bg-slate-800/80 text-violet-600 dark:text-violet-400 font-mono text-sm" {...props}>
          {children}
        </code>
      );
    },
    table: ({ children }: any) => (
      <div className="overflow-x-auto my-6 border border-slate-100 dark:border-slate-800 rounded-xl">
        <table className="min-w-full divide-y divide-slate-100 dark:divide-slate-800 text-sm">
          {children}
        </table>
      </div>
    ),
    thead: ({ children }: any) => <thead className="bg-slate-50/70 dark:bg-slate-900/40">{children}</thead>,
    tbody: ({ children }: any) => <tbody className="divide-y divide-slate-100 dark:divide-slate-800/60">{children}</tbody>,
    tr: ({ children }: any) => <tr className="hover:bg-slate-50/30 transition-colors">{children}</tr>,
    th: ({ children }: any) => <th className="px-4 py-3 text-left font-bold text-slate-500 uppercase tracking-widest text-[10px]">{children}</th>,
    td: ({ children }: any) => <td className="px-4 py-3 text-slate-600 dark:text-slate-400 font-semibold">{children}</td>,
    a: ({ href, children }: any) => (
      <a href={href} className="text-violet-600 dark:text-violet-400 font-bold hover:underline">
        {children}
      </a>
    ),
    h2: ({ children }: any) => {
      const id = String(children).toLowerCase().replace(/[^a-z0-9]+/g, "-");
      return <h2 id={id} className="text-xl font-bold tracking-tight text-slate-800 dark:text-slate-200 mt-8 mb-4 border-b border-slate-100 dark:border-slate-800/60 pb-2">{children}</h2>;
    },
    h3: ({ children }: any) => {
      const id = String(children).toLowerCase().replace(/[^a-z0-9]+/g, "-");
      return <h3 id={id} className="text-lg font-bold text-slate-800 dark:text-slate-200 mt-6 mb-3">{children}</h3>;
    }
  };

  return (
    <article className="prose prose-sm sm:prose-base dark:prose-invert max-w-none text-slate-600 dark:text-slate-400">
      <ReactMarkdown 
        remarkPlugins={[remarkGfm]} 
        components={customRenderers as any}
      >
        {cleanContent}
      </ReactMarkdown>
    </article>
  );
}

// Interactive Copyable Code Block
function CodeBlock({ code, language }: { code: string; language: string }) {
  const [copied, setCopied] = useState(false);

  const handleCopy = () => {
    navigator.clipboard.writeText(code);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="relative group border border-slate-100 dark:border-slate-800 rounded-xl my-6 bg-slate-900 text-slate-100 overflow-hidden font-mono">
      <div className="flex items-center justify-between px-4 py-2 border-b border-slate-800 bg-slate-950 text-slate-400 text-xs">
        <span>{language.toUpperCase()}</span>
        <button 
          onClick={handleCopy}
          className="flex items-center gap-1.5 hover:text-slate-200 transition-colors"
        >
          {copied ? (
            <>
              <Check className="h-3 w-3 text-emerald-400" />
              <span className="text-emerald-400">Copied!</span>
            </>
          ) : (
            <>
              <Copy className="h-3 w-3" />
              <span>Copy code</span>
            </>
          )}
        </button>
      </div>
      <pre className="p-4 overflow-x-auto text-sm leading-relaxed">
        <code>{code}</code>
      </pre>
    </div>
  );
}

// Callout Boxes Component
function CalloutBox({ type, children }: { type: string; children: React.ReactNode }) {
  const configs: Record<string, { bg: string; border: string; text: string; icon: any; label: string }> = {
    info: { 
      bg: "bg-blue-50/50 dark:bg-blue-950/20", 
      border: "border-blue-200 dark:border-blue-800", 
      text: "text-blue-800 dark:text-blue-400", 
      icon: Info, 
      label: "Information" 
    },
    warning: { 
      bg: "bg-amber-50/50 dark:bg-amber-950/20", 
      border: "border-amber-200 dark:border-amber-800", 
      text: "text-amber-800 dark:text-amber-400", 
      icon: AlertTriangle, 
      label: "Warning" 
    },
    success: { 
      bg: "bg-emerald-50/50 dark:bg-emerald-950/20", 
      border: "border-emerald-200 dark:border-emerald-800", 
      text: "text-emerald-800 dark:text-emerald-400", 
      icon: CheckCircle, 
      label: "Success" 
    },
    danger: { 
      bg: "bg-rose-50/50 dark:bg-rose-950/20", 
      border: "border-rose-200 dark:border-rose-800", 
      text: "text-rose-800 dark:text-rose-400", 
      icon: Flame, 
      label: "Danger" 
    },
    tip: { 
      bg: "bg-purple-50/50 dark:bg-purple-950/20", 
      border: "border-purple-200 dark:border-purple-800", 
      text: "text-purple-800 dark:text-purple-400", 
      icon: Lightbulb, 
      label: "Tip" 
    }
  };

  const config = configs[type] || configs.info;
  const Icon = config.icon;

  return (
    <div className={`p-4 rounded-xl border ${config.bg} ${config.border} my-6 flex gap-3.5`}>
      <Icon className={`h-5 w-5 ${config.text} shrink-0 mt-0.5`} />
      <div className="flex-1">
        <div className={`text-[10px] font-black uppercase tracking-wider mb-1 ${config.text}`}>
          {config.label}
        </div>
        <div className="text-sm font-semibold leading-relaxed text-slate-700 dark:text-slate-300">
          {children}
        </div>
      </div>
    </div>
  );
}
