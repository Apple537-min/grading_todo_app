import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/grade_provider.dart';
import '../providers/todo_provider.dart';
import '../models/attendance_model.dart';
import '../models/todo_model.dart';
import 'profile_screen.dart';
import 'stats_screen.dart';
import 'attendance_screen.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final gradeProvider = Provider.of<GradeProvider>(context);
    final todoProvider = Provider.of<TodoProvider>(context);
    
    final student = authProvider.currentStudent;
    final attSummary = gradeProvider.attendanceSummary;
    
    // Filter tasks for the selected date on the mini-calendar
    final dailyTasks = todoProvider.todos.where((task) {
      if (task.dueDate == null) return false;
      return task.dueDate!.year == _selectedDate.year &&
             task.dueDate!.month == _selectedDate.month &&
             task.dueDate!.day == _selectedDate.day;
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Portal Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StatsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, student?.name ?? 'Scholar'),
              const SizedBox(height: 24),
              
              _buildMiniCalendar(context),
              const SizedBox(height: 32),
              
              _buildSectionHeader(context, 'Academic Goals', () {}),
              const SizedBox(height: 16),
              _buildUpcomingTasks(context, dailyTasks),
              const SizedBox(height: 32),

              _buildSectionHeader(context, 'Attendance Health', () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AttendanceScreen()));
              }),
              const SizedBox(height: 16),
              _buildAttendanceOverview(context, attSummary),
              const SizedBox(height: 32),

              _buildSectionHeader(context, 'Academic Performance', () {}),
              const SizedBox(height: 16),
              _buildProjectedGrade(context, gradeProvider),
              const SizedBox(height: 16),
              _buildTermOverview(context, gradeProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
        ),
        TextButton(onPressed: onTap, child: const Text('View All')),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, String name) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withBlue(150)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'S',
              style: TextStyle(fontSize: 24, color: colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back,', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCalendar(BuildContext context) {
    final today = DateTime.now();
    final weekDays = List.generate(7, (i) => today.add(Duration(days: i - today.weekday + 1)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('MMMM yyyy').format(_selectedDate),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Icon(Icons.calendar_today_rounded, size: 18, color: Colors.grey),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: weekDays.length,
            itemBuilder: (context, index) {
              final day = weekDays[index];
              final isSelected = DateFormat('yyyyMMdd').format(day) == DateFormat('yyyyMMdd').format(_selectedDate);
              final isToday = DateFormat('yyyyMMdd').format(day) == DateFormat('yyyyMMdd').format(today);

              return GestureDetector(
                onTap: () => setState(() => _selectedDate = day),
                child: Container(
                  width: 55,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).colorScheme.primary : (isToday ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent),
                    borderRadius: BorderRadius.circular(16),
                    border: isToday && !isSelected ? Border.all(color: Theme.of(context).colorScheme.primary) : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('E').format(day)[0],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('d').format(day),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingTasks(BuildContext context, List<TodoModel> tasks) {
    if (tasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: const Row(
          children: [
            Icon(Icons.event_available, color: Colors.grey),
            SizedBox(width: 12),
            Text('No goals for this day.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Container(
            width: 250,
            margin: const EdgeInsets.only(right: 12),
            child: Card(
              color: task.isOverdue ? Colors.red.shade50 : null,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: task.priorityColor, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 16, color: task.isOverdue ? Colors.red : Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          task.countdownText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: task.isOverdue ? Colors.red : Colors.teal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${task.subjectCode} • ${task.title}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: task.priorityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        task.priority.toString().split('.').last.toUpperCase(),
                        style: TextStyle(color: task.priorityColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAttendanceOverview(BuildContext context, Map<AttendanceStatus, int> summary) {
    int total = summary.values.fold(0, (a, b) => a + b);
    double presentRate = total == 0 ? 100 : (summary[AttendanceStatus.present]! / total) * 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${presentRate.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: presentRate > 80 ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Text('Monthly Attendance Rate', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniStat('P', summary[AttendanceStatus.present].toString(), Colors.green),
                  _buildMiniStat('A', summary[AttendanceStatus.absent].toString(), Colors.red),
                  _buildMiniStat('L', summary[AttendanceStatus.late].toString(), Colors.orange),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildProjectedGrade(BuildContext context, GradeProvider provider) {
    final grade = provider.summary.calculateWeightedFinalGrade();
    final color = grade >= 75 ? Colors.teal : Colors.orange;

    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Projected Standing',
                  style: TextStyle(color: color.withValues(alpha: 0.8), fontWeight: FontWeight.bold),
                ),
                Text('Overall Weighted Grade', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            const Spacer(),
            Text(
              '${grade.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color, letterSpacing: -1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermOverview(BuildContext context, GradeProvider provider) {
    return Column(
      children: [
        _buildTermCard(context, 'Prelim', provider),
        _buildTermCard(context, 'Midterm', provider),
        _buildTermCard(context, 'Finals', provider),
      ],
    );
  }

  Widget _buildTermCard(BuildContext context, String term, GradeProvider provider) {
    final examScore = provider.summary.calculateExamScore(term);
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(term, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: LinearProgressIndicator(
          value: examScore / 100,
          backgroundColor: Colors.grey[200],
          color: examScore >= 75 ? Colors.teal : Colors.orange,
        ),
        trailing: Text('${examScore.toStringAsFixed(0)}%'),
      ),
    );
  }
}
