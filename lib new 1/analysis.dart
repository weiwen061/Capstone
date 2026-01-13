import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'performance.dart';

class PerformanceAnalysisPage extends StatefulWidget {
  final String classId;
  const PerformanceAnalysisPage({super.key, required this.classId});

  @override
  State<PerformanceAnalysisPage> createState() =>
      _PerformanceAnalysisPageState();
}

class _PerformanceAnalysisPageState extends State<PerformanceAnalysisPage> {
  String? selectedStudent;
  String? selectedSubjectForTopics;

  String? tooltipTextChart1;
  Offset? tooltipPositionChart1;

  String? tooltipTextChart2;
  Offset? tooltipPositionChart2;

  final List<List<Color>> gradientColors = [
    [Color(0xFF42A5F5), Color(0xFF1E88E5)],
    [Color(0xFF66BB6A), Color(0xFF43A047)],
    [Color(0xFFFFCA28), Color(0xFFF9A825)],
    [Color(0xFFAB47BC), Color(0xFF8E24AA)],
    [Color(0xFFEF5350), Color(0xFFE53935)],
    [Color(0xFF26C6DA), Color(0xFF00ACC1)],
  ];

  final List<String> tpLevels = ['TP1', 'TP2', 'TP3', 'TP4', 'TP5', 'TP6'];

  Map<String, String> studentNames = {};
  Map<String, String> subjectNames = {};

  bool loading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  Future<void> _loadNames() async {
    final students = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('students')
        .get();

    studentNames = {for (var d in students.docs) d.id: d['name'].toString()};

    final subjects =
        await FirebaseFirestore.instance.collection('subjects').get();

    subjectNames = {for (var d in subjects.docs) d.id: d['name'].toString()};

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Student Performance Analysis')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('performance')
            .where('classId', isEqualTo: widget.classId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data!.docs;

          final sortedStudents = studentNames.entries.toList()
            ..sort((a, b) => a.value.compareTo(b.value));

          final displayedStudents = sortedStudents.where((e) =>
              e.value.toLowerCase().contains(searchQuery.toLowerCase())).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search Student',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => searchQuery = v),
                ),
                const SizedBox(height: 10),

                Text('Select Student:',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 5),

                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: ListView.builder(
                    itemCount: displayedStudents.length,
                    itemBuilder: (context, index) {
                      final student = displayedStudents[index];
                      return ListTile(
                        title: Text(student.value),
                        selected: student.key == selectedStudent,
                        onTap: () {
                          setState(() {
                            selectedStudent = student.key;
                            selectedSubjectForTopics = null;
                            tooltipTextChart1 = null;
                            tooltipPositionChart1 = null;
                            tooltipTextChart2 = null;
                            tooltipPositionChart2 = null;
                          });
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 25),
                if (selectedStudent != null) _buildChartsRow(records),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChartsRow(List<QueryDocumentSnapshot> records) {
    final studentRecords = records
        .where((r) => r['studentId'] == selectedStudent)
        .map((r) => r.data() as Map<String, dynamic>)
        .toList();

    final rawSubjectAvg = computeSubjectAverageTP(studentRecords);

    final rawPercent = {
      for (var e in rawSubjectAvg.entries)
        e.key: (e.value / tpLevels.length) * 100
    };

    final total = rawPercent.values.fold(0.0, (a, b) => a + b);

    final subjectAvg = {
      for (var e in rawPercent.entries) e.key: (e.value / total) * 100
    };

    final sectionsChart1 = <PieChartSectionData>[];
    int colorIndex = 0;

    subjectAvg.forEach((subject, percent) {
      sectionsChart1.add(
        PieChartSectionData(
          value: percent,
          title:
              '${subjectNames[subject] ?? subject}\n${percent.toStringAsFixed(1)}%',
          radius: 70,
          gradient: LinearGradient(
            colors: gradientColors[colorIndex % gradientColors.length],
          ),
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    });

    final chart1 = Column(
      children: [
        const Text(
          'Overall Subject Mastery',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),

        Stack(
          children: [
            SizedBox(
              width: 450,
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: sectionsChart1,
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      // ✅ FIX: ONLY tap-up
                      if (event is! FlTapUpEvent) return;
                      if (response?.touchedSection == null) return;

                      final localPos = event.localPosition;
                      final index =
                          response!.touchedSection!.touchedSectionIndex;
                      final key = subjectAvg.keys.elementAt(index);

                      setState(() {
                        tooltipTextChart1 =
                            "${subjectNames[key] ?? key}\n"
                            "${subjectAvg[key]!.toStringAsFixed(1)}%   "
                            "TP ${rawSubjectAvg[key]!.toStringAsFixed(2)}";

                        tooltipPositionChart1 = localPos;
                        selectedSubjectForTopics = key;

                        tooltipTextChart2 = null;
                        tooltipPositionChart2 = null;
                      });
                    },
                  ),
                ),
              ),
            ),

            if (tooltipTextChart1 != null && tooltipPositionChart1 != null)
              Positioned(
                left: tooltipPositionChart1!.dx,
                top: tooltipPositionChart1!.dy - 40,
                child: _buildTooltip(tooltipTextChart1!),
              ),
          ],
        ),
      ],
    );

    final chart2 = selectedSubjectForTopics != null
        ? Column(
            children: [
              Text(
                'Topic Mastery for ${subjectNames[selectedSubjectForTopics] ?? selectedSubjectForTopics}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              SizedBox(
                width: 450,
                height: 250,
                child:
                    _buildTopicPie(records, selectedSubjectForTopics!),
              ),
            ],
          )
        : const SizedBox.shrink();

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          chart1,
          if (selectedSubjectForTopics != null) ...[
            const SizedBox(width: 50),
            chart2,
          ],
        ],
      ),
    );
  }

  Widget _buildTooltip(String text) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(2, 2),
            )
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTopicPie(List<QueryDocumentSnapshot> records, String selectedSubject) {
    final studentRecordsMap = records
        .where((r) =>
            r['studentId'] == selectedStudent && r['subjectId'] == selectedSubject)
        .map((r) => r.data() as Map<String, dynamic>)
        .toList();

    if (studentRecordsMap.isEmpty) return const Center(child: Text('No data'));

    Map<String, List<double>> topicMap = {};
    for (var r in studentRecordsMap) {
      final topic = r['topic'] ?? 'Unknown';
      final level = r['level'] ?? 'TP1';
      final tpNum = tpLevels.indexOf(level) + 1;
      topicMap.putIfAbsent(topic, () => []);
      topicMap[topic]!.add(tpNum.toDouble());
    }

    Map<String, double> topicAvg = {
      for (var e in topicMap.entries)
        e.key: e.value.reduce((a, b) => a + b) / e.value.length
    };

    Map<String, double> topicPercent = {
      for (var e in topicAvg.entries)
        e.key: (e.value / tpLevels.length) * 100
    };

    final totalPercent = topicPercent.values.reduce((a, b) => a + b);
    final topicNormalized = {
      for (var e in topicPercent.entries) e.key: (e.value / totalPercent) * 100
    };

    int colorIndex = 0;
    final sections = topicNormalized.entries.map((e) {
      colorIndex++;
      return PieChartSectionData(
        value: e.value,
        title: '${e.value.toStringAsFixed(1)}%',
        radius: 70,
        gradient: LinearGradient(
          colors: gradientColors[colorIndex % gradientColors.length],
        ),
        titleStyle:
            const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      if (event is! FlTapUpEvent) return;
                      if (response?.touchedSection == null) {
                        setState(() {
                          tooltipTextChart2 = null;
                          tooltipPositionChart2 = null;
                        });
                        return;
                      }

                      final touchedIndex =
                          response!.touchedSection!.touchedSectionIndex;
                      final key = topicNormalized.keys.elementAt(touchedIndex);

                      setState(() {
                        tooltipTextChart2 =
                            "$key: ${topicNormalized[key]!.toStringAsFixed(1)}%  (TP${topicAvg[key]!.toStringAsFixed(2)})";
                        tooltipPositionChart2 = event.localPosition;
                      });
                    },
                  ),
                ),
              ),
              if (tooltipTextChart2 != null && tooltipPositionChart2 != null)
                Positioned(
                  left: tooltipPositionChart2!.dx,
                  top: tooltipPositionChart2!.dy - 40,
                  child: _buildTooltip(tooltipTextChart2!),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
