import { useState, useEffect } from "react";
import {
  HelpCircle, MessageSquare, AlertOctagon, Lightbulb, X,
  Send, ChevronRight, ChevronLeft, Check, Sparkles
} from "lucide-react";
import { smartDb } from "@/lib/localDb";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useAuth } from "@/hooks/useAuth";

// ── Need Help? Widget ────────────────────────────────────────────────────────
export function NeedHelpWidget() {
  const { role, user } = useAuth();
  const [isOpen, setIsOpen] = useState(false);
  const [tab, setTab] = useState<"menu" | "support" | "issue" | "suggest">("menu");
  const [subject, setSubject] = useState("");
  const [description, setDescription] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!description.trim()) {
      toast.error("Please enter a description.");
      return;
    }
    setSubmitting(true);
    try {
      await smartDb.create("SupportTicket", {
        type: tab,
        subject: subject || `${tab.toUpperCase()} Submission`,
        description,
        status: "Open",
        createdAt: new Date().toISOString(),
        submittedBy: user?.email ?? "anonymous",
        role: role ?? "unknown",
      });
      toast.success("Thank you! Your request has been logged successfully.");
      setSubject("");
      setDescription("");
      setTab("menu");
      setIsOpen(false);
    } catch {
      toast.error("Failed to log ticket. Please try again.");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="fixed bottom-6 right-6 z-40 font-semibold print:hidden">
      
      {/* Floating Action Button */}
      {!isOpen && (
        <button
          onClick={() => setIsOpen(true)}
          className="h-14 px-5 rounded-full bg-violet-600 hover:bg-violet-700 text-white shadow-2xl flex items-center gap-2.5 hover:scale-105 active:scale-95 transition-all"
        >
          <HelpCircle className="h-5 w-5" />
          <span className="text-sm font-bold tracking-wide">Need Help?</span>
        </button>
      )}

      {/* Widget Container Panel */}
      {isOpen && (
        <div className="w-80 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl shadow-[0_20px_50px_rgba(0,0,0,0.15)] overflow-hidden animate-in slide-in-from-bottom-5 duration-200">
          
          {/* Header */}
          <div className="bg-slate-900 text-white px-4 py-3 flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Sparkles className="h-4 w-4 text-violet-400" />
              <span className="text-sm font-black tracking-wide">Support Desk</span>
            </div>
            <button 
              onClick={() => { setIsOpen(false); setTab("menu"); }}
              className="text-slate-400 hover:text-white"
            >
              <X className="h-4 w-4" />
            </button>
          </div>

          {/* Body panel */}
          <div className="p-4">
            {tab === "menu" && (
              <div className="space-y-2">
                <p className="text-xs text-slate-500 mb-3">How would you like to proceed?</p>
                <button 
                  onClick={() => setTab("support")}
                  className="w-full flex items-center gap-3 p-3 rounded-xl hover:bg-slate-50 dark:hover:bg-slate-800 text-left border border-slate-100 dark:border-slate-800 transition-colors"
                >
                  <div className="h-8 w-8 rounded-lg bg-violet-50 text-violet-600 flex items-center justify-center shrink-0">
                    <MessageSquare className="h-4 w-4" />
                  </div>
                  <div>
                    <div className="text-xs font-bold text-slate-800 dark:text-slate-200">Contact Support</div>
                    <p className="text-[10px] text-slate-400 mt-0.5">Submit a general inquiry ticket</p>
                  </div>
                </button>

                <button 
                  onClick={() => setTab("issue")}
                  className="w-full flex items-center gap-3 p-3 rounded-xl hover:bg-slate-50 dark:hover:bg-slate-800 text-left border border-slate-100 dark:border-slate-800 transition-colors"
                >
                  <div className="h-8 w-8 rounded-lg bg-rose-50 text-rose-600 flex items-center justify-center shrink-0">
                    <AlertOctagon className="h-4 w-4" />
                  </div>
                  <div>
                    <div className="text-xs font-bold text-slate-800 dark:text-slate-200">Report Doc Issue</div>
                    <p className="text-[10px] text-slate-400 mt-0.5">Flag inaccurate or broken details</p>
                  </div>
                </button>

                <button 
                  onClick={() => setTab("suggest")}
                  className="w-full flex items-center gap-3 p-3 rounded-xl hover:bg-slate-50 dark:hover:bg-slate-800 text-left border border-slate-100 dark:border-slate-800 transition-colors"
                >
                  <div className="h-8 w-8 rounded-lg bg-amber-50 text-amber-600 flex items-center justify-center shrink-0">
                    <Lightbulb className="h-4 w-4" />
                  </div>
                  <div>
                    <div className="text-xs font-bold text-slate-800 dark:text-slate-200">Suggest Improvement</div>
                    <p className="text-[10px] text-slate-400 mt-0.5">Submit feature recommendations</p>
                  </div>
                </button>
              </div>
            )}

            {tab !== "menu" && (
              <form onSubmit={handleSubmit} className="space-y-3.5">
                <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-2">
                  <span className="text-xs font-bold text-slate-700 dark:text-slate-300 capitalize">
                    {tab === "support" ? "Support Ticket" : tab === "issue" ? "Report Documentation Issue" : "Suggest Improvement"}
                  </span>
                  <button 
                    type="button" 
                    onClick={() => setTab("menu")}
                    className="text-[10px] text-violet-600 font-bold hover:underline"
                  >
                    Back
                  </button>
                </div>

                <div className="space-y-1">
                  <label className="text-[10px] text-slate-400 font-black uppercase">Subject</label>
                  <Input 
                    placeholder="Enter short topic title..."
                    value={subject}
                    onChange={(e) => setSubject(e.target.value)}
                    className="h-9 text-xs rounded-xl"
                  />
                </div>

                <div className="space-y-1">
                  <label className="text-[10px] text-slate-400 font-black uppercase">Description</label>
                  <textarea 
                    placeholder="Provide details..."
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    className="w-full min-h-[90px] text-xs p-3 border border-slate-200 dark:border-slate-800 rounded-xl focus:outline-none focus:ring-1 focus:ring-violet-500 bg-transparent"
                    required
                  />
                </div>

                <Button 
                  type="submit" 
                  disabled={submitting} 
                  className="w-full h-9 bg-violet-600 hover:bg-violet-700 text-white rounded-xl text-xs gap-1.5"
                >
                  <Send className="h-3 w-3" />
                  {submitting ? "Submitting..." : "Submit Request"}
                </Button>
              </form>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

// ── Interactive Guided Tour ──────────────────────────────────────────────────
export interface TourStep {
  target: string;
  title: string;
  content: string;
}

interface GuidedTourProps {
  steps: TourStep[];
  active: boolean;
  onClose: () => void;
}

export function GuidedTour({ steps, active, onClose }: GuidedTourProps) {
  const [currentStep, setCurrentStep] = useState(0);

  if (!active || steps.length === 0) return null;

  const step = steps[currentStep];

  const handleNext = () => {
    if (currentStep < steps.length - 1) {
      setCurrentStep(currentStep + 1);
    } else {
      onClose();
    }
  };

  const handlePrev = () => {
    if (currentStep > 0) {
      setCurrentStep(currentStep - 1);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/10 backdrop-blur-[1px] z-50 flex items-center justify-center p-4">
      <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl shadow-2xl p-6 max-w-sm w-full space-y-4 animate-in zoom-in-95 duration-200">
        <div className="flex items-center justify-between">
          <Badge variant="outline" className="text-[10px] uppercase font-black border-violet-200 text-violet-600 bg-violet-50/50">
            Guide Step {currentStep + 1} of {steps.length}
          </Badge>
          <button onClick={onClose} className="text-slate-400 hover:text-slate-600">
            <X className="h-4 w-4" />
          </button>
        </div>
        
        <div>
          <h4 className="text-sm font-bold text-slate-800 dark:text-slate-200">{step.title}</h4>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-2 leading-relaxed">{step.content}</p>
        </div>

        <div className="flex items-center justify-between pt-2">
          <button 
            onClick={handlePrev}
            disabled={currentStep === 0}
            className="text-xs text-slate-400 hover:text-slate-600 disabled:opacity-30 disabled:pointer-events-none flex items-center gap-1"
          >
            <ChevronLeft className="h-3 w-3" /> Previous
          </button>
          
          <button
            onClick={handleNext}
            className="h-8 px-4 rounded-xl bg-violet-600 hover:bg-violet-700 text-white text-xs font-bold flex items-center gap-1.5"
          >
            {currentStep === steps.length - 1 ? (
              <>
                <Check className="h-3 w-3" /> Finish
              </>
            ) : (
              <>
                Next <ChevronRight className="h-3 w-3" />
              </>
            )}
          </button>
        </div>
      </div>
    </div>
  );
}
