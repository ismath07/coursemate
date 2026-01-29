import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Returns a stream of degree levels as clean maps: { id, displayName }
  Stream<List<Map<String, String>>> getDegreeLevels() {
    return _firestore
        .collection('degree_levels')
        .orderBy('displayName')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'displayName': (data['displayName'] ?? '').toString(),
        };
      }).toList();
    });
  }

  // Returns a stream of courses for a degree level: { id, displayName }
  Stream<List<Map<String, String>>> getCourses(String degreeLevelId) {
    return _firestore
        .collection('degree_levels')
        .doc(degreeLevelId)
        .collection('courses')
        .orderBy('displayName')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'displayName': (data['displayName'] ?? '').toString(),
        };
      }).toList();
    });
  }

  // Returns a stream of semesters for a course: { id, displayName }
  Stream<List<Map<String, String>>> getSemesters(
    String degreeLevelId,
    String courseId,
  ) {
    return _firestore
        .collection('degree_levels')
        .doc(degreeLevelId)
        .collection('courses')
        .doc(courseId)
        .collection('semesters')
        .orderBy('displayName')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'displayName': (data['displayName'] ?? '').toString(),
        };
      }).toList();
    });
  }

  // Returns a stream of subjects for a semester: { id, displayName, subjectCode }
  Stream<List<Map<String, String>>> getSubjects(
    String degreeLevelId,
    String courseId,
    String semesterId,
  ) {
    return _firestore
        .collection('degree_levels')
        .doc(degreeLevelId)
        .collection('courses')
        .doc(courseId)
        .collection('semesters')
        .doc(semesterId)
        .collection('subjects')
        .orderBy('displayName')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'displayName': (data['displayName'] ?? '').toString(),
          'subjectCode': (data['subjectCode'] ?? doc.id).toString(),
        };
      }).toList();
    });
  }

  // Returns syllabus data for a subject as a clean map:
  // { subjectTitle: String, units: Map<String, dynamic> }
  Future<Map<String, dynamic>?> getSyllabus(
    String degreeLevelId,
    String courseId,
    String semesterId,
    String subjectCode,
  ) async {
    final docRef = _firestore
        .collection('degree_levels')
        .doc(degreeLevelId)
        .collection('courses')
        .doc(courseId)
        .collection('semesters')
        .doc(semesterId)
        .collection('subjects')
        .doc(subjectCode);

    final doc = await docRef.get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;

    final title = (data['subjectTitle'] ?? '').toString();
    final rawUnits = data['units'] ?? {};

    return {
      'subjectTitle': title,
      'units': rawUnits is Map ? Map<String, dynamic>.from(rawUnits) : <String, dynamic>{},
    };
  }

  // Reads exam hall allotments from exam_hall_allotments/{examId}/rows ordered by 'sno'
  Future<List<Map<String, dynamic>>> getHallAllotments(String examId) async {
    final snapshot = await _firestore
        .collection('exam_hall_allotments')
        .doc(examId)
        .collection('rows')
        .orderBy('sno')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'sno': data['sno'],
        'yearDept': (data['yearDept'] is List) ? List<String>.from(data['yearDept']) : <String>[],
        'regNos': (data['regNos'] is List) ? List<String>.from(data['regNos']) : <String>[],
        'hallNo': (data['hallNo'] ?? '').toString(),
      };
    }).toList();
  }
}
