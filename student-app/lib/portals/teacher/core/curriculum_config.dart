// Central registry of all supported school curricula — a faithful Dart port of
// the desktop `src/lib/curriculumConfig.ts`. One curriculum is "active" at a
// time (saved in the `school_config` MySQL table, row `active_curriculum`). The
// gradebook engine reads the active curriculum's gradebook band for a student's
// grade to know the assessment categories and their weights.
//
// This is real configuration, not seed data: it mirrors, category-for-category
// and weight-for-weight, the exact bands the desktop gradebook computes against,
// so the mobile weighted-composite result equals the desktop's.

class GradebookCategory {
  final String name;
  final int? count; // null = continuous / untracked
  final int marks; // marks allocated per period (band totals to 100)
  final bool isExam;
  const GradebookCategory(this.name, this.count, this.marks, this.isExam);
}

class GradebookBand {
  final String label; // e.g. "Primary (Grade 1 – 6)"
  final List<String> grades;
  final List<GradebookCategory> categories;
  const GradebookBand(this.label, this.grades, this.categories);
}

class SubjectBand {
  final String label;
  final List<String> grades;
  final List<String> subjects;
  const SubjectBand(this.label, this.grades, this.subjects);
}

class AnnualStructure {
  final int periods; // 2 or 3
  final String periodLabel; // "Term" or "Semester"
  final List<int> weights; // must sum to 100
  const AnnualStructure(this.periods, this.periodLabel, this.weights);
}

class CurriculumConfig {
  final String id;
  final String name;
  final String shortName;
  final String accentColor; // hex for UI badges/highlights
  final List<String> grades;
  final AnnualStructure annualStructure;
  final List<GradebookBand> gradebookBands;
  final List<SubjectBand> subjectBands;
  const CurriculumConfig({
    required this.id,
    required this.name,
    required this.shortName,
    required this.accentColor,
    required this.grades,
    required this.annualStructure,
    required this.gradebookBands,
    required this.subjectBands,
  });
}

// ── Qatar National Curriculum ────────────────────────────────────────────────
const _qatar = CurriculumConfig(
  id: 'qatar',
  name: 'Qatar National Curriculum',
  shortName: 'Qatar',
  accentColor: '#8B0000',
  grades: ['Pre-KG', 'KG1', 'KG2', 'Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10', 'Grade 11', 'Grade 12'],
  annualStructure: AnnualStructure(3, 'Term', [30, 30, 40]),
  gradebookBands: [
    GradebookBand('Early Years (Pre-KG – KG2)', ['Pre-KG', 'KG1', 'KG2'], [
      GradebookCategory('Activities', 10, 40, false),
      GradebookCategory('Observation Records', 4, 20, false),
      GradebookCategory('Projects', 1, 10, false),
      GradebookCategory('Participation', null, 30, false),
    ]),
    GradebookBand('Primary (Grade 1 – 6)', ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6'], [
      GradebookCategory('Assignments', 5, 15, false),
      GradebookCategory('Quizzes', 3, 10, false),
      GradebookCategory('Projects', 1, 10, false),
      GradebookCategory('Assessments', 3, 20, false),
      GradebookCategory('Participation', null, 5, false),
      GradebookCategory('Term Exam', 1, 40, true),
    ]),
    GradebookBand('Middle School (Grade 7 – 9)', ['Grade 7', 'Grade 8', 'Grade 9'], [
      GradebookCategory('Assignments', 5, 15, false),
      GradebookCategory('Quizzes', 4, 10, false),
      GradebookCategory('Projects', 2, 10, false),
      GradebookCategory('Assessments', 4, 20, false),
      GradebookCategory('Participation', null, 5, false),
      GradebookCategory('Term Exam', 1, 40, true),
    ]),
    GradebookBand('Secondary (Grade 10 – 12)', ['Grade 10', 'Grade 11', 'Grade 12'], [
      GradebookCategory('Assignments', 4, 10, false),
      GradebookCategory('Projects', 2, 10, false),
      GradebookCategory('Assessments', 3, 20, false),
      GradebookCategory('Mock Exam', 1, 10, true),
      GradebookCategory('Final Exam', 1, 50, true),
    ]),
  ],
  subjectBands: [
    SubjectBand('KG (Pre-KG – KG2)', ['Pre-KG', 'KG1', 'KG2'], ['Arabic', 'English', 'Mathematics', 'Science Discovery', 'Islamic Studies', 'Art', 'Physical Education']),
    SubjectBand('Grade 1 – 6', ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6'], ['Arabic', 'English', 'Mathematics', 'Science', 'Islamic Studies', 'Social Studies', 'ICT', 'Art', 'Physical Education']),
    SubjectBand('Grade 7 – 9', ['Grade 7', 'Grade 8', 'Grade 9'], ['Arabic', 'English', 'Mathematics', 'Science', 'Islamic Studies', 'Social Studies', 'ICT', 'Qatar History', 'Art', 'Physical Education']),
    SubjectBand('Grade 10 – 12', ['Grade 10', 'Grade 11', 'Grade 12'], ['Arabic', 'English', 'Mathematics', 'Physics', 'Chemistry', 'Biology', 'ICT', 'Islamic Studies', 'Qatar History', 'Physical Education']),
  ],
);

// ── British / Cambridge ──────────────────────────────────────────────────────
const _british = CurriculumConfig(
  id: 'british',
  name: 'British / Cambridge',
  shortName: 'British',
  accentColor: '#003087',
  grades: ['Pre-Nursery', 'Nursery', 'Reception', 'Year 1', 'Year 2', 'Year 3', 'Year 4', 'Year 5', 'Year 6', 'Year 7', 'Year 8', 'Year 9', 'Year 10', 'Year 11', 'Year 12', 'Year 13'],
  annualStructure: AnnualStructure(3, 'Term', [30, 30, 40]),
  gradebookBands: [
    GradebookBand('Early Years (Pre-Nursery – Reception)', ['Pre-Nursery', 'Nursery', 'Reception'], [
      GradebookCategory('Activities', 10, 40, false),
      GradebookCategory('Observation Assessments', 4, 20, false),
      GradebookCategory('Worksheets', 6, 30, false),
      GradebookCategory('Project', 1, 10, false),
    ]),
    GradebookBand('All Years (Year 1 – 13)', ['Year 1', 'Year 2', 'Year 3', 'Year 4', 'Year 5', 'Year 6', 'Year 7', 'Year 8', 'Year 9', 'Year 10', 'Year 11', 'Year 12', 'Year 13'], [
      GradebookCategory('Assignments', 4, 15, false),
      GradebookCategory('Quizzes', 3, 10, false),
      GradebookCategory('Class Tests / Assessments', 3, 20, false),
      GradebookCategory('Projects', 1, 15, false),
      GradebookCategory('Term Exam', 1, 40, true),
    ]),
  ],
  subjectBands: [
    SubjectBand('Early Years (Pre-Nursery – Reception)', ['Pre-Nursery', 'Nursery', 'Reception'], ['English', 'Mathematics', 'Understanding the World', 'Personal Development', 'Creative Arts', 'Physical Development']),
    SubjectBand('Cambridge Primary (Year 1 – 6)', ['Year 1', 'Year 2', 'Year 3', 'Year 4', 'Year 5', 'Year 6'], ['English', 'Mathematics', 'Science', 'Digital Literacy', 'Computing', 'Global Perspectives', 'Art & Design', 'Music', 'Physical Education']),
    SubjectBand('Lower Secondary (Year 7 – 9)', ['Year 7', 'Year 8', 'Year 9'], ['English', 'Mathematics', 'Science', 'Global Perspectives', 'ICT', 'Geography', 'History', 'Art', 'Music', 'Physical Education', 'Foreign Language']),
    SubjectBand('IGCSE (Year 10 – 11)', ['Year 10', 'Year 11'], ['English', 'Mathematics', 'Biology', 'Chemistry', 'Physics', 'ICT', 'Business Studies', 'Accounting', 'Economics', 'Geography', 'History', 'Art & Design', 'Computer Science', 'French', 'Arabic']),
    SubjectBand('AS / A Level (Year 12 – 13)', ['Year 12', 'Year 13'], ['Mathematics', 'Physics', 'Chemistry', 'Biology', 'Accounting', 'Economics', 'Business', 'History', 'Geography', 'Psychology', 'Sociology']),
  ],
);

// ── American ─────────────────────────────────────────────────────────────────
const _american = CurriculumConfig(
  id: 'american',
  name: 'American Curriculum',
  shortName: 'American',
  accentColor: '#B22234',
  grades: ['Pre-K', 'Kindergarten', 'Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10', 'Grade 11', 'Grade 12'],
  annualStructure: AnnualStructure(2, 'Semester', [50, 50]),
  gradebookBands: [
    GradebookBand('Early Years (Pre-K – Kindergarten)', ['Pre-K', 'Kindergarten'], [
      GradebookCategory('Activities', 10, 40, false),
      GradebookCategory('Observation Assessments', 4, 20, false),
      GradebookCategory('Worksheets', 6, 30, false),
      GradebookCategory('Project', 1, 10, false),
    ]),
    GradebookBand('All Grades (Grade 1 – 12)', ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10', 'Grade 11', 'Grade 12'], [
      GradebookCategory('Assignments', 6, 20, false),
      GradebookCategory('Quizzes', 5, 15, false),
      GradebookCategory('Projects', 2, 15, false),
      GradebookCategory('Mid-Term Exam', 1, 20, true),
      GradebookCategory('Final Exam', 1, 30, true),
    ]),
  ],
  subjectBands: [
    SubjectBand('Pre-K – Grade 5', ['Pre-K', 'Kindergarten', 'Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5'], ['English Language Arts', 'Mathematics', 'Science', 'Social Studies', 'Art', 'Music', 'Physical Education', 'Technology']),
    SubjectBand('Grade 6 – 8', ['Grade 6', 'Grade 7', 'Grade 8'], ['English', 'Mathematics', 'Science', 'Social Studies', 'Computer Science', 'Physical Education', 'Art']),
    SubjectBand('Grade 9 – 12', ['Grade 9', 'Grade 10', 'Grade 11', 'Grade 12'], ['English', 'Algebra / Advanced Mathematics', 'Biology', 'Chemistry', 'Physics', 'World History', 'US History', 'Government', 'Economics', 'Computer Science', 'Electives']),
  ],
);

// ── IB ───────────────────────────────────────────────────────────────────────
const _ib = CurriculumConfig(
  id: 'ib',
  name: 'IB Curriculum',
  shortName: 'IB',
  accentColor: '#0082C8',
  grades: ['Pre-K', 'KG1', 'KG2', 'Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10', 'Grade 11', 'Grade 12'],
  annualStructure: AnnualStructure(2, 'Semester', [50, 50]),
  gradebookBands: [
    GradebookBand('Early Years (Pre-K – KG2)', ['Pre-K', 'KG1', 'KG2'], [
      GradebookCategory('Activities', 10, 40, false),
      GradebookCategory('Observation Assessments', 4, 20, false),
      GradebookCategory('Worksheets', 6, 30, false),
      GradebookCategory('Project', 1, 10, false),
    ]),
    GradebookBand('All Grades (Grade 1 – 12)', ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10', 'Grade 11', 'Grade 12'], [
      GradebookCategory('Assignments', 5, 15, false),
      GradebookCategory('Projects', 2, 20, false),
      GradebookCategory('Presentations', 3, 10, false),
      GradebookCategory('Assessments', 3, 15, false),
      GradebookCategory('Internal Assessment (IA)', 1, 10, false),
      GradebookCategory('Semester Exam', 1, 30, true),
    ]),
  ],
  subjectBands: [
    SubjectBand('PYP (Pre-K – Grade 5)', ['Pre-K', 'KG1', 'KG2', 'Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5'], ['Language', 'Mathematics', 'Science', 'Social Studies', 'Arts', 'Physical Education']),
    SubjectBand('MYP (Grade 6 – 10)', ['Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10'], ['Language & Literature', 'Language Acquisition', 'Mathematics', 'Sciences', 'Individuals & Societies', 'Arts', 'Design', 'Physical Education']),
    SubjectBand('DP (Grade 11 – 12)', ['Grade 11', 'Grade 12'], ['Studies in Language & Literature', 'Language Acquisition', 'Mathematics', 'Sciences', 'Individuals & Societies', 'Arts', 'Theory of Knowledge', 'Extended Essay', 'CAS']),
  ],
);

// ── CBSE ─────────────────────────────────────────────────────────────────────
const _cbse = CurriculumConfig(
  id: 'cbse',
  name: 'CBSE Curriculum',
  shortName: 'CBSE',
  accentColor: '#FF6B35',
  grades: ['Pre-KG', 'LKG', 'UKG', 'Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10', 'Grade 11', 'Grade 12'],
  annualStructure: AnnualStructure(2, 'Term', [50, 50]),
  gradebookBands: [
    GradebookBand('Early Years (Pre-KG – UKG)', ['Pre-KG', 'LKG', 'UKG'], [
      GradebookCategory('Activities', 10, 40, false),
      GradebookCategory('Observation Assessments', 4, 20, false),
      GradebookCategory('Worksheets', 6, 30, false),
      GradebookCategory('Project', 1, 10, false),
    ]),
    GradebookBand('Primary & Middle (Grade 1 – 8)', ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6', 'Grade 7', 'Grade 8'], [
      GradebookCategory('Assignments', 3, 10, false),
      GradebookCategory('Periodic Tests', 3, 20, false),
      GradebookCategory('Projects', 1, 10, false),
      GradebookCategory('Subject Enrichment', 1, 10, false),
      GradebookCategory('Term Exam', 1, 50, true),
    ]),
    GradebookBand('Secondary (Grade 9 – 10)', ['Grade 9', 'Grade 10'], [
      GradebookCategory('Periodic Tests', null, 10, false),
      GradebookCategory('Notebook Submission', null, 5, false),
      GradebookCategory('Subject Enrichment', null, 5, false),
      GradebookCategory('Annual Exam', 1, 80, true),
    ]),
    GradebookBand('Senior Secondary (Grade 11 – 12)', ['Grade 11', 'Grade 12'], [
      GradebookCategory('Assignments', 3, 10, false),
      GradebookCategory('Unit Tests', 2, 10, false),
      GradebookCategory('Practicals / Projects', 2, 20, false),
      GradebookCategory('Mid-Term Exam', 1, 20, true),
      GradebookCategory('Final Exam', 1, 40, true),
    ]),
  ],
  subjectBands: [
    SubjectBand('Pre-KG – UKG', ['Pre-KG', 'LKG', 'UKG'], ['English', 'Hindi', 'Mathematics', 'EVS', 'Art', 'Physical Education']),
    SubjectBand('Grade 1 – 5', ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5'], ['English', 'Hindi', 'Mathematics', 'EVS', 'General Knowledge', 'Computer Science', 'Art', 'Physical Education']),
    SubjectBand('Grade 6 – 8', ['Grade 6', 'Grade 7', 'Grade 8'], ['English', 'Hindi', 'Mathematics', 'Science', 'Social Science', 'Third Language', 'Computer Science', 'Art', 'Physical Education']),
    SubjectBand('Grade 9 – 10', ['Grade 9', 'Grade 10'], ['English', 'Mathematics', 'Science', 'Social Science', 'Second Language', 'Information Technology / AI', 'Physical Education']),
    SubjectBand('Grade 11 – 12 (Science)', ['Grade 11', 'Grade 12'], ['English', 'Physics', 'Chemistry', 'Mathematics', 'Biology / Computer Science', 'Physical Education']),
  ],
);

// ── Sri Lankan ───────────────────────────────────────────────────────────────
const _srilankan = CurriculumConfig(
  id: 'srilankan',
  name: 'Sri Lankan Curriculum',
  shortName: 'Sri Lankan',
  accentColor: '#8D153A',
  grades: ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10', 'Grade 11', 'Grade 12', 'Grade 13'],
  annualStructure: AnnualStructure(3, 'Term', [30, 30, 40]),
  gradebookBands: [
    GradebookBand('Primary (Grade 1 – 5)', ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5'], [
      GradebookCategory('Assignments', 3, 15, false),
      GradebookCategory('Class Tests', 3, 25, false),
      GradebookCategory('Project', 1, 10, false),
      GradebookCategory('Term Exam', 1, 50, true),
    ]),
    GradebookBand('Secondary (Grade 6 – 11)', ['Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10', 'Grade 11'], [
      GradebookCategory('Assignments', 4, 15, false),
      GradebookCategory('Class Tests', 4, 25, false),
      GradebookCategory('Project', 1, 10, false),
      GradebookCategory('Term Exam', 1, 50, true),
    ]),
    GradebookBand('Collegiate (Grade 12 – 13)', ['Grade 12', 'Grade 13'], [
      GradebookCategory('Assignments', 3, 10, false),
      GradebookCategory('Unit Tests', 3, 20, false),
      GradebookCategory('Project', 1, 10, false),
      GradebookCategory('Term Exam', 1, 60, true),
    ]),
  ],
  subjectBands: [
    SubjectBand('Grade 1 – 5', ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5'], ['Sinhala / Tamil', 'English', 'Mathematics', 'Environmental Studies', 'Religion', 'Aesthetics']),
    SubjectBand('Grade 6 – 11', ['Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10', 'Grade 11'], ['First Language', 'English', 'Mathematics', 'Science', 'History', 'Geography', 'ICT', 'Health & Physical Education', 'Religion']),
    SubjectBand('Grade 12 – 13', ['Grade 12', 'Grade 13'], ['Science Stream', 'Commerce Stream', 'Arts Stream', 'Technology Stream']),
  ],
);

// ── Pakistani ────────────────────────────────────────────────────────────────
const _pakistani = CurriculumConfig(
  id: 'pakistani',
  name: 'Pakistani Curriculum',
  shortName: 'Pakistani',
  accentColor: '#01411C',
  grades: ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10', 'Grade 11', 'Grade 12'],
  annualStructure: AnnualStructure(2, 'Term', [50, 50]),
  gradebookBands: [
    GradebookBand('Primary (Grade 1 – 5)', ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5'], [
      GradebookCategory('Assignments', 3, 10, false),
      GradebookCategory('Unit Tests', 2, 20, false),
      GradebookCategory('Project', 1, 10, false),
      GradebookCategory('Term Exam', 1, 60, true),
    ]),
    GradebookBand('Middle & Secondary (Grade 6 – 10)', ['Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10'], [
      GradebookCategory('Assignments', 4, 10, false),
      GradebookCategory('Unit Tests', 3, 20, false),
      GradebookCategory('Project', 1, 10, false),
      GradebookCategory('Mid-Term', 1, 20, true),
      GradebookCategory('Final Exam', 1, 40, true),
    ]),
    GradebookBand('Higher Secondary (Grade 11 – 12)', ['Grade 11', 'Grade 12'], [
      GradebookCategory('Assignments', 3, 10, false),
      GradebookCategory('Unit Tests', 2, 10, false),
      GradebookCategory('Practicals', 2, 20, false),
      GradebookCategory('Mid-Term', 1, 20, true),
      GradebookCategory('Final Exam', 1, 40, true),
    ]),
  ],
  subjectBands: [
    SubjectBand('Grade 1 – 8', ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6', 'Grade 7', 'Grade 8'], ['English', 'Urdu', 'Mathematics', 'Science', 'Islamiat', 'Social Studies', 'Computer Science', 'Art']),
    SubjectBand('Grade 9 – 12', ['Grade 9', 'Grade 10', 'Grade 11', 'Grade 12'], ['English', 'Urdu', 'Mathematics', 'Physics', 'Chemistry', 'Biology', 'Pakistan Studies', 'Islamiat', 'Computer Science']),
  ],
);

// ── Lebanese ─────────────────────────────────────────────────────────────────
const _lebanese = CurriculumConfig(
  id: 'lebanese',
  name: 'Lebanese Curriculum',
  shortName: 'Lebanese',
  accentColor: '#C8102E',
  grades: ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10', 'Grade 11', 'Grade 12'],
  annualStructure: AnnualStructure(2, 'Semester', [50, 50]),
  gradebookBands: [
    GradebookBand('Primary (Grade 1 – 6)', ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6'], [
      GradebookCategory('Assignments', 4, 20, false),
      GradebookCategory('Quizzes', 3, 20, false),
      GradebookCategory('Project', 1, 10, false),
      GradebookCategory('Semester Exam', 1, 50, true),
    ]),
    GradebookBand('Intermediate (Grade 7 – 9)', ['Grade 7', 'Grade 8', 'Grade 9'], [
      GradebookCategory('Assignments', 4, 15, false),
      GradebookCategory('Quizzes', 4, 20, false),
      GradebookCategory('Project', 1, 15, false),
      GradebookCategory('Semester Exam', 1, 50, true),
    ]),
    GradebookBand('Secondary (Grade 10 – 12)', ['Grade 10', 'Grade 11', 'Grade 12'], [
      GradebookCategory('Assignments', 3, 10, false),
      GradebookCategory('Assessments', 3, 20, false),
      GradebookCategory('Project', 1, 10, false),
      GradebookCategory('Semester Exam', 1, 60, true),
    ]),
  ],
  subjectBands: [
    SubjectBand('Primary (Grade 1 – 6)', ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6'], ['Arabic', 'English', 'Mathematics', 'Science', 'Islamic Studies', 'Social Studies', 'ICT', 'Art', 'Physical Education']),
    SubjectBand('Intermediate (Grade 7 – 9)', ['Grade 7', 'Grade 8', 'Grade 9'], ['Arabic', 'English', 'Mathematics', 'Science', 'Islamic Studies', 'Social Studies', 'ICT', 'Art', 'Physical Education']),
    SubjectBand('Secondary (Grade 10 – 12)', ['Grade 10', 'Grade 11', 'Grade 12'], ['Arabic', 'English', 'Mathematics', 'Physics', 'Chemistry', 'Biology', 'Islamic Studies', 'ICT', 'Physical Education']),
  ],
);

// ── Egyptian ─────────────────────────────────────────────────────────────────
const _egyptian = CurriculumConfig(
  id: 'egyptian',
  name: 'Egyptian Curriculum',
  shortName: 'Egyptian',
  accentColor: '#C09300',
  grades: ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10', 'Grade 11', 'Grade 12'],
  annualStructure: AnnualStructure(2, 'Semester', [50, 50]),
  gradebookBands: [
    GradebookBand('Primary (Grade 1 – 6)', ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6'], [
      GradebookCategory('Assignments', 4, 20, false),
      GradebookCategory('Quizzes', 3, 15, false),
      GradebookCategory('Project', 1, 15, false),
      GradebookCategory('Semester Exam', 1, 50, true),
    ]),
    GradebookBand('Preparatory (Grade 7 – 9)', ['Grade 7', 'Grade 8', 'Grade 9'], [
      GradebookCategory('Assignments', 4, 15, false),
      GradebookCategory('Assessments', 3, 20, false),
      GradebookCategory('Project', 1, 15, false),
      GradebookCategory('Semester Exam', 1, 50, true),
    ]),
    GradebookBand('Secondary (Grade 10 – 12)', ['Grade 10', 'Grade 11', 'Grade 12'], [
      GradebookCategory('Assignments', 3, 10, false),
      GradebookCategory('Assessments', 3, 20, false),
      GradebookCategory('Project', 1, 10, false),
      GradebookCategory('Mid-Term', 1, 20, true),
      GradebookCategory('Final Exam', 1, 40, true),
    ]),
  ],
  subjectBands: [
    SubjectBand('Primary (Grade 1 – 6)', ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6'], ['Arabic', 'English', 'Mathematics', 'Science', 'Islamic Studies', 'Social Studies', 'ICT', 'Art', 'Physical Education']),
    SubjectBand('Preparatory (Grade 7 – 9)', ['Grade 7', 'Grade 8', 'Grade 9'], ['Arabic', 'English', 'Mathematics', 'Science', 'Islamic Studies', 'Social Studies', 'ICT', 'Art', 'Physical Education']),
    SubjectBand('Secondary (Grade 10 – 12)', ['Grade 10', 'Grade 11', 'Grade 12'], ['Arabic', 'English', 'Mathematics', 'Physics', 'Chemistry', 'Biology', 'Islamic Studies', 'ICT', 'Physical Education']),
  ],
);

// ── Palestinian ──────────────────────────────────────────────────────────────
const _palestinian = CurriculumConfig(
  id: 'palestinian',
  name: 'Palestinian Curriculum',
  shortName: 'Palestinian',
  accentColor: '#007A3D',
  grades: ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10', 'Grade 11', 'Grade 12'],
  annualStructure: AnnualStructure(2, 'Semester', [50, 50]),
  gradebookBands: [
    GradebookBand('Lower Primary (Grade 1 – 4)', ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4'], [
      GradebookCategory('Assignments', 4, 20, false),
      GradebookCategory('Quizzes', 3, 20, false),
      GradebookCategory('Project', 1, 10, false),
      GradebookCategory('Semester Exam', 1, 50, true),
    ]),
    GradebookBand('Basic Education (Grade 5 – 10)', ['Grade 5', 'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10'], [
      GradebookCategory('Assignments', 4, 15, false),
      GradebookCategory('Assessments', 3, 20, false),
      GradebookCategory('Project', 1, 15, false),
      GradebookCategory('Semester Exam', 1, 50, true),
    ]),
    GradebookBand('Secondary / Tawjihi (Grade 11 – 12)', ['Grade 11', 'Grade 12'], [
      GradebookCategory('Assignments', 3, 10, false),
      GradebookCategory('Assessments', 3, 20, false),
      GradebookCategory('Project', 1, 10, false),
      GradebookCategory('Mid-Term', 1, 20, true),
      GradebookCategory('Final Exam', 1, 40, true),
    ]),
  ],
  subjectBands: [
    SubjectBand('Lower Primary (Grade 1 – 4)', ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4'], ['Arabic', 'English', 'Mathematics', 'Science', 'Islamic Studies', 'Social Studies', 'Art', 'Physical Education']),
    SubjectBand('Basic Education (Grade 5 – 10)', ['Grade 5', 'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10'], ['Arabic', 'English', 'Mathematics', 'Science', 'Islamic Studies', 'Social Studies', 'ICT', 'Art', 'Physical Education']),
    SubjectBand('Secondary / Tawjihi (Grade 11 – 12)', ['Grade 11', 'Grade 12'], ['Arabic', 'English', 'Mathematics', 'Physics', 'Chemistry', 'Biology', 'Islamic Studies', 'ICT', 'Physical Education']),
  ],
);

// ── Sudanese ─────────────────────────────────────────────────────────────────
const _sudanese = CurriculumConfig(
  id: 'sudanese',
  name: 'Sudanese Curriculum',
  shortName: 'Sudanese',
  accentColor: '#D21034',
  grades: ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10', 'Grade 11', 'Grade 12'],
  annualStructure: AnnualStructure(2, 'Semester', [50, 50]),
  gradebookBands: [
    GradebookBand('Basic — Lower (Grade 1 – 6)', ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6'], [
      GradebookCategory('Assignments', 4, 20, false),
      GradebookCategory('Class Tests', 3, 20, false),
      GradebookCategory('Project', 1, 10, false),
      GradebookCategory('Semester Exam', 1, 50, true),
    ]),
    GradebookBand('Basic — Upper (Grade 7 – 9)', ['Grade 7', 'Grade 8', 'Grade 9'], [
      GradebookCategory('Assignments', 4, 15, false),
      GradebookCategory('Class Tests', 4, 25, false),
      GradebookCategory('Project', 1, 10, false),
      GradebookCategory('Semester Exam', 1, 50, true),
    ]),
    GradebookBand('Secondary (Grade 10 – 12)', ['Grade 10', 'Grade 11', 'Grade 12'], [
      GradebookCategory('Assignments', 3, 10, false),
      GradebookCategory('Assessments', 3, 20, false),
      GradebookCategory('Project', 1, 10, false),
      GradebookCategory('Mid-Term', 1, 20, true),
      GradebookCategory('Final Exam', 1, 40, true),
    ]),
  ],
  subjectBands: [
    SubjectBand('Basic — Lower (Grade 1 – 6)', ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6'], ['Arabic', 'English', 'Mathematics', 'Science', 'Islamic Studies', 'Social Studies', 'ICT', 'Art', 'Physical Education']),
    SubjectBand('Basic — Upper (Grade 7 – 9)', ['Grade 7', 'Grade 8', 'Grade 9'], ['Arabic', 'English', 'Mathematics', 'Science', 'Islamic Studies', 'Social Studies', 'ICT', 'Art', 'Physical Education']),
    SubjectBand('Secondary (Grade 10 – 12)', ['Grade 10', 'Grade 11', 'Grade 12'], ['Arabic', 'English', 'Mathematics', 'Physics', 'Chemistry', 'Biology', 'Islamic Studies', 'ICT', 'Physical Education']),
  ],
);

// ── Registry ─────────────────────────────────────────────────────────────────
const Map<String, CurriculumConfig> curricula = {
  'qatar': _qatar,
  'british': _british,
  'american': _american,
  'ib': _ib,
  'cbse': _cbse,
  'srilankan': _srilankan,
  'pakistani': _pakistani,
  'lebanese': _lebanese,
  'egyptian': _egyptian,
  'palestinian': _palestinian,
  'sudanese': _sudanese,
};

const String defaultCurriculumId = 'qatar';

CurriculumConfig getCurriculum(String? id) =>
    curricula[id] ?? curricula[defaultCurriculumId]!;

/// Return the gradebook band for a given grade within a curriculum, or null.
GradebookBand? getBandForGrade(CurriculumConfig curriculum, String grade) {
  for (final b in curriculum.gradebookBands) {
    if (b.grades.contains(grade)) return b;
  }
  return null;
}

/// Generate period labels: ["Term 1", "Term 2", "Term 3"] etc.
List<String> getPeriodLabels(CurriculumConfig curriculum) {
  final s = curriculum.annualStructure;
  return List.generate(s.periods, (i) => '${s.periodLabel} ${i + 1}');
}

/// Default subject list for a grade under a curriculum — empty if the grade
/// isn't in any of this curriculum's subject bands.
List<String> getDefaultSubjectsForGrade(CurriculumConfig curriculum, String grade) {
  for (final b in curriculum.subjectBands) {
    if (b.grades.contains(grade)) return b.subjects;
  }
  return const [];
}
