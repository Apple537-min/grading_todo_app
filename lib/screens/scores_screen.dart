import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/grade_provider.dart';
import '../models/grade_model.dart';
import 'package:fl_chart/fl_chart.dart';

class ScoresScreen extends StatefulWidget {
  const ScoresScreen({super.key});

  @override
  State<ScoresScreen> createState() => _ScoresScreenState();
}

class _ScoresScreenState extends State<ScoresScreen> {
  String? _selectedSubjectCode;

  @override
  Widget build(BuildContext context) {
    final gradeProvider = Provider.of<GradeProvider>(context);
    final subjectCodes = gradeProvider.summary.uniqueSubjectCodes;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Academic Performance'),
          elevation: 2,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: Column(
              children: [
                _buildSubjectFilter(subjectCodes),
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(text: 'Quiz', icon: Icon(Icons.quiz_outlined)),
                    Tab(text: 'Exam', icon: Icon(Icons.assignment_outlined)),
                    Tab(text: 'Activity', icon: Icon(Icons.task_alt)),
                    Tab(text: 'Oral', icon: Icon(Icons.record_voice_over)),
                    Tab(text: 'Project', icon: Icon(Icons.account_tree_outlined)),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            ScoreCategoryList(type: AssessmentType.quiz, subjectCode: _selectedSubjectCode),
            ScoreCategoryList(type: AssessmentType.exam, subjectCode: _selectedSubjectCode),
            ScoreCategoryList(type: AssessmentType.activity, subjectCode: _selectedSubjectCode),
            ScoreCategoryList(type: AssessmentType.oral, subjectCode: _selectedSubjectCode),
            ScoreCategoryList(type: AssessmentType.project, subjectCode: _selectedSubjectCode),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectFilter(List<String> codes) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All Subjects'),
            selected: _selectedSubjectCode == null,
            onSelected: (val) => setState(() => _selectedSubjectCode = null),
          ),
          ...codes.map((code) => Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: ChoiceChip(
                  label: Text(code),
                  selected: _selectedSubjectCode == code,
                  onSelected: (val) => setState(() => _selectedSubjectCode = val ? code : null),
                ),
              )),
        ],
      ),
    );
  }
}

class ScoreCategoryList extends StatelessWidget {
  final AssessmentType type;
  final String? subjectCode;

  const ScoreCategoryList({super.key, required this.type, this.subjectCode});

  @override
  Widget build(BuildContext context) {
    final gradeProvider = Provider.of<GradeProvider>(context);
    var assessments = gradeProvider.assessments.where((a) => a.type == type).toList();
    if (subjectCode != null) {
      assessments = assessments.where((a) => a.subjectCode == subjectCode).toList();
    }
    
    final average = gradeProvider.summary.calculateAverage(type, subjectCode: subjectCode);

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSummaryHeader(context, average),
          if (assessments.isNotEmpty) ...[
            _buildChartSection(context, assessments),
            const Divider(),
            _buildScoreList(context, assessments),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: Text('No records found for this selection.')),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(BuildContext context, double average) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        border: const Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Column(
        children: [
          Text(
            subjectCode == null ? 'Overall Category Average' : '$subjectCode Average',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            '${average.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(BuildContext context, List<AssessmentModel> items) {
    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.only(top: 24, right: 24, left: 16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barTouchData: BarTouchData(enabled: true),
          titlesData: const FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          barGroups: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final percentage = (item.score / item.totalItems) * 100;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: percentage,
                  color: percentage >= 75 ? Theme.of(context).colorScheme.primary : Colors.orange,
                  width: 16,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildScoreList(BuildContext context, List<AssessmentModel> items) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final perc = (item.score / item.totalItems) * 100;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: (perc >= 75 ? Theme.of(context).colorScheme.primary : Colors.orange).withValues(alpha: 0.1),
            child: Text('${index + 1}', style: TextStyle(color: perc >= 75 ? Theme.of(context).colorScheme.primary : Colors.orange)),
          ),
          title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${item.subjectName} • ${item.term}'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${item.score} / ${item.totalItems}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('${perc.toStringAsFixed(1)}%', style: TextStyle(color: perc >= 75 ? Colors.green : Colors.orange, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }
}
