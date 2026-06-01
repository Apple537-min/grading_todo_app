import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../providers/auth_provider.dart';
import '../models/todo_model.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  TodoStatus? _filterStatus;
  TodoCategory? _filterCategory;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final todoProvider = Provider.of<TodoProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final filteredTodos = todoProvider.getFilteredAndSortedTodos(
      _filterStatus,
      categoryFilter: _filterCategory,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          PopupMenuButton<TodoSortOption>(
            icon: const Icon(Icons.sort),
            onSelected: (option) => todoProvider.setSortOption(option),
            itemBuilder: (context) => [
              const PopupMenuItem(value: TodoSortOption.dueDate, child: Text('Sort by Due Date')),
              const PopupMenuItem(value: TodoSortOption.priority, child: Text('Sort by Priority')),
              const PopupMenuItem(value: TodoSortOption.createdAt, child: Text('Sort by Created At')),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(160),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Search tasks...',
                  onChanged: (value) => todoProvider.setSearchQuery(value),
                  leading: const Icon(Icons.search),
                  trailing: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          todoProvider.setSearchQuery('');
                        },
                      ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _buildFilterChip(null, 'All Status'),
                    const SizedBox(width: 8),
                    _buildFilterChip(TodoStatus.pending, 'Pending'),
                    const SizedBox(width: 8),
                    _buildFilterChip(TodoStatus.completed, 'Completed'),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _buildCategoryChip(null, 'All Categories'),
                    ...TodoCategory.values.map((cat) => Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: _buildCategoryChip(cat, cat.toString().split('.').last.toUpperCase()),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: filteredTodos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.isNotEmpty ? 'No matches found.' : 'No tasks for now!',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredTodos.length,
              itemBuilder: (context, index) {
                final task = filteredTodos[index];
                return _buildSwipeableTaskCard(context, task, todoProvider);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskDialog(context, null, todoProvider, authProvider.currentStudent!.studentId),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(TodoStatus? status, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _filterStatus == status,
      onSelected: (selected) {
        setState(() {
          _filterStatus = selected ? status : null;
        });
      },
    );
  }

  Widget _buildCategoryChip(TodoCategory? category, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _filterCategory == category,
      selectedColor: category?.color.withValues(alpha: 0.2),
      onSelected: (selected) {
        setState(() {
          _filterCategory = selected ? category : null;
        });
      },
    );
  }

  Widget _buildSwipeableTaskCard(BuildContext context, TodoModel task, TodoProvider provider) {
    return Dismissible(
      key: Key(task.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.green,
        child: const Icon(Icons.check, color: Colors.white),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          provider.updateTodo(task.copyWith(
            status: TodoStatus.completed,
            completedAt: DateTime.now(),
          ));
          if (!context.mounted) return false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Task "${task.title}" completed!'), duration: const Duration(seconds: 1)),
          );
          return false;
        } else {
          return await _showDeleteConfirmation(context, task, provider);
        }
      },
      child: _buildTaskCard(context, task, provider),
    );
  }

  Widget _buildTaskCard(BuildContext context, TodoModel task, TodoProvider provider) {
    return Card(
      elevation: task.isOverdue ? 4 : 1,
      shape: task.isOverdue
          ? RoundedRectangleBorder(
              side: const BorderSide(color: Colors.red, width: 2),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: task.priorityColor, width: 6),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Icon(task.categoryIcon, color: task.categoryColor),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    decoration: task.status == TodoStatus.completed ? TextDecoration.lineThrough : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (task.isOverdue) const BlinkingBadge(),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description.isNotEmpty)
                Text(
                  task.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: task.categoryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      task.category.toString().split('.').last.toUpperCase(),
                      style: TextStyle(color: task.categoryColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.access_time, size: 14, color: task.isOverdue ? Colors.red : Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    task.countdownText,
                    style: TextStyle(
                      color: task.isOverdue ? Colors.red : Colors.grey[700],
                      fontWeight: task.isOverdue ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          onTap: () => _showTaskDialog(context, task, provider, task.studentId),
        ),
      ),
    );
  }

  void _showTaskDialog(BuildContext context, TodoModel? task, TodoProvider provider, String studentId) {
    final titleController = TextEditingController(text: task?.title);
    final descController = TextEditingController(text: task?.description);
    TodoPriority priority = task?.priority ?? TodoPriority.medium;
    TodoCategory category = task?.category ?? TodoCategory.assignment;
    DateTime? dueDate = task?.dueDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(task == null ? 'Add Task' : 'Edit Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TodoCategory>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: TodoCategory.values.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c.toString().split('.').last.toUpperCase()),
                  )).toList(),
                  onChanged: (val) => setDialogState(() => category = val!),
                ),
                DropdownButtonFormField<TodoPriority>(
                  initialValue: priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: TodoPriority.values.map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(p.toString().split('.').last.toUpperCase()),
                  )).toList(),
                  onChanged: (val) => setDialogState(() => priority = val!),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(dueDate == null ? 'Set Due Date' : DateFormat('MMM d, h:mm a').format(dueDate!)),
                  trailing: const Icon(Icons.calendar_today, size: 20),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: dueDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      if (!context.mounted) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(dueDate ?? DateTime.now()),
                      );
                      if (time != null) {
                        setDialogState(() {
                          dueDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  if (task == null) {
                    provider.addTodo(TodoModel(
                      id: const Uuid().v4(),
                      studentId: studentId,
                      title: titleController.text,
                      description: descController.text,
                      priority: priority,
                      category: category,
                      status: TodoStatus.pending,
                      dueDate: dueDate,
                      createdAt: DateTime.now(),
                    ));
                  } else {
                    provider.updateTodo(task.copyWith(
                      title: titleController.text,
                      description: descController.text,
                      priority: priority,
                      category: category,
                      dueDate: dueDate,
                    ));
                  }
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context, TodoModel task, TodoProvider provider) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.deleteTodo(task.id);
              Navigator.pop(context, true);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class BlinkingBadge extends StatefulWidget {
  const BlinkingBadge({super.key});

  @override
  State<BlinkingBadge> createState() => _BlinkingBadgeState();
}

class _BlinkingBadgeState extends State<BlinkingBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'OVERDUE',
          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
