import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/reports/offtheclock_summary_service.dart';

const Color backgroundColor = Color(0xFFF0F0E3);
const Color primaryColor = Color(0xFF53A09D);

class OffTheClockSummaryScreen extends StatefulWidget {
  @override
  State<OffTheClockSummaryScreen> createState() => _OffTheClockSummaryScreenState();
}

class _OffTheClockSummaryScreenState extends State<OffTheClockSummaryScreen> {
  bool _loading = false;
  List<Map<String, dynamic>> _summaries = [];

  List<Map<String, dynamic>> _campuses = [];
  String? _selectedCampusId;

  final OffTheClockSummaryService _service = OffTheClockSummaryService();

  @override
  void initState() {
    super.initState();
    _loadCampuses();
  }

  Future<void> _loadCampuses() async {
    print('OffTheClockSummaryScreen: Loading campuses...');
    final campusSnap = await FirebaseFirestore.instance.collection('campuses').get();
    setState(() {
      _campuses = campusSnap.docs
          .map((doc) => {'id': doc.id, 'name': doc.data()['name'] ?? doc.id})
          .toList();
      _selectedCampusId = null;
    });
    print('OffTheClockSummaryScreen: Loaded ${_campuses.length} campuses');
  }

  Future<void> _loadSummary() async {
    if (_selectedCampusId == null) {
      print('OffTheClockSummaryScreen: Missing campus, aborting load');
      return;
    }
    setState(() {
      _loading = true;
      _summaries = [];
    });
    print('OffTheClockSummaryScreen: Loading offtheclock summary for campus $_selectedCampusId');
    final results = await _service.getOffTheClockSummary(
      campusId: _selectedCampusId!,
    );
    setState(() {
      _summaries = results;
      _loading = false;
    });
    print('OffTheClockSummaryScreen: Loaded ${_summaries.length} teacher summaries');
  }

  Widget _buildCampusDropdown() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedCampusId,
            decoration: InputDecoration(
              labelText: 'Campus',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: _campuses
                .map((c) => DropdownMenuItem<String>(
              value: c['id'],
              child: Text(c['name']),
            ))
                .toList(),
            onChanged: (campusId) {
              setState(() {
                _selectedCampusId = campusId;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadButtonRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: _loading || _selectedCampusId == null
              ? null
              : _loadSummary,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          ),
          child: _loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Cargar'),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> summary) {
    final teacherName = summary['teacherName'] ?? '';
    final totalTrue = summary['totalOffTheClockTrue'] ?? 0;
    final totalFalse = summary['totalOffTheClockFalse'] ?? 0;
    final avgDelayFalse = summary['averageDelayMinutes'] ?? 0;
    final avgDelayTrue = summary['averageOffTheClockDelayMinutes'] ?? 0;

    String delayFalseText = '';
    if (totalFalse > 0) {
      final hours = avgDelayFalse ~/ 60;
      final minutes = avgDelayFalse % 60;
      delayFalseText = 'Retraso promedio EN HORARIO: ';
      if (hours > 0) delayFalseText += '$hours h ';
      delayFalseText += '$minutes min';
    }

    String delayTrueText = '';
    if (totalTrue > 0) {
      final hours = avgDelayTrue ~/ 60;
      final minutes = avgDelayTrue % 60;
      delayTrueText = 'Retraso promedio FUERA DE HORARIO: ';
      if (hours > 0) delayTrueText += '$hours h ';
      delayTrueText += '$minutes min';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(teacherName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryColor)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatusChip('Fuera de horario', totalTrue, true),
                const SizedBox(width: 16),
                _buildStatusChip('En horario', totalFalse, false),
              ],
            ),
            if (delayTrueText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(delayTrueText, style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.bold)),
            ],
            if (delayFalseText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(delayFalseText, style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, int count, bool isOffTheClock) {
    return Chip(
      backgroundColor: isOffTheClock ? Colors.red[100] : Colors.green[100],
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isOffTheClock ? Icons.access_time : Icons.check_circle, color: isOffTheClock ? Colors.red : Colors.green, size: 20),
          const SizedBox(width: 6),
          Text('$label: ', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          Text('$count', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildSummaryList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_summaries.isEmpty) {
      return const Center(child: Text('No hay registros para los filtros seleccionados.'));
    }
    return ListView.builder(
      itemCount: _summaries.length,
      itemBuilder: (context, index) => _buildSummaryCard(_summaries[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Resumen Fuera de Horario'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCampusDropdown(),
            const SizedBox(height: 16),
            _buildLoadButtonRow(),
            const SizedBox(height: 24),
            if (_summaries.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Se encontraron ${_summaries.length} docentes',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 16),
                  ),
                ),
              ),
            Expanded(child: _buildSummaryList()),
          ],
        ),
      ),
    );
  }
}
