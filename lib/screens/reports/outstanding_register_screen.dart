import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/reports/outstanding_register_service.dart';

class OutstandingRegisterScreen extends StatefulWidget {
  const OutstandingRegisterScreen({Key? key}) : super(key: key);

  @override
  State<OutstandingRegisterScreen> createState() => _OutstandingRegisterScreenState();
}

class _OutstandingRegisterScreenState extends State<OutstandingRegisterScreen> {
  final OutstandingRegisterService _service = OutstandingRegisterService();

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  bool _loading = false;
  List<OutstandingAttendance> _outstanding = [];

  // Maps for ID -> name lookup
  Map<String, String> campusNames = {};
  Map<String, String> teacherNames = {};
  Map<String, String> subjectNames = {};
  Map<String, String> homeroomNames = {};

  // English to Spanish day mapping
  static const Map<String, String> _diasSemana = {
    'Monday': 'Lunes',
    'Tuesday': 'Martes',
    'Wednesday': 'Miércoles',
    'Thursday': 'Jueves',
    'Friday': 'Viernes',
    'Saturday': 'Sábado',
    'Sunday': 'Domingo',
  };

  @override
  void initState() {
    super.initState();
    _preloadNames();
  }

  /// Preload all names for lookups from Firestore.
  Future<void> _preloadNames() async {
    print('Preloading campus, teacher, subject, and homeroom names...');
    final campusSnap = await FirebaseFirestore.instance.collection('campuses').get();
    campusNames = {
      for (var doc in campusSnap.docs)
        doc.id: (doc.data()['name'] ?? doc.id)?.toString() ?? doc.id
    };
    print('Loaded ${campusNames.length} campus names');

    final teacherSnap = await FirebaseFirestore.instance.collection('teachers').get();
    teacherNames = {
      for (var doc in teacherSnap.docs)
        doc.id: (doc.data()['name'] ?? doc.id)?.toString() ?? doc.id
    };
    print('Loaded ${teacherNames.length} teacher names');

    final subjectSnap = await FirebaseFirestore.instance.collection('subjects').get();
    subjectNames = {
      for (var doc in subjectSnap.docs)
        doc.id: (doc.data()['name'] ?? doc.id)?.toString() ?? doc.id
    };
    print('Loaded ${subjectNames.length} subject names');

    final homeroomSnap = await FirebaseFirestore.instance.collection('homerooms').get();
    homeroomNames = {
      for (var doc in homeroomSnap.docs)
        doc.id: (doc.data()['name'] ?? doc.id)?.toString() ?? doc.id
    };
    print('Loaded ${homeroomNames.length} homeroom names');

    setState(() {});
  }

  /// Fetch outstanding records and update state.
  Future<void> _loadOutstanding() async {
    setState(() {
      _loading = true;
    });
    try {
      final results = await _service.findOutstandingAttendance(_startDate, _endDate);
      print('Loaded ${results.length} outstanding attendance records');
      setState(() {
        _outstanding = results;
      });
    } catch (e) {
      print('Error loading outstanding attendance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /// Show date picker for start date.
  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  /// Show date picker for end date.
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
      });
    }
  }

  /// Widget for the green "Libre" label.
  Widget _buildLibreLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Libre',
        style: TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Build the main outstanding table.
  Widget _buildOutstandingTable() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_outstanding.isEmpty) {
      return const Center(child: Text('No se encontraron registros pendientes.'));
    }
    print('Building table with ${_outstanding.length} rows');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 400,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Campus', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Docente', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Día', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Hora', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Bloque', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Materia', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Salón', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: _outstanding.map((item) {
              final campusName = campusNames[item.campus] ?? item.campus;
              final teacherName = teacherNames[item.teacherId] ?? item.teacherId;
              final subjectName = subjectNames[item.subject] ?? '';
              final homeroomName = homeroomNames[item.homeroom] ?? '';
              final dia = _diasSemana[item.day] ?? item.day;

              // Only show "Libre" if BOTH subject and homeroom are missing
              final showLibre = (item.subject.isEmpty || subjectName.isEmpty) &&
                  (item.homeroom.isEmpty || homeroomName.isEmpty);

              print(
                  'Row: $campusName, $teacherName, ${DateFormat('yyyy-MM-dd').format(item.date)}, $dia, ${item.timeRange}, ${item.slotNumber}, $subjectName, $homeroomName, Libre: $showLibre');

              return DataRow(cells: [
                DataCell(Text(campusName)),
                DataCell(Text(teacherName)),
                DataCell(Text(DateFormat('yyyy-MM-dd').format(item.date))),
                DataCell(Text(dia)),
                DataCell(Text(item.timeRange)),
                DataCell(Text(item.slotNumber.toString())),
                DataCell(
                  showLibre
                      ? _buildLibreLabel()
                      : Text(subjectName),
                ),
                DataCell(
                  showLibre
                      ? _buildLibreLabel()
                      : Text(homeroomName),
                ),
              ]);
            }).toList(),
            headingRowColor: MaterialStateColor.resolveWith((states) => Colors.grey[200]!),
            dataRowHeight: 48,
            headingRowHeight: 52,
            columnSpacing: 16,
            showCheckboxColumn: false,
          ),
        ),
      ),
    );
  }

  /// Build the date range picker row.
  Widget _buildDateRangePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: TextButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: Text(
              'Desde: ${DateFormat('yyyy-MM-dd').format(_startDate)}',
              overflow: TextOverflow.ellipsis,
            ),
            onPressed: _pickStartDate,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: Text(
              'Hasta: ${DateFormat('yyyy-MM-dd').format(_endDate)}',
              overflow: TextOverflow.ellipsis,
            ),
            onPressed: _pickEndDate,
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _loading ? null : _loadOutstanding,
          child: const Text('Cargar'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro Pendiente de Asistencia'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDateRangePicker(),
            const SizedBox(height: 16),
            Expanded(child: _buildOutstandingTable()),
          ],
        ),
      ),
    );
  }
}
