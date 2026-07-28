function hashName(name: string): number {
  let h = 0;
  for (let i = 0; i < name.length; i++) h = (h * 31 + name.charCodeAt(i)) >>> 0;
  return h;
}

export function getCustomAvatar(name: string, role?: string): string {
  const normName = name.toLowerCase().trim();
  const normRole = (role || "").toLowerCase().trim();
  
  // Try mapping by role first
  if (normRole.includes("principal") && !normRole.includes("vice")) {
    return "/avatars/staff/principal.png";
  }
  if (normRole.includes("vice_principal") || normRole.includes("vice principal")) {
    return "/avatars/staff/vice_principal.png";
  }
  if (normRole.includes("hod") || normRole.includes("head of department")) {
    return "/avatars/staff/hod.png";
  }
  if (normRole.includes("class_teacher") || normRole.includes("class teacher")) {
    return "/avatars/staff/class_teacher.png";
  }
  if (normRole.includes("subject_teacher") || normRole.includes("subject teacher") || normRole.includes("teacher")) {
    return "/avatars/staff/subject_teacher.png";
  }
  if (normRole.includes("counselor")) {
    return "/avatars/staff/counselor.png";
  }
  if (normRole.includes("librarian")) {
    return "/avatars/staff/librarian.png";
  }
  if (normRole.includes("sports_coach") || normRole.includes("sports coach") || normRole.includes("coach")) {
    return "/avatars/staff/sports_coach.png";
  }
  if (normRole.includes("system_admin") || normRole.includes("system admin") || normRole.includes("admin") || normRole.includes("coordinator")) {
    return "/avatars/staff/system_admin.png";
  }
  if (normRole.includes("accountant")) {
    return "/avatars/staff/accountant.png";
  }
  if (normRole.includes("office_staff") || normRole.includes("office staff") || normRole.includes("staff")) {
    return "/avatars/staff/office_staff.png";
  }
  if (normRole.includes("school_nurse") || normRole.includes("school nurse") || normRole.includes("nurse")) {
    return "/avatars/staff/school_nurse.png";
  }
  if (normRole.includes("transport_incharge") || normRole.includes("transport manager")) {
    return "/avatars/staff/transport_incharge.png";
  }
  if (normRole.includes("driver")) {
    return "/avatars/staff/driver.png";
  }
  if (normRole.includes("security_guard") || normRole.includes("security guard") || normRole.includes("security")) {
    return "/avatars/staff/security_guard.png";
  }

  // Guess from name if no explicit role is matched
  if (normName.includes("principal") && !normName.includes("vice")) return "/avatars/staff/principal.png";
  if (normName.includes("vice principal")) return "/avatars/staff/vice_principal.png";
  if (normName.includes("admin")) return "/avatars/staff/system_admin.png";
  if (normName.includes("nurse")) return "/avatars/staff/school_nurse.png";
  if (normName.includes("driver")) return "/avatars/staff/driver.png";
  if (normName.includes("security")) return "/avatars/staff/security_guard.png";
  if (normName.includes("counselor")) return "/avatars/staff/counselor.png";
  if (normName.includes("librarian")) return "/avatars/staff/librarian.png";
  if (normName.includes("coach")) return "/avatars/staff/sports_coach.png";
  if (normName.includes("accountant")) return "/avatars/staff/accountant.png";
  if (normName.includes("hod")) return "/avatars/staff/hod.png";
  if (normName.includes("staff")) return "/avatars/staff/office_staff.png";

  if (
    normName.includes("teacher") || 
    normName.startsWith("mr.") || 
    normName.startsWith("mrs.") || 
    normName.startsWith("ms.") || 
    normName.startsWith("dr.")
  ) {
    const staffAvatars = [
      "class_teacher", "subject_teacher", "counselor", "librarian", 
      "sports_coach", "system_admin", "accountant", "office_staff"
    ];
    const picked = staffAvatars[hashName(name) % staffAvatars.length];
    return `/avatars/staff/${picked}.png`;
  }
  
  // Default to student avatar based on hash
  const studentIndex = (hashName(name) % 7) + 1;
  return `/avatars/students/student_${studentIndex}.png`;
}
