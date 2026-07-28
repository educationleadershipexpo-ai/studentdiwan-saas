import { useEffect, useState, useCallback } from 'react';
import {
  type SchoolProfile, EMPTY_SCHOOL_PROFILE,
  loadSchoolProfile, saveSchoolProfile, isSchoolProfileComplete,
  _schoolProfileListeners,
} from '@/lib/schoolProfile';

export interface UseSchoolProfileResult {
  profile: SchoolProfile;
  loading: boolean;
  saving: boolean;
  isComplete: boolean;
  save: (next: SchoolProfile) => Promise<void>;
}

export function useSchoolProfile(): UseSchoolProfileResult {
  const [profile, setProfile] = useState<SchoolProfile>(EMPTY_SCHOOL_PROFILE);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    let alive = true;
    loadSchoolProfile().then((p) => { if (alive) { setProfile(p); setLoading(false); } });
    const refresh = () => loadSchoolProfile().then((p) => { if (alive) setProfile(p); });
    _schoolProfileListeners.add(refresh);
    return () => { alive = false; _schoolProfileListeners.delete(refresh); };
  }, []);

  const save = useCallback(async (next: SchoolProfile) => {
    setSaving(true);
    try {
      await saveSchoolProfile(next);
      setProfile(next);
    } finally {
      setSaving(false);
    }
  }, []);

  return { profile, loading, saving, isComplete: isSchoolProfileComplete(profile), save };
}
