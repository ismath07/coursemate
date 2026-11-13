import 'package:cloud_firestore/cloud_firestore.dart';

/// Fixed academic order for Year/Department master data.
///
/// Sort key: degreePriority → coursePriority → yearPriority
/// Unknown UG entries appear after known UG courses but before PG.
/// Unknown PG entries appear after known PG courses.
class YearDeptSort {
  YearDeptSort._();

  static const _ugCourses = [
    'TAMIL',
    'ENGLISH',
    'BSC MATHS',
    'BSC N&D',
    'BSC BIO',
    'BSC CS',
    'BSC IT',
    'BCA',
    'BSC BIO TECH',
    'BSC DS',
    'BSC AI&ML',
    'BCOM',
    'BCOM BM',
    'BCOM CA',
  ];

  static const _pgCourses = [
    'MA ENGLISH',
    'MA TAMIL',
    'MSC MATHS',
    'MSC FSN',
    'MSC BIO',
    'MSC CS',
    'MSC IT',
    'MCOM',
    'MBA',
  ];

  static const _unknownCoursePriority = 1000;

  /// Compares two display names using the fixed academic order.
  static int compareDisplayNames(String a, String b) {
    return _sortKey(a).compareTo(_sortKey(b));
  }

  /// Returns a new list of Firestore documents sorted by academic order.
  static List<QueryDocumentSnapshot> sortDocuments(
    Iterable<QueryDocumentSnapshot> docs,
  ) {
    final sorted = docs.toList();
    sorted.sort((a, b) {
      final nameA = a['displayName']?.toString() ?? '';
      final nameB = b['displayName']?.toString() ?? '';
      return compareDisplayNames(nameA, nameB);
    });
    return sorted;
  }

  /// Sorts `{id, name}` (or `{id, displayName}`) maps in place.
  static void sortMaps(
    List<Map<String, String>> items, {
    String nameKey = 'name',
  }) {
    items.sort((a, b) => compareDisplayNames(a[nameKey] ?? '', b[nameKey] ?? ''));
  }

  static _YearDeptSortKey _sortKey(String displayName) {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      return const _YearDeptSortKey(
        degreePriority: 2,
        coursePriority: _unknownCoursePriority,
        yearPriority: 99,
        tieBreaker: '',
      );
    }

    final parsed = _parseDisplayName(trimmed);
    final yearPriority = _yearPriority(parsed.year);
    final courseIndex = _courseIndex(parsed.course);

    if (courseIndex != null) {
      return _YearDeptSortKey(
        degreePriority: courseIndex.isUg ? 0 : 1,
        coursePriority: courseIndex.index,
        yearPriority: yearPriority,
        tieBreaker: trimmed.toLowerCase(),
      );
    }

    final isPg = _inferPg(parsed.year, parsed.course);
    return _YearDeptSortKey(
      degreePriority: isPg ? 1 : 0,
      coursePriority: _unknownCoursePriority,
      yearPriority: yearPriority,
      tieBreaker: trimmed.toLowerCase(),
    );
  }

  static _ParsedYearDept _parseDisplayName(String displayName) {
    final normalized = _normalizeText(displayName);
    final match = RegExp(r'^(I{1,3})\s*[-]?\s*(.+)$').firstMatch(normalized);
    if (match != null) {
      return _ParsedYearDept(
        year: match.group(1)!,
        course: match.group(2)!.trim(),
      );
    }
    return _ParsedYearDept(year: null, course: normalized);
  }

  static int _yearPriority(String? year) {
    switch (year) {
      case 'I':
        return 1;
      case 'II':
        return 2;
      case 'III':
        return 3;
      default:
        return 99;
    }
  }

  static _CourseMatch? _courseIndex(String course) {
    final normalizedCourse = _normalizeCourse(course);

    for (var i = 0; i < _ugCourses.length; i++) {
      if (_normalizeCourse(_ugCourses[i]) == normalizedCourse) {
        return _CourseMatch(index: i, isUg: true);
      }
    }

    for (var i = 0; i < _pgCourses.length; i++) {
      if (_normalizeCourse(_pgCourses[i]) == normalizedCourse) {
        return _CourseMatch(index: i, isUg: false);
      }
    }

    return null;
  }

  static bool _inferPg(String? year, String course) {
    if (year == 'III') return false;

    final normalizedCourse = _normalizeCourse(course);
    return RegExp(r'^(MA|MSC|MCOM|MBA)\b').hasMatch(normalizedCourse);
  }

  static String _normalizeText(String value) {
    var result = value.trim().toUpperCase();
    result = result.replaceAll(RegExp(r'\s*&\s*'), '&');
    result = result.replaceAll(RegExp(r'\s+'), ' ');
    return result;
  }

  static String _normalizeCourse(String course) => _normalizeText(course);
}

class _ParsedYearDept {
  final String? year;
  final String course;

  const _ParsedYearDept({required this.year, required this.course});
}

class _CourseMatch {
  final int index;
  final bool isUg;

  const _CourseMatch({required this.index, required this.isUg});
}

class _YearDeptSortKey implements Comparable<_YearDeptSortKey> {
  final int degreePriority;
  final int coursePriority;
  final int yearPriority;
  final String tieBreaker;

  const _YearDeptSortKey({
    required this.degreePriority,
    required this.coursePriority,
    required this.yearPriority,
    required this.tieBreaker,
  });

  @override
  int compareTo(_YearDeptSortKey other) {
    final degreeCompare = degreePriority.compareTo(other.degreePriority);
    if (degreeCompare != 0) return degreeCompare;

    final courseCompare = coursePriority.compareTo(other.coursePriority);
    if (courseCompare != 0) return courseCompare;

    final yearCompare = yearPriority.compareTo(other.yearPriority);
    if (yearCompare != 0) return yearCompare;

    return tieBreaker.compareTo(other.tieBreaker);
  }
}
