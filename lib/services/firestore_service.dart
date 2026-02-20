import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /* ============================================================
     SYLLABUS FLOW (already working – unchanged)
     ============================================================ */

  // Degree levels (UG / PG etc.)
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

  // Courses
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

  // Semesters
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

  // Subjects
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

  // Syllabus content
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

    return {
      'subjectTitle': (data['subjectTitle'] ?? '').toString(),
      'units': data['units'] is Map
          ? Map<String, dynamic>.from(data['units'])
          : <String, dynamic>{},
    };
  }

  /* ============================================================
     HALL ALLOTMENT FLOW
     ============================================================ */

  // 🔹 UG / PG cards
  Stream<List<Map<String, String>>> getHallDegrees() {
    return _firestore
        .collection('exam_hall_allotments')
        .get()
        .asStream()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id, // UG / PG
          'displayName': (data['displayName'] ?? doc.id).toString(),
        };
      }).toList();
    });
  }

  // 🔹 Hall allotment table rows
  Future<List<Map<String, dynamic>>> getHallAllotmentRows({
    required String degreeId, // UG / PG
    required String examId,   // nov_2025
  }) async {
    final snapshot = await _firestore
        .collection('exam_hall_allotments')
        .doc(degreeId)
        .collection(examId)
        .orderBy('sno')
        .get();

    final docs = snapshot.docs;

    // Sort by sno
    docs.sort((a, b) {
      final sa = a.data()['sno'];
      final sb = b.data()['sno'];
      final na = sa is num ? sa.toInt() : int.tryParse(sa.toString()) ?? 0;
      final nb = sb is num ? sb.toInt() : int.tryParse(sb.toString()) ?? 0;
      return na.compareTo(nb);
    });

    return docs.map((doc) {
      final data = doc.data();
      return {
        'sno': data['sno'],
        'yearDept': List<String>.from(data['yearDept'] ?? []),
        'regNumbers': List<String>.from(data['regNumbers'] ?? []),
        'hallNo': (data['hallNo'] ?? '').toString(),
        'noOfStudents': data['noOfStudents'],
      };
    }).toList();
  }

  /* ============================================================
     PROFILE & ROLE FLOW (Staff & Student)
     ============================================================ */

  Future<String?> getUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final staffDoc = await _firestore
        .collection('staff_accounts')
        .doc(user.uid)
        .get();

    if (staffDoc.exists) {
      return 'staff';
    }

    final studentDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (studentDoc.exists) {
      return 'student';
    }

    return null;
  }

  Future<bool> isAdminApproved() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Prefer staff_accounts for staff users if present
    final staffDoc = await _firestore
        .collection('staff_accounts')
        .doc(user.uid)
        .get();

    if (staffDoc.exists) {
      final data = staffDoc.data();
      if (data != null && data['adminApproved'] is bool) {
        return data['adminApproved'] as bool;
      }
    }

    // Fallback to users collection (students / legacy staff)
    final userDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (userDoc.exists) {
      final data = userDoc.data();
      if (data != null && data['adminApproved'] is bool) {
        return data['adminApproved'] as bool;
      }
    }

    return false;
  }

  Future<void> updateUserProfile({required String name}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final role = await getUserRole();

    if (role == 'staff') {
      await _firestore
          .collection('staff_accounts')
          .doc(user.uid)
          .update({'name': name});
    } else if (role == 'student') {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({'name': name});
    }
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final role = await getUserRole();

    if (role == 'staff') {
      final doc = await _firestore
          .collection('staff_accounts')
          .doc(user.uid)
          .get();
      if (!doc.exists) return null;
      return doc.data();
    } else if (role == 'student') {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      if (!doc.exists) return null;
      return doc.data();
    }

    return null;
  }
}
