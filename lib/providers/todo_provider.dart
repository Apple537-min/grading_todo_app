import 'package:flutter/material.dart';
import '../services/todo_service.dart';
import '../models/todo_model.dart';
import '../services/notification_service.dart';

enum TodoSortOption { dueDate, priority, createdAt }

class TodoProvider extends ChangeNotifier {
  final TodoService _todoService = TodoService();
  final NotificationService _notificationService = NotificationService();
  
  List<TodoModel> _todos = [];
  String _searchQuery = '';
  TodoSortOption _sortOption = TodoSortOption.dueDate;

  List<TodoModel> get todos => _todos;
  String get searchQuery => _searchQuery;
  TodoSortOption get sortOption => _sortOption;

  void init(String studentId) {
    _todoService.getTodos(studentId).listen((data) {
      _todos = data;
      notifyListeners();
    });
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSortOption(TodoSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  Future<void> addTodo(TodoModel todo) async {
    await _todoService.createTodo(todo);
    _scheduleNotifications(todo);
  }

  Future<void> updateTodo(TodoModel todo) async {
    await _todoService.updateTodo(todo);
    // Cancel old ones and schedule new ones
    await _notificationService.cancelNotification(todo.id);
    _scheduleNotifications(todo);
  }

  Future<void> deleteTodo(String todoId) async {
    await _todoService.deleteTodo(todoId);
    await _notificationService.cancelNotification(todoId);
  }

  void _scheduleNotifications(TodoModel todo) {
    if (todo.dueDate == null || todo.status == TodoStatus.completed) return;

    // 1. Reminder 1 hour before
    final oneHourBefore = todo.dueDate!.subtract(const Duration(hours: 1));
    if (oneHourBefore.isAfter(DateTime.now())) {
      _notificationService.scheduleTodoReminder(
        id: '${todo.id}_1h',
        title: 'Task Due Soon!',
        body: '${todo.title} is due in 1 hour',
        scheduledDate: oneHourBefore,
      );
    }

    // 2. Reminder at exactly the due time
    _notificationService.scheduleTodoReminder(
      id: todo.id,
      title: 'Task Deadline!',
      body: 'Your task "${todo.title}" is due now!',
      scheduledDate: todo.dueDate!,
    );
  }

  List<TodoModel> getFilteredAndSortedTodos(TodoStatus? statusFilter, {TodoCategory? categoryFilter}) {
    List<TodoModel> filtered = _todos;

    if (statusFilter != null) {
      filtered = filtered.where((t) => t.status == statusFilter).toList();
    }

    if (categoryFilter != null) {
      filtered = filtered.where((t) => t.category == categoryFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((t) =>
          t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.description.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    filtered.sort((a, b) {
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;

      if (a.status == TodoStatus.completed && b.status != TodoStatus.completed) return 1;
      if (a.status != TodoStatus.completed && b.status == TodoStatus.completed) return -1;

      switch (_sortOption) {
        case TodoSortOption.dueDate:
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        case TodoSortOption.priority:
          return b.priorityValue.compareTo(a.priorityValue);
        case TodoSortOption.createdAt:
          return b.createdAt.compareTo(a.createdAt);
      }
    });

    return filtered;
  }
}
