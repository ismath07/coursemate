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

    // Step 1: Check staff_accounts collection first
    final staffDoc = await _firestore
        .collection('staff_accounts')
        .doc(user.uid)
        .get();

    if (staffDoc.exists) {
      return 'staff';
    }

    // Step 2: Check users collection
    final studentDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (studentDoc.exists) {
      return 'student';
    }

    // Step 3: If neither exists, create student document
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set({
      'email': user.email ?? '',
      'name': user.displayName ?? '',
      'role': 'student',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return 'student';
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

  /// Check if current user is admin (for edit permissions)
  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Check staff_accounts first
    final staffDoc = await _firestore
        .collection('staff_accounts')
        .doc(user.uid)
        .get();

    if (staffDoc.exists) {
      final data = staffDoc.data();
      if (data != null && data['isAdmin'] is bool) {
        return data['isAdmin'] as bool;
      }
    }

    // Check users collection
    final userDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (userDoc.exists) {
      final data = userDoc.data();
      if (data != null && data['isAdmin'] is bool) {
        return data['isAdmin'] as bool;
      }
    }

    return false;
  }

  /* ============================================================
     EDIT ACCESS CONTROL
     ============================================================ */

  /// Create staff account if not exists with default access fields
  Future<void> createStaffAccountIfNotExists() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('staff_accounts')
        .doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      // Create new staff document with default access fields
      await docRef.set({
        'email': user.email ?? '',
        'name': user.displayName ?? '',
        'role': 'staff',
        'createdAt': FieldValue.serverTimestamp(),
        // DEFAULT ACCESS FIELDS
        'adminApproved': false,
        'editAccessRequested': false,
        'editAccessApproved': false,
      });
    } else {
      // Ensure existing document also has required fields
      final data = doc.data();
      if (data != null) {
        Map<String, dynamic> updates = {};
        
        if (!data.containsKey('adminApproved')) {
          updates['adminApproved'] = false;
        }
        if (!data.containsKey('editAccessRequested')) {
          updates['editAccessRequested'] = false;
        }
        if (!data.containsKey('editAccessApproved')) {
          updates['editAccessApproved'] = false;
        }
        
        if (updates.isNotEmpty) {
          await docRef.update(updates);
        }
      }
    }
  }

  /// Ensure staff account has edit access fields (legacy support)
  Future<void> ensureStaffAccessFields() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore.collection('staff_accounts').doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) return;

    final data = doc.data();
    if (data == null) return;

    // Check if fields are missing
    if (!data.containsKey('editAccessRequested') ||
        !data.containsKey('editAccessApproved')) {
      await docRef.set({
        'editAccessRequested': false,
        'editAccessApproved': false,
      }, SetOptions(merge: true));
    }
  }

  /// Check if current user has edit access approved
  Future<bool> isEditAccessApproved() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _firestore
        .collection('staff_accounts')
        .doc(user.uid)
        .get();

    if (!doc.exists) return false;

    final data = doc.data();
    return data?['editAccessApproved'] == true;
  }

  /// Request edit access
  Future<void> requestEditAccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('staff_accounts')
        .doc(user.uid)
        .update({
      'editAccessRequested': true,
    });
  }

  /// Stream edit access status
  Stream<bool> editAccessStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);

    return _firestore
        .collection('staff_accounts')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return false;
      final data = doc.data();
      return data?['editAccessApproved'] == true;
    });
  }

  /// Stream staff account document for real-time updates
  Stream<DocumentSnapshot> getStaffAccountStream() {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    
    return _firestore
        .collection('staff_accounts')
        .doc(user.uid)
        .snapshots();
  }

  /// Get edit access request status
  Future<Map<String, bool>> getEditAccessStatus() async {
    final user = _auth.currentUser;
    if (user == null) {
      return {
        'editAccessApproved': false,
        'editAccessRequested': false,
      };
    }

    final doc = await _firestore
        .collection('staff_accounts')
        .doc(user.uid)
        .get();

    if (!doc.exists) {
      return {
        'editAccessApproved': false,
        'editAccessRequested': false,
      };
    }

    final data = doc.data();
    return {
      'editAccessApproved': data?['editAccessApproved'] == true,
      'editAccessRequested': data?['editAccessRequested'] == true,
    };
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

/* ============================================================
   EXAM TIMETABLE FLOW
   ============================================================ */

/// Get UG / PG
Stream<List<Map<String, String>>> getExamDegrees() {
  return _firestore
      .collection('exam_timetables')
      .orderBy('displayName')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'displayName': (data['displayName'] ?? doc.id).toString(),
      };
    }).toList();
  });
}

/// Get Departments
Stream<List<Map<String, String>>> getExamDepartments(
  String degreeId,
) {
  return _firestore
      .collection('exam_timetables')
      .doc(degreeId)
      .collection('departments')
      .orderBy('displayName')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'displayName': (data['displayName'] ?? doc.id).toString(),
      };
    }).toList();
  });
}

/// Get Years
Stream<List<Map<String, String>>> getExamYears(
  String degreeId,
  String departmentId,
) {
  return _firestore
      .collection('exam_timetables')
      .doc(degreeId)
      .collection('departments')
      .doc(departmentId)
      .collection('years')
      .orderBy('displayName')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'displayName': (data['displayName'] ?? doc.id).toString(),
      };
    }).toList();
  });
}

/// Get Exams (Timetable rows)
Stream<List<Map<String, dynamic>>> getExamTimetable(
  String degreeId,
  String departmentId,
  String yearId,
) {
  return _firestore
      .collection('exam_timetables')
      .doc(degreeId)
      .collection('departments')
      .doc(departmentId)
      .collection('years')
      .doc(yearId)
      .collection('subjects')
      .orderBy('date')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'subjectName': data['subjectName'] ?? '',
        'subjectCode': data['subjectCode'] ?? '',
        'date': data['date'] ?? '',
        'day': data['day'] ?? '',
        'session': data['session'] ?? '',
      };
    }).toList();
  });
}


  Future<List<Map<String, dynamic>>> getStaffHallAllotments() async {
    final snapshot = await _firestore
        .collection('staff_hall_allotments')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'staffName': data['staffName'] ?? '',
        'hallNo': data['hallNo'] ?? '',
        'noOfStudents': data['noOfStudents'] ?? [],
        'createdAt': data['createdAt'],
      };

    }).toList();
  }

  /* ============================================================
     ADMIN ACCESS CONTROL
     ============================================================ */

  Stream<bool> getSyllabusTimetableAccess() {
    return _firestore
        .collection('admin_access')
        .doc('syllabus_timetable')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return false;
      final data = snapshot.data();
      return data?['enabled'] == true;
    });
  }

  Future<void> toggleSyllabusTimetableAccess(bool enabled) async {
    await _firestore
        .collection('admin_access')
        .doc('syllabus_timetable')
        .set({'enabled': enabled}, SetOptions(merge: true));
  }

  /* ============================================================
     SYLLABUS CRUD OPERATIONS
     ============================================================ */

  Future<void> addSubject({
    required String degreeLevelId,
    required String courseId,
    required String semesterId,
    required String subjectCode,
    required String displayName,
    required String subjectTitle,
    required Map<String, dynamic> units,
  }) async {
    await _firestore
        .collection('degree_levels')
        .doc(degreeLevelId)
        .collection('courses')
        .doc(courseId)
        .collection('semesters')
        .doc(semesterId)
        .collection('subjects')
        .doc(subjectCode)
        .set({
      'displayName': displayName,
      'subjectCode': subjectCode,
      'subjectTitle': subjectTitle,
      'units': units,
    });
  }

  Future<void> updateSubject({
    required String degreeLevelId,
    required String courseId,
    required String semesterId,
    required String subjectCode,
    required String subjectTitle,
    required Map<String, dynamic> units,
  }) async {
    await _firestore
        .collection('degree_levels')
        .doc(degreeLevelId)
        .collection('courses')
        .doc(courseId)
        .collection('semesters')
        .doc(semesterId)
        .collection('subjects')
        .doc(subjectCode)
        .update({
      'subjectTitle': subjectTitle,
      'units': units,
    });
  }

  /// Update subject name and code
  Future<void> updateSubjectInfo({
    required String degreeLevelId,
    required String courseId,
    required String semesterId,
    required String oldSubjectCode,
    required String newSubjectCode,
    required String displayName,
    required String subjectTitle,
  }) async {
    // If subject code changed, we need to create new doc and delete old one
    if (oldSubjectCode != newSubjectCode) {
      // Get existing data
      final oldDoc = await _firestore
          .collection('degree_levels')
          .doc(degreeLevelId)
          .collection('courses')
          .doc(courseId)
          .collection('semesters')
          .doc(semesterId)
          .collection('subjects')
          .doc(oldSubjectCode)
          .get();

      if (oldDoc.exists) {
        final data = oldDoc.data();
        // Create new document with new code
        await _firestore
            .collection('degree_levels')
            .doc(degreeLevelId)
            .collection('courses')
            .doc(courseId)
            .collection('semesters')
            .doc(semesterId)
            .collection('subjects')
            .doc(newSubjectCode)
            .set({
          'displayName': displayName,
          'subjectCode': newSubjectCode,
          'subjectTitle': subjectTitle,
          'units': data?['units'] ?? {},
        });

        // Delete old document
        await _firestore
            .collection('degree_levels')
            .doc(degreeLevelId)
            .collection('courses')
            .doc(courseId)
            .collection('semesters')
            .doc(semesterId)
            .collection('subjects')
            .doc(oldSubjectCode)
            .delete();
      }
    } else {
      // Just update the existing document
      await _firestore
          .collection('degree_levels')
          .doc(degreeLevelId)
          .collection('courses')
          .doc(courseId)
          .collection('semesters')
          .doc(semesterId)
          .collection('subjects')
          .doc(oldSubjectCode)
          .update({
        'displayName': displayName,
        'subjectTitle': subjectTitle,
      });
    }
  }

  /// Update a specific unit within a subject
  Future<void> updateUnit({
    required String degreeLevelId,
    required String courseId,
    required String semesterId,
    required String subjectCode,
    required String unitKey,
    required String unitContent,
  }) async {
    await _firestore
        .collection('degree_levels')
        .doc(degreeLevelId)
        .collection('courses')
        .doc(courseId)
        .collection('semesters')
        .doc(semesterId)
        .collection('subjects')
        .doc(subjectCode)
        .update({
      'units.$unitKey': unitContent,
    });
  }

  Future<void> deleteSubject({
    required String degreeLevelId,
    required String courseId,
    required String semesterId,
    required String subjectCode,
  }) async {
    await _firestore
        .collection('degree_levels')
        .doc(degreeLevelId)
        .collection('courses')
        .doc(courseId)
        .collection('semesters')
        .doc(semesterId)
        .collection('subjects')
        .doc(subjectCode)
        .delete();
  }

  /* ============================================================
     TIMETABLE CRUD OPERATIONS
     ============================================================ */

  Future<void> addTimetable({
    required String degreeId,
    required String departmentId,
    required String yearId,
    required String title,
    required String subjectCode,
    required String date,
    required String day,
    required String session,
  }) async {
    await _firestore
        .collection('exam_timetables')
        .doc(degreeId)
        .collection('departments')
        .doc(departmentId)
        .collection('years')
        .doc(yearId)
        .collection('subjects')
        .add({
      'subjectName': title,
      'subjectCode': subjectCode,
      'date': date,
      'day': day,
      'session': session,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateTimetable({
    required String degreeId,
    required String departmentId,
    required String yearId,
    required String examId,
    required String title,
    required String subjectCode,
    required String date,
    required String day,
    required String session,
  }) async {
    await _firestore
        .collection('exam_timetables')
        .doc(degreeId)
        .collection('departments')
        .doc(departmentId)
        .collection('years')
        .doc(yearId)
        .collection('subjects')
        .doc(examId)
        .update({
      'subjectName': title,
      'subjectCode': subjectCode,
      'date': date,
      'day': day,
      'session': session,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteTimetable({
    required String degreeId,
    required String departmentId,
    required String yearId,
    required String examId,
  }) async {
    await _firestore
        .collection('exam_timetables')
        .doc(degreeId)
        .collection('departments')
        .doc(departmentId)
        .collection('years')
        .doc(yearId)
        .collection('subjects')
        .doc(examId)
        .delete();
  }

  /* ============================================================
     COURSE CRUD OPERATIONS
     ============================================================ */

  /// Add a new course
  Future<void> addCourse({
    required String degreeLevelId,
    required String displayName,
  }) async {
    await _firestore
        .collection('degree_levels')
        .doc(degreeLevelId)
        .collection('courses')
        .add({
      'displayName': displayName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update course
  Future<void> updateCourse({
    required String degreeLevelId,
    required String courseId,
    required String displayName,
  }) async {
    await _firestore
        .collection('degree_levels')
        .doc(degreeLevelId)
        .collection('courses')
        .doc(courseId)
        .update({
      'displayName': displayName,
    });
  }

  /// Delete course
  Future<void> deleteCourse({
    required String degreeLevelId,
    required String courseId,
  }) async {
    await _firestore
        .collection('degree_levels')
        .doc(degreeLevelId)
        .collection('courses')
        .doc(courseId)
        .delete();
  }

  /* ============================================================
     SEMESTER CRUD OPERATIONS
     ============================================================ */

  /// Add a new semester
  Future<void> addSemester({
    required String degreeLevelId,
    required String courseId,
    required String displayName,
  }) async {
    await _firestore
        .collection('degree_levels')
        .doc(degreeLevelId)
        .collection('courses')
        .doc(courseId)
        .collection('semesters')
        .add({
      'displayName': displayName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update semester
  Future<void> updateSemester({
    required String degreeLevelId,
    required String courseId,
    required String semesterId,
    required String displayName,
  }) async {
    await _firestore
        .collection('degree_levels')
        .doc(degreeLevelId)
        .collection('courses')
        .doc(courseId)
        .collection('semesters')
        .doc(semesterId)
        .update({
      'displayName': displayName,
    });
  }

  /// Delete semester
  Future<void> deleteSemester({
    required String degreeLevelId,
    required String courseId,
    required String semesterId,
  }) async {
    await _firestore
        .collection('degree_levels')
        .doc(degreeLevelId)
        .collection('courses')
        .doc(courseId)
        .collection('semesters')
        .doc(semesterId)
        .delete();
  }

  /* ============================================================
     UNIT CRUD OPERATIONS
     ============================================================ */

  /// Add a new unit to a subject
  Future<void> addUnit({
    required String degreeLevelId,
    required String courseId,
    required String semesterId,
    required String subjectCode,
    required String unitTitle,
    required String unitContent,
  }) async {
    // Get current units
    final doc = await _firestore
        .collection('degree_levels')
        .doc(degreeLevelId)
        .collection('courses')
        .doc(courseId)
        .collection('semesters')
        .doc(semesterId)
        .collection('subjects')
        .doc(subjectCode)
        .get();

    final units = Map<String, dynamic>.from(doc.data()?['units'] ?? {});
    units[unitTitle] = unitContent;

    await _firestore
        .collection('degree_levels')
        .doc(degreeLevelId)
        .collection('courses')
        .doc(courseId)
        .collection('semesters')
        .doc(semesterId)
        .collection('subjects')
        .doc(subjectCode)
        .update({
      'units': units,
    });
  }

  /// Delete a unit from a subject
  Future<void> deleteUnit({
    required String degreeLevelId,
    required String courseId,
    required String semesterId,
    required String subjectCode,
    required String unitKey,
  }) async {
    await _firestore
        .collection('degree_levels')
        .doc(degreeLevelId)
        .collection('courses')
        .doc(courseId)
        .collection('semesters')
        .doc(semesterId)
        .collection('subjects')
        .doc(subjectCode)
        .update({
      'units.$unitKey': FieldValue.delete(),
    });
  }

}
