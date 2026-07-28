import { useCallback, useEffect, useState } from 'react';
import { smartDb } from '@/lib/localDb';
import { staffRepository } from '@/repositories/StaffRepository';
import { userRepository } from '@/repositories/UserRepository';
import { ONBOARDING_STEPS } from '@/lib/onboardingSteps';
import { loadSchoolProfile, isSchoolProfileComplete } from '@/lib/schoolProfile';

const ENTITY = 'school_config';
const ROW_ID = 'onboarding';

interface OnboardingRow {
  id: string;
  manualComplete?: string[];
}

async function loadManualComplete(): Promise<Set<string>> {
  try {
    const row = await smartDb.getOne(ENTITY, ROW_ID) as OnboardingRow | null;
    return new Set(row?.manualComplete ?? []);
  } catch {
    return new Set();
  }
}

async function saveManualComplete(ids: Set<string>): Promise<void> {
  const payload: OnboardingRow = { id: ROW_ID, manualComplete: [...ids] };
  try {
    await smartDb.update(ENTITY, ROW_ID, payload);
  } catch {
    try { await smartDb.create(ENTITY, payload, ROW_ID); } catch { /* ignore */ }
  }
}

// Best-effort count check — any entity name mismatch or fetch failure just
// means that step won't auto-complete (falls back to manual), never a crash.
async function hasAny(entity: string): Promise<boolean> {
  try {
    const rows = await smartDb.getAll(entity, undefined);
    return Array.isArray(rows) && rows.length > 0;
  } catch {
    return false;
  }
}

export interface UseOnboardingProgressResult {
  loading: boolean;
  completed: Record<string, boolean>;
  completedCount: number;
  totalCount: number;
  percent: number;
  markManualComplete: (stepId: string) => Promise<void>;
  unmarkManualComplete: (stepId: string) => Promise<void>;
  refresh: () => Promise<void>;
}

export function useOnboardingProgress(): UseOnboardingProgressResult {
  const [loading, setLoading] = useState(true);
  const [completed, setCompleted] = useState<Record<string, boolean>>({});

  const refresh = useCallback(async () => {
    const [profile, manual, hasAcademicYear, hasClasses, hasSubjects, hasStaff, hasStudents, hasFees, hasTimetable, hasAttendance, users] =
      await Promise.all([
        loadSchoolProfile(),
        loadManualComplete(),
        hasAny('AcademicYear'),
        hasAny('Class'),
        hasAny('TeacherAssignment'),
        staffRepository.getAll().catch(() => []),
        hasAny('students'),
        hasAny('FeeStructure'),
        hasAny('TimetableSlot'),
        hasAny('attendance'),
        userRepository.getAll().catch(() => []),
      ]);

    setCompleted({
      'school-profile': isSchoolProfileComplete(profile),
      'academic-year': hasAcademicYear,
      'classes': hasClasses,
      'subjects': hasSubjects,
      'teachers': hasStaff.length > 0,
      'students': hasStudents,
      'fees': hasFees,
      'timetable': hasTimetable,
      'attendance': hasAttendance,
      'users': users.length > 1, // more than just the current admin account
      'test-system': manual.has('test-system'),
    });
    setLoading(false);
  }, []);

  useEffect(() => { refresh(); }, [refresh]);

  const markManualComplete = useCallback(async (stepId: string) => {
    const current = await loadManualComplete();
    const next = new Set(current).add(stepId);
    await saveManualComplete(next);
    setCompleted((prev) => ({ ...prev, [stepId]: true }));
  }, []);

  const unmarkManualComplete = useCallback(async (stepId: string) => {
    const current = await loadManualComplete();
    const next = new Set(current);
    next.delete(stepId);
    await saveManualComplete(next);
    setCompleted((prev) => ({ ...prev, [stepId]: false }));
  }, []);

  const completedCount = ONBOARDING_STEPS.filter((s) => completed[s.id]).length;
  const totalCount = ONBOARDING_STEPS.length;

  return {
    loading,
    completed,
    completedCount,
    totalCount,
    percent: totalCount ? Math.round((completedCount / totalCount) * 100) : 0,
    markManualComplete,
    unmarkManualComplete,
    refresh,
  };
}
