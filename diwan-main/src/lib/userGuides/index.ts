export { superAdminGuide } from './guides/superAdmin';
export { schoolAdminGuide } from './guides/schoolAdmin';
export { teacherGuide } from './guides/teacher';
export { parentGuide } from './guides/parent';
export { studentGuide } from './guides/student';
export { accountantGuide } from './guides/accountant';
export { hrGuide } from './guides/hr';
export { transportGuide } from './guides/transport';
export { libraryGuide } from './guides/library';
export { mobileAppGuide } from './guides/mobileApp';

import { superAdminGuide } from './guides/superAdmin';
import { schoolAdminGuide } from './guides/schoolAdmin';
import { teacherGuide } from './guides/teacher';
import { parentGuide } from './guides/parent';
import { studentGuide } from './guides/student';
import { accountantGuide } from './guides/accountant';
import { hrGuide } from './guides/hr';
import { transportGuide } from './guides/transport';
import { libraryGuide } from './guides/library';
import { mobileAppGuide } from './guides/mobileApp';
import type { UserGuide } from './types';

export const ALL_GUIDES: UserGuide[] = [
  superAdminGuide,
  schoolAdminGuide,
  teacherGuide,
  parentGuide,
  studentGuide,
  accountantGuide,
  hrGuide,
  transportGuide,
  libraryGuide,
  mobileAppGuide,
];

export function getGuide(id: string): UserGuide | undefined {
  return ALL_GUIDES.find((g) => g.id === id);
}
