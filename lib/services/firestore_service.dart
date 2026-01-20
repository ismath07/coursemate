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
  // { subjectTitle: String, units: Map<String, String> }
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

    final title = (data['displayName'] ?? '').toString();
    final rawUnits = data['units'];

    final units = <String, String>{};
    if (rawUnits is Map) {
      rawUnits.forEach((key, value) {
        if (key != null && value != null) {
          units[key.toString()] = value.toString();
        }
      });
    }

    return {
      'subjectTitle': title,
      'units': units,
    };
  }

  // Finds a subject document across all 'subjects' subcollections by subjectCode
  // and returns { subjectTitle, units } similar to getSyllabus above.
  Future<Map<String, dynamic>?> getSyllabusBySubjectCode(
    String subjectCode,
  ) async {
    final query = await _firestore
        .collectionGroup('subjects')
        .where('subjectCode', isEqualTo: subjectCode)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    final data = doc.data();

    final title = (data['displayName'] ?? '').toString();
    final rawUnits = data['units'];

    final units = <String, String>{};
    if (rawUnits is Map) {
      rawUnits.forEach((key, value) {
        if (key != null && value != null) {
          units[key.toString()] = value.toString();
        }
      });
    }

    return {
      'subjectTitle': title,
      'units': units,
    };
  }
}
