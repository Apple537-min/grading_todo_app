import 'package:flutter/material.dart';
import '../services/grade_service.dart';
import '../models/grade_model.dart';
import '../models/attendance_model.dart';

class GradeProvider extends ChangeNotifier {
  final GradeService _gradeService = GradeService();
  List<AssessmentModel> _assessments = [];
  List<AttendanceModel> _attendance = [];

  List<AssessmentModel> get assessments => _assessments;
  // Support legacy screens while they migrate
  List<AssessmentModel> get scores => _assessments;
  List<AttendanceModel> get attendance => _attendance;

  void init(String studentId) {
    _gradeService.getStudentScores(studentId).listen((data) {
      _assessments = data;
      notifyListeners();
    });

    _gradeService.getStudentAttendance(studentId).listen((data) {
      _attendance = data;
      notifyListeners();
    });
  }

  GradeSummary get summary => GradeSummary(_assessments);

  Map<AttendanceStatus, int> get attendanceSummary {
    Map<AttendanceStatus, int> summary = {
      AttendanceStatus.present: 0,
      AttendanceStatus.absent: 0,
      AttendanceStatus.late: 0,
    };
    for (var a in _attendance) {
      summary[a.status] = (summary[a.status] ?? 0) + 1;
    }
    return summary;
  }
}
