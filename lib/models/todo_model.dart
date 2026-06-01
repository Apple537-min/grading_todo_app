import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum TodoPriority { low, medium, high }
enum TodoStatus { pending, completed }
enum TodoCategory { assignment, project, exam, quiz, other }

extension TodoCategoryExtension on TodoCategory {
  IconData get icon {
    switch (this) {
      case TodoCategory.assignment:
        return Icons.assignment_outlined;
      case TodoCategory.project:
        return Icons.account_tree_outlined;
      case TodoCategory.exam:
        return Icons.article_outlined;
      case TodoCategory.quiz:
        return Icons.quiz_outlined;
      case TodoCategory.other:
        return Icons.more_horiz_outlined;
    }
  }

  Color get color {
    switch (this) {
      case TodoCategory.assignment:
        return Colors.blue;
      case TodoCategory.project:
        return Colors.purple;
      case TodoCategory.exam:
        return Colors.deepOrange;
      case TodoCategory.quiz:
        return Colors.indigo;
      case TodoCategory.other:
        return Colors.grey;
    }
  }
}

class TodoModel {
  final String id;
  final String studentId;
  final String title;
  final String description;
  final DateTime? dueDate;
  final TodoPriority priority;
  final TodoStatus status;
  final TodoCategory category;
  final String subjectCode; // Added subject support
  final DateTime createdAt;
  final DateTime? completedAt;

  TodoModel({
    required this.id,
    required this.studentId,
    required this.title,
    required this.description,
    this.dueDate,
    required this.priority,
    required this.status,
    required this.category,
    this.subjectCode = 'GEN101', // Default subject
    required this.createdAt,
    this.completedAt,
  });

  factory TodoModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TodoModel(
      id: doc.id,
      studentId: data['student_id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      dueDate: data['due_date'] != null ? (data['due_date'] as Timestamp).toDate() : null,
      priority: TodoPriority.values.firstWhere(
        (e) => e.toString().split('.').last == data['priority'],
        orElse: () => TodoPriority.medium,
      ),
      status: TodoStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => TodoStatus.pending,
      ),
      category: TodoCategory.values.firstWhere(
        (e) => e.toString().split('.').last == data['category'],
        orElse: () => TodoCategory.other,
      ),
      subjectCode: data['subject_code'] ?? 'GEN101',
      createdAt: (data['created_at'] as Timestamp).toDate(),
      completedAt: data['completed_at'] != null ? (data['completed_at'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'student_id': studentId,
      'title': title,
      'description': description,
      'due_date': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'priority': priority.toString().split('.').last,
      'status': status.toString().split('.').last,
      'category': category.toString().split('.').last,
      'subject_code': subjectCode,
      'created_at': Timestamp.fromDate(createdAt),
      'completed_at': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  Color get priorityColor {
    switch (priority) {
      case TodoPriority.high:
        return Colors.red;
      case TodoPriority.medium:
        return Colors.orange;
      case TodoPriority.low:
        return Colors.teal;
    }
  }

  int get priorityValue {
    switch (priority) {
      case TodoPriority.high:
        return 3;
      case TodoPriority.medium:
        return 2;
      case TodoPriority.low:
        return 1;
    }
  }

  bool get isOverdue {
    if (status == TodoStatus.completed) return false;
    if (dueDate == null) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  String get countdownText {
    if (status == TodoStatus.completed) return 'Completed';
    if (dueDate == null) return 'No due date';

    final now = DateTime.now();
    final difference = dueDate!.difference(now);

    if (difference.isNegative) {
      final days = difference.inDays.abs();
      if (days == 0) return 'Overdue today';
      return 'Overdue by $days day${days > 1 ? 's' : ''}';
    }

    if (difference.inDays == 0) {
      final hours = difference.inHours;
      if (hours == 0) return 'Due in ${difference.inMinutes} mins';
      return 'Due in $hours hour${hours > 1 ? 's' : ''}';
    }

    if (difference.inDays == 1) return 'Due tomorrow';
    return 'Due in ${difference.inDays} days';
  }

  IconData get categoryIcon {
    switch (category) {
      case TodoCategory.assignment:
        return Icons.assignment_outlined;
      case TodoCategory.project:
        return Icons.account_tree_outlined;
      case TodoCategory.exam:
        return Icons.article_outlined;
      case TodoCategory.quiz:
        return Icons.quiz_outlined;
      case TodoCategory.other:
        return Icons.more_horiz_outlined;
    }
  }

  Color get categoryColor {
    switch (category) {
      case TodoCategory.assignment:
        return Colors.blue;
      case TodoCategory.project:
        return Colors.purple;
      case TodoCategory.exam:
        return Colors.deepOrange;
      case TodoCategory.quiz:
        return Colors.indigo;
      case TodoCategory.other:
        return Colors.grey;
    }
  }

  TodoModel copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    TodoPriority? priority,
    TodoStatus? status,
    TodoCategory? category,
    String? subjectCode,
    DateTime? completedAt,
  }) {
    return TodoModel(
      id: id,
      studentId: studentId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      category: category ?? this.category,
      subjectCode: subjectCode ?? this.subjectCode,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
