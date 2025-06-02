import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/reports/pattern_summary_service.dart';

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
        headingRowColor: MaterialStateProperty.all(Theme.of(context).colorScheme.primary.withOpacity(0.1)),
        columns: const [
          DataColumn(label: Text('Estudiante')),
          DataColumn(label: Text('Grupo (Homeroom)')),
          DataColumn(label: Text('Máxima Racha Ausente'), numeric: true),
          DataColumn(label: Text('Total Ausencias'), numeric: true),
        ],
        rows: sortedEntries.map((entry) {
          final data = entry.value;
          return DataRow(cells: [
            DataCell(Text(data['name'] ?? 'Desconocido')),
            DataCell(Text(data['homeroomName'] ?? 'Sin grupo')),
            DataCell(Text(data['maxStreak'].toString())),
            DataCell(Text(data['totalAbsences'].toString())),
          ]);
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patrones de Ausencia y Ausencias Continuas'),
        backgroundColor: theme.colorScheme.primary,
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
                              Text('Fecha inicio:', style: theme.textTheme.labelLarge),
                              TextButton(
                                onPressed: _pickStartDate,
                                child: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Fecha fin:', style: theme.textTheme.labelLarge),
                              TextButton(
                                onPressed: _pickEndDate,
                                child: Text(DateFormat('dd/MM/yyyy').format(_endDate)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(child: _buildPatternTable()),
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
