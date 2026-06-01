import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/grade_model.dart';
import '../models/attendance_model.dart';

class GradeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Optimized polymorphic query
  Stream<List<AssessmentModel>> getStudentScores(String studentId) {
    return _firestore
        .collection('assessments') // Changed from 'grades' to 'assessments'
        .where('student_id', isEqualTo: studentId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AssessmentModel.fromFirestore(doc)).toList();
    });
  }

  Stream<List<AttendanceModel>> getStudentAttendance(String studentId) {
    return _firestore
        .collection('attendance')
        .where('student_id', isEqualTo: studentId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AttendanceModel.fromFirestore(doc)).toList();
    });
  }
}
