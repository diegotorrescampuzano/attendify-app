import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../services/reports/pattern_summary_service.dart';

const Color backgroundColor = Color(0xFFF0F0E3);
const Color primaryColor = Color(0xFF53A09D);
const Color secondaryColor = Color(0xFF607D8B);

class PatternSummaryScreen extends StatefulWidget {
  const PatternSummaryScreen({super.key});

  @override
  State<PatternSummaryScreen> createState() => _PatternSummaryScreenState();
}

class _PatternSummaryScreenState extends State<PatternSummaryScreen> {
  final PatternSummaryService _service = PatternSummaryService();

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  late Future<void> _loadFuture;

  Map<String, Map<String, dynamic>> _absencePatterns = {};
  Map<String, Map<String, dynamic>> _studentsMap = {};

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadData();
  }

  Future<void> _loadData() async {
    final students = await _service.fetchAllStudents();
    final studentMap = {for (var s in students) s['refId'] as String: s};

    final homeroomIds = <String>{};
    for (final s in students) {
      final homeroomRef = s['homeroom'];
      if (homeroomRef != null && homeroomRef is DocumentReference<dynamic>) {
        homeroomIds.add(homeroomRef.id);
      }
    }
    final homeroomNames = await _service.fetchHomeroomNames(homeroomIds);

    final absenceDates = await _service.fetchAbsenceDatesPerStudent(
      startDate: _startDate,
      endDate: _endDate,
    );

    final patterns = _service.analyzeAbsencePatterns(absenceDates, studentMap, homeroomNames);

    _studentsMap = studentMap;
    _absencePatterns = patterns;
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: primaryColor,
            onPrimary: Colors.white,
            surface: backgroundColor,
            onSurface: Colors.black87,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        _loadFuture = _loadData();
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: primaryColor,
            onPrimary: Colors.white,
            surface: backgroundColor,
            onSurface: Colors.black87,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
        _loadFuture = _loadData();
      });
    }
  }

  Widget _buildPatternTable() {
    if (_absencePatterns.isEmpty) {
      return const Center(child: Text('No se encontraron patrones de ausencia.'));
    }

    final sortedEntries = _absencePatterns.entries.toList()
      ..sort((a, b) => b.value['maxStreak'].compareTo(a.value['maxStreak']));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(secondaryColor.withOpacity(0.1)),
        columnSpacing: 12,
        columns: [
          DataColumn(
            label: SizedBox(
              width: 150,
              child: const Text(
                'Estudiante',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          DataColumn(
            label: SizedBox(
              width: 120,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('Grupo', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('(Salón)', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          DataColumn(
            numeric: true,
            label: SizedBox(
              width: 80,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('Máxima', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Racha', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          DataColumn(
            numeric: true,
            label: SizedBox(
              width: 80,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Ausencias', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
        rows: sortedEntries.map((entry) {
          final data = entry.value;
          return DataRow(cells: [
            DataCell(
              SizedBox(
                width: 150,
                child: Text(data['name'] ?? 'Desconocido', overflow: TextOverflow.ellipsis),
              ),
            ),
            DataCell(
              SizedBox(
                width: 120,
                child: Text(data['homeroomName'] ?? 'Sin grupo', overflow: TextOverflow.ellipsis),
              ),
            ),
            DataCell(
              SizedBox(
                width: 80,
                child: Text(data['maxStreak'].toString(), textAlign: TextAlign.center),
              ),
            ),
            DataCell(
              SizedBox(
                width: 80,
                child: Text(data['totalAbsences'].toString(), textAlign: TextAlign.center),
              ),
            ),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildVerticalBarChart() {
    if (_absencePatterns.isEmpty) return const SizedBox();

    final sorted = _absencePatterns.entries.toList()
      ..sort((a, b) => b.value['maxStreak'].compareTo(a.value['maxStreak']));
    final topEntries = sorted.take(5).toList();

    return Card(
      margin: const EdgeInsets.only(top: 24),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Top 5 Rachas Máximas de Ausencia',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  maxY: (topEntries.first.value['maxStreak'] as int).toDouble() + 1,
                  barGroups: List.generate(topEntries.length, (index) {
                    final streak = topEntries[index].value['maxStreak'] as int;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: streak.toDouble(),
                          color: primaryColor,
                          width: 22,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 70,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= topEntries.length) return const SizedBox();
                          final name = topEntries[index].value['name'] ?? '';
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Transform.rotate(
                              angle: -1.5708, // -90 degrees in radians
                              child: SizedBox(
                                width: 70,
                                child: Text(
                                  name.length > 10 ? '${name.substring(0, 10)}…' : name,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, interval: 1),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: true, horizontalInterval: 1),
                  borderData: FlBorderData(show: false),
                  backgroundColor: secondaryColor.withOpacity(0.1), // Use secondary color background
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Patrones de Ausencia Continua'),
        backgroundColor: primaryColor,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder(
            future: _loadFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Fecha inicio:', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                              TextButton(
                                onPressed: _pickStartDate,
                                child: Text(DateFormat('dd/MM/yyyy').format(_startDate),
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Fecha fin:', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                              TextButton(
                                onPressed: _pickEndDate,
                                child: Text(DateFormat('dd/MM/yyyy').format(_endDate),
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(child: _buildPatternTable()),
                    _buildVerticalBarChart(),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
