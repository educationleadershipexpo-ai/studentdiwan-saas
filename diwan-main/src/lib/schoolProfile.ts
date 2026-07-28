import { smartDb } from '@/lib/localDb';

// Single global row holding the school's identity — name, logo, address,
// contact details, timezone. Lives in the same 'school_config' table
// useCurriculum.ts already uses (different row id), so no new table is
// introduced. This is what the Quick Start wizard's "School Profile" step
// reads/writes; other parts of the app (PDF headers, invoices) currently
// hardcode "Bluewood School" and can migrate to read this later.
const ENTITY = 'school_config';
const ROW_ID = 'profile';

export interface SchoolProfile {
  name: string;
  logoUrl: string;
  address: string;
  phone: string;
  email: string;
  timezone: string;
}

export const EMPTY_SCHOOL_PROFILE: SchoolProfile = {
  name: '', logoUrl: '', address: '', phone: '', email: '', timezone: '',
};

// A profile counts as "complete" for onboarding purposes once the two fields
// every school genuinely needs (name + address) are filled in — logo/phone/
// email/timezone are nice-to-have, not blocking.
export function isSchoolProfileComplete(p: SchoolProfile): boolean {
  return p.name.trim().length > 0 && p.address.trim().length > 0;
}

let _cached: SchoolProfile | null = null;
export const _schoolProfileListeners = new Set<() => void>();
function _notify() { _schoolProfileListeners.forEach(fn => fn()); }

export async function loadSchoolProfile(): Promise<SchoolProfile> {
  if (_cached) return _cached;
  try {
    const row = await smartDb.getOne(ENTITY, ROW_ID) as (Partial<SchoolProfile> & { id: string }) | null;
    _cached = row ? { ...EMPTY_SCHOOL_PROFILE, ...row } : { ...EMPTY_SCHOOL_PROFILE };
  } catch {
    _cached = { ...EMPTY_SCHOOL_PROFILE };
  }
  return _cached;
}

export async function saveSchoolProfile(profile: SchoolProfile): Promise<void> {
  _cached = profile;
  _notify();
  const payload = { id: ROW_ID, ...profile };
  try {
    await smartDb.update(ENTITY, ROW_ID, payload);
  } catch {
    try {
      await smartDb.create(ENTITY, payload, ROW_ID);
    } catch { /* table auto-created on first CRUD call */ }
  }
}
