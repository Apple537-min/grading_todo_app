import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/grade_provider.dart';
import '../models/attendance_model.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final gradeProvider = Provider.of<GradeProvider>(context);
    final attendance = gradeProvider.attendance;
    final summary = gradeProvider.attendanceSummary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Records'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSummaryHeader(context, summary),
          _buildCalendarSection(attendance),
          const Divider(height: 1),
          Expanded(
            child: _buildDetailsList(attendance),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(BuildContext context, Map<AttendanceStatus, int> summary) {
    int total = summary.values.fold(0, (a, b) => a + b);
    double rate = total == 0 ? 100 : (summary[AttendanceStatus.present]! / total) * 100;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${rate.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Text('Overall Attendance Rate', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
          Row(
            children: [
              _buildMiniIndicator('P', summary[AttendanceStatus.present].toString(), Colors.green),
              const SizedBox(width: 12),
              _buildMiniIndicator('A', summary[AttendanceStatus.absent].toString(), Colors.red),
              const SizedBox(width: 12),
              _buildMiniIndicator('L', summary[AttendanceStatus.late].toString(), Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniIndicator(String label, String count, Color color) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCalendarSection(List<AttendanceModel> history) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: TableCalendar(
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now().add(const Duration(days: 30)),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        eventLoader: (day) {
          return history.where((a) => isSameDay(a.date, day)).toList();
        },
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isEmpty) return null;
            final event = events.first as AttendanceModel;
            return Positioned(
              bottom: 4,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getStatusColor(event.status),
                ),
              ),
            );
          },
          todayBuilder: (context, day, focusedDay) => _buildDayBuilder(day, Colors.grey.shade200, Colors.black),
          selectedBuilder: (context, day, focusedDay) => _buildDayBuilder(day, Theme.of(context).colorScheme.primary, Colors.white),
        ),
      ),
    );
  }

  Widget _buildDayBuilder(DateTime day, Color bg, Color text) {
    return Center(
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text('${day.day}', style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }

  Widget _buildDetailsList(List<AttendanceModel> history) {
    final filtered = history.where((a) => isSameDay(a.date, _selectedDay)).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('No records for this day', style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final record = filtered[index];
        final color = _getStatusColor(record.status);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withValues(alpha: 0.2)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              radius: 18,
              child: Icon(Icons.check_circle_outline, color: color, size: 20),
            ),
            title: Text(
              record.status.toString().split('.').last.toUpperCase(),
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(DateFormat('EEEE, MMMM d, yyyy').format(record.date)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
        );
      },
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present: return Colors.green;
      case AttendanceStatus.absent: return Colors.red;
      case AttendanceStatus.late: return Colors.orange;
    }
  }
}
