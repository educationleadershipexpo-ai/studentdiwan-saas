import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';
import { isCentralAdmin } from '@/lib/roles';
import { DashboardLayout } from '../components/layout/DashboardLayout';
import { Card, CardContent, CardHeader } from '../components/ui/card';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Label } from '../components/ui/label';
import { Progress } from '../components/ui/progress';
import {
  Shield, CheckCircle2, Circle, ArrowRight, PartyPopper, Loader2, Rocket,
} from 'lucide-react';
import { toast } from 'sonner';
import { cn } from '@/lib/utils';
import { ONBOARDING_STEPS } from '@/lib/onboardingSteps';
import { useOnboardingProgress } from '@/hooks/useOnboardingProgress';
import { useSchoolProfile } from '@/hooks/useSchoolProfile';

const QuickStart: React.FC = () => {
  const { role } = useAuth();
  const navigate = useNavigate();
  const {
    loading, completed, completedCount, totalCount, percent,
    markManualComplete, unmarkManualComplete,
  } = useOnboardingProgress();
  const [activeId, setActiveId] = useState<string>(ONBOARDING_STEPS[0].id);

  if (!isCentralAdmin(role)) {
    return (
      <DashboardLayout>
        <div className="flex items-center justify-center h-[60vh]">
          <div className="text-center">
            <Shield className="h-12 w-12 text-destructive mx-auto mb-4" />
            <h2 className="text-2xl font-bold">Access Denied</h2>
            <p className="text-muted-foreground">Only administrators can access the setup guide.</p>
          </div>
        </div>
      </DashboardLayout>
    );
  }

  const activeStep = ONBOARDING_STEPS.find((s) => s.id === activeId) ?? ONBOARDING_STEPS[0];
  const activeIndex = ONBOARDING_STEPS.findIndex((s) => s.id === activeId);
  const allDone = !loading && completedCount === totalCount;

  const goToStep = (id: string) => setActiveId(id);
  const goNext = () => {
    const next = ONBOARDING_STEPS[activeIndex + 1];
    if (next) setActiveId(next.id);
  };
  const goPrev = () => {
    const prev = ONBOARDING_STEPS[activeIndex - 1];
    if (prev) setActiveId(prev.id);
  };

  return (
    <DashboardLayout>
      <div className="space-y-5">
        {/* Header */}
        <div className="flex items-center justify-between flex-wrap gap-3">
          <div className="flex items-center gap-3">
            <div className="w-11 h-11 rounded-xl bg-purple-100 flex items-center justify-center flex-shrink-0">
              <Rocket className="h-5 w-5 text-purple-600" />
            </div>
            <div>
              <h1 className="text-2xl font-bold text-slate-900">Quick Start Guide</h1>
              <p className="text-sm text-slate-400">
                Follow these steps to set up your school and start using Student Diwan effectively.
              </p>
            </div>
          </div>
          <div className="flex items-center gap-3 min-w-[220px]">
            <div className="flex-1">
              <Progress value={percent} className="h-2" />
            </div>
            <span className="text-sm font-bold text-slate-600 whitespace-nowrap">
              {completedCount}/{totalCount} steps
            </span>
          </div>
        </div>

        {allDone ? (
          <Card className="rounded-2xl border-emerald-200 bg-emerald-50/50">
            <CardContent className="py-12 text-center space-y-4">
              <PartyPopper className="h-14 w-14 text-emerald-600 mx-auto" />
              <h2 className="text-2xl font-bold text-emerald-800">Your school is ready!</h2>
              <p className="text-emerald-700 max-w-md mx-auto">
                All setup steps are complete. You're all set to start managing your school with Student Diwan.
              </p>
              <Button onClick={() => navigate('/')} className="gradient-primary border-none">
                Go to Dashboard <ArrowRight className="h-4 w-4 ml-2" />
              </Button>
            </CardContent>
          </Card>
        ) : (
          <div className="grid grid-cols-1 lg:grid-cols-[280px_1fr] gap-5">
            {/* Step list */}
            <Card className="rounded-2xl border-border/50 shadow-sm h-fit">
              <CardContent className="p-2">
                {ONBOARDING_STEPS.map((step, idx) => {
                  const done = !!completed[step.id];
                  const isActive = step.id === activeId;
                  return (
                    <button
                      key={step.id}
                      onClick={() => goToStep(step.id)}
                      className={cn(
                        'w-full text-left flex items-start gap-2.5 p-2.5 rounded-xl transition-colors',
                        isActive ? 'bg-purple-50 border border-purple-200' : 'hover:bg-slate-50 border border-transparent'
                      )}
                    >
                      {done ? (
                        <CheckCircle2 className="h-4.5 w-4.5 text-emerald-500 shrink-0 mt-0.5" />
                      ) : (
                        <Circle className="h-4.5 w-4.5 text-slate-300 shrink-0 mt-0.5" />
                      )}
                      <div className="min-w-0">
                        <p className={cn('text-xs font-bold truncate', isActive ? 'text-purple-700' : 'text-slate-700')}>
                          {idx + 1}. {step.title}
                        </p>
                      </div>
                    </button>
                  );
                })}
              </CardContent>
            </Card>

            {/* Active step panel */}
            <Card className="rounded-2xl border-border/50 shadow-sm">
              <CardHeader className="pb-3">
                <p className="text-xs font-bold text-purple-600 uppercase tracking-wider">
                  Step {activeIndex + 1} of {totalCount}
                </p>
                <h2 className="text-xl font-bold text-slate-900">{activeStep.title}</h2>
                <p className="text-sm text-slate-500">{activeStep.description}</p>
              </CardHeader>
              <CardContent className="space-y-5">
                {activeStep.id === 'school-profile' ? (
                  <SchoolProfileForm onSaved={() => { /* progress hook re-fetches on next visit */ }} />
                ) : (
                  <div className="flex items-center gap-3">
                    <Button onClick={() => navigate(activeStep.route)} className="gradient-primary border-none">
                      Start Step <ArrowRight className="h-4 w-4 ml-2" />
                    </Button>
                    {activeStep.completion === 'manual' && (
                      <Button
                        variant="outline"
                        onClick={() => (completed[activeStep.id] ? unmarkManualComplete(activeStep.id) : markManualComplete(activeStep.id))}
                      >
                        {completed[activeStep.id] ? 'Mark as Not Done' : 'Mark as Complete'}
                      </Button>
                    )}
                    {completed[activeStep.id] && (
                      <span className="text-xs font-bold text-emerald-600 flex items-center gap-1">
                        <CheckCircle2 className="h-3.5 w-3.5" /> Completed
                      </span>
                    )}
                  </div>
                )}

                {activeStep.tips.length > 0 && (
                  <div className="rounded-xl bg-slate-50 border border-slate-100 p-3 space-y-1">
                    <p className="text-[11px] font-bold text-slate-500 uppercase tracking-wider">Tip</p>
                    {activeStep.tips.map((tip) => (
                      <p key={tip} className="text-xs text-slate-500">{tip}</p>
                    ))}
                  </div>
                )}

                <div className="flex items-center justify-between pt-2 border-t border-slate-100">
                  <Button variant="ghost" size="sm" disabled={activeIndex === 0} onClick={goPrev}>
                    Previous
                  </Button>
                  <Button variant="ghost" size="sm" disabled={activeIndex === totalCount - 1} onClick={goNext}>
                    Next Step
                  </Button>
                </div>
              </CardContent>
            </Card>
          </div>
        )}
      </div>
    </DashboardLayout>
  );
};

function SchoolProfileForm({ onSaved }: { onSaved: () => void }) {
  const { profile, loading, saving, save } = useSchoolProfile();
  const [form, setForm] = useState(profile);
  const [dirty, setDirty] = useState(false);

  React.useEffect(() => {
    if (!loading) setForm(profile);
  }, [loading, profile]);

  const field = (key: keyof typeof form) => ({
    value: form[key],
    onChange: (e: React.ChangeEvent<HTMLInputElement>) => {
      setForm((prev) => ({ ...prev, [key]: e.target.value }));
      setDirty(true);
    },
  });

  const handleSave = async () => {
    await save(form);
    setDirty(false);
    toast.success('School profile saved');
    onSaved();
  };

  if (loading) {
    return <Loader2 className="h-5 w-5 animate-spin text-slate-400" />;
  }

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div className="space-y-1.5">
          <Label>School Name</Label>
          <Input placeholder="e.g. Bluewood International School" {...field('name')} />
        </div>
        <div className="space-y-1.5">
          <Label>Logo URL</Label>
          <Input placeholder="https://..." {...field('logoUrl')} />
        </div>
        <div className="space-y-1.5 sm:col-span-2">
          <Label>Address</Label>
          <Input placeholder="Street, City, Country" {...field('address')} />
        </div>
        <div className="space-y-1.5">
          <Label>Phone</Label>
          <Input placeholder="+974 ..." {...field('phone')} />
        </div>
        <div className="space-y-1.5">
          <Label>Email</Label>
          <Input placeholder="info@school.edu" {...field('email')} />
        </div>
        <div className="space-y-1.5">
          <Label>Time Zone</Label>
          <Input placeholder="e.g. GMT+03:00 Asia/Qatar" {...field('timezone')} />
        </div>
      </div>
      <Button onClick={handleSave} disabled={!dirty || saving} className="gradient-primary border-none">
        {saving ? <Loader2 className="h-4 w-4 mr-2 animate-spin" /> : null}
        Save & Continue
      </Button>
    </div>
  );
}

export default QuickStart;
