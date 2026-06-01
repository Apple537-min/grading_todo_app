import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus { present, absent, late }

class AttendanceModel {
  final String id;
  final String studentId;
  final DateTime date;
  final AttendanceStatus status;

  AttendanceModel({
    required this.id,
    required this.studentId,
    required this.date,
    required this.status,
  });

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AttendanceModel(
      id: doc.id,
      studentId: data['student_id'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      status: AttendanceStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => AttendanceStatus.present,
      ),
    );
  }
}
