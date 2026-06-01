import 'package:cloud_firestore/cloud_firestore.dart';

enum AssessmentType { quiz, exam, activity, oral, project }

class WeightConfig {
  static const Map<AssessmentType, double> defaultWeights = {
    AssessmentType.quiz: 0.20,     // 20%
    AssessmentType.exam: 0.40,     // 40%
    AssessmentType.activity: 0.10, // 10%
    AssessmentType.oral: 0.15,     // 15%
    AssessmentType.project: 0.15,  // 15%
  };
}

class AssessmentModel {
  final String id;
  final String studentId;
  final String title;
  final double score;
  final int totalItems;
  final AssessmentType type;
  final String term; // Prelim, Midterm, Finals
  final String subjectCode; 
  final String subjectName; 
  final DateTime createdAt;

  AssessmentModel({
    required this.id,
    required this.studentId,
    required this.title,
    required this.score,
    required this.totalItems,
    required this.type,
    required this.term,
    required this.subjectCode,
    required this.subjectName,
    required this.createdAt,
  });

  bool get isOral => type == AssessmentType.oral;
  bool get isExam => type == AssessmentType.exam;

  factory AssessmentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AssessmentModel(
      id: doc.id,
      studentId: data['student_id'] ?? '',
      title: data['title'] ?? '',
      score: (data['score'] ?? 0).toDouble(),
      totalItems: data['total_items'] ?? (data['number_of_items'] ?? 100),
      type: AssessmentType.values.firstWhere(
        (e) => e.name == (data['type'] ?? data['category'] ?? 'activity'),
        orElse: () => AssessmentType.activity,
      ),
      term: data['term'] ?? '',
      subjectCode: data['subject_code'] ?? 'GEN101',
      subjectName: data['subject_name'] ?? 'General Education',
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'student_id': studentId,
      'title': title,
      'score': score,
      'total_items': totalItems,
      'type': type.name,
      'term': term,
      'subject_code': subjectCode,
      'subject_name': subjectName,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}

class GradeSummary {
  final List<AssessmentModel> assessments;
  
  GradeSummary(this.assessments);

  List<String> get uniqueSubjectCodes => 
      assessments.map((a) => a.subjectCode).toSet().toList();

  double calculateAverage(AssessmentType type, {String? subjectCode, String? term}) {
    var filtered = assessments.where((a) => a.type == type).toList();
    if (subjectCode != null) {
      filtered = filtered.where((a) => a.subjectCode == subjectCode).toList();
    }
    if (term != null) {
      filtered = filtered.where((a) => a.term == term).toList();
    }
    
    if (filtered.isEmpty) return 0.0;
    
    double totalPercent = 0;
    for (var a in filtered) {
      totalPercent += (a.score / a.totalItems);
    }
    return (totalPercent / filtered.length) * 100;
  }

  /// Calculates the final weighted grade (GPA) for a specific term and subject.
  /// Standard: Quiz(20%) + Exam(40%) + Activity(10%) + Oral(15%) + Project(15%)
  double calculateWeightedFinalGrade({String? subjectCode, String? term}) {
    double finalGrade = 0.0;
    double weightAccountedFor = 0.0;

    for (var type in AssessmentType.values) {
      double average = calculateAverage(type, subjectCode: subjectCode, term: term);
      double weight = WeightConfig.defaultWeights[type] ?? 0.0;
      
      // If no assessments yet for a category, we don't count it for the current projection
      // but in a strict system we might count it as zero. 
      // Here we only weight categories that have data to give a "current standing".
      if (assessments.any((a) => a.type == type && 
          (subjectCode == null || a.subjectCode == subjectCode) && 
          (term == null || a.term == term))) {
        finalGrade += (average * weight);
        weightAccountedFor += weight;
      }
    }

    // Normalize if some categories are missing to show "Current Standing"
    if (weightAccountedFor == 0) return 0.0;
    return (finalGrade / weightAccountedFor);
  }

  double calculateExamScore(String term) {
    var exam = assessments.firstWhere(
      (a) => a.type == AssessmentType.exam && a.term == term,
      orElse: () => AssessmentModel(
        id: '',
        studentId: '',
        title: '',
        score: 0,
        totalItems: 100,
        type: AssessmentType.exam,
        term: term,
        subjectCode: '',
        subjectName: '',
        createdAt: DateTime.now(),
      ),
    );
    return (exam.score / exam.totalItems) * 100;
  }
}
