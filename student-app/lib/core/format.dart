/// Shared formatting helpers. Single source of truth so grade labels never
/// render "Grade Grade 3" and currency is consistent across all three portals.
library;

/// Renders a grade (+ optional section) as "Grade 3" or "Grade 3-B".
/// Strips any existing leading "grade " (any case) before prefixing once, so
/// inputs "3", "Grade 3", and "grade 3" all produce "Grade 3".
String gradeLabel(dynamic grade, [dynamic section]) {
  var g = (grade ?? '').toString().trim();
  if (g.isEmpty) {
    final s = _stripSection(section);
    return s.isEmpty ? '' : 'Section $s';
  }
  g = g.replaceFirst(RegExp(r'^grade\s*', caseSensitive: false), '');
  final s = _stripSection(section);
  return s.isEmpty ? 'Grade $g' : 'Grade $g-$s';
}

String _stripSection(dynamic section) =>
    (section ?? '').toString().trim().replaceFirst(
          RegExp(r'^section\s*', caseSensitive: false),
          '',
        );

/// Canonical grade key for equality checks: "Grade 1", "grade 1", "1" → "1".
String canonGrade(String? g) => (g ?? '')
    .trim()
    .toLowerCase()
    .replaceFirst(RegExp(r'^grade\s*'), '')
    .replaceAll(RegExp(r'\s+'), '');

/// Canonical section key: "Section B", "b", "B" → "B".
String canonSection(String? s) => (s ?? '')
    .trim()
    .toUpperCase()
    .replaceFirst(RegExp(r'^SECTION\s*'), '')
    .trim();

/// Formats an amount as Bahraini Dinar with 3 decimals, e.g. "BHD 12.500".
String money(num? amount) => 'BHD ${(amount ?? 0).toStringAsFixed(3)}';
