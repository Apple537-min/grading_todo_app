import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../models/todo_model.dart';
import 'package:fl_chart/fl_chart.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final todoProvider = Provider.of<TodoProvider>(context);
    final allTodos = todoProvider.todos;
    final completedTodos = allTodos.where((t) => t.status == TodoStatus.completed).toList();

    // 1. Completion Rate
    int onTime = completedTodos.where((t) {
      if (t.dueDate == null || t.completedAt == null) return true;
      return t.completedAt!.isBefore(t.dueDate!) || t.completedAt!.isAtSameMomentAs(t.dueDate!);
    }).length;
    double onTimeRate = completedTodos.isEmpty ? 0 : (onTime / completedTodos.length) * 100;

    // 2. Category Breakdown
    Map<TodoCategory, int> categoryCounts = {};
    for (var task in completedTodos) {
      categoryCounts[task.category] = (categoryCounts[task.category] ?? 0) + 1;
    }

    // 3. Streak Calculation
    int streak = _calculateStreak(completedTodos);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productivity Insights'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStreakCard(context, streak),
            const SizedBox(height: 16),
            _buildCompletionCard(context, onTimeRate, completedTodos.length),
            const SizedBox(height: 16),
            _buildCategoryBreakdownCard(context, categoryCounts),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, int streak) {
    return Card(
      color: Colors.orange.shade700,
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        child: Column(
          children: [
            const Icon(Icons.local_fire_department, color: Colors.white, size: 64),
            const SizedBox(height: 8),
            Text(
              '$streak Day Streak!',
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Keep finishing tasks to maintain your streak.',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionCard(BuildContext context, double rate, int total) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('On-Time Completion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('${rate.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 12,
              child: LinearProgressIndicator(
                value: rate / 100,
                backgroundColor: Colors.teal.withValues(alpha: 0.1),
                color: Colors.teal,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 12),
            Text('You have finished $total tasks in total.', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdownCard(BuildContext context, Map<TodoCategory, int> counts) {
    if (counts.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Focus Areas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: counts.entries.map((e) {
                    return PieChartSectionData(
                      color: e.key.color,
                      value: e.value.toDouble(),
                      title: e.value.toString(),
                      radius: 50,
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    );
                  }).toList(),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: counts.entries.map((e) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 12, height: 12, color: e.key.color),
                    const SizedBox(width: 4),
                    Text(e.key.toString().split('.').last.toUpperCase(), style: const TextStyle(fontSize: 12)),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateStreak(List<TodoModel> completed) {
    if (completed.isEmpty) return 0;

    Set<DateTime> days = completed
        .where((t) => t.completedAt != null)
        .map((t) => DateTime(t.completedAt!.year, t.completedAt!.month, t.completedAt!.day))
        .toSet();

    if (days.isEmpty) return 0;

    days.toList().sort((a, b) => b.compareTo(a));

    DateTime today = DateTime.now();
    DateTime checkDay = DateTime(today.year, today.month, today.day);

    // If today is not in the set, check if yesterday is.
    if (!days.contains(checkDay)) {
      checkDay = checkDay.subtract(const Duration(days: 1));
      if (!days.contains(checkDay)) return 0;
    }

    int streak = 0;
    while (days.contains(checkDay)) {
      streak++;
      checkDay = checkDay.subtract(const Duration(days: 1));
    }

    return streak;
  }
}
