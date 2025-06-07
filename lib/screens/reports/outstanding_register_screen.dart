import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../services/reports/outstanding_register_service.dart';

class OutstandingRegisterScreen extends StatefulWidget {
  const OutstandingRegisterScreen({Key? key}) : super(key: key);

  @override
  State<OutstandingRegisterScreen> createState() => _OutstandingRegisterScreenState();
}

class _OutstandingRegisterScreenState extends State<OutstandingRegisterScreen> {
  // Corporate colors
  static const Color backgroundColor = Color(0xFFF0F0E3);
  static const Color primaryColor = Color(0xFF53A09D);

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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: primaryColor,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: primaryColor,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
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

  /// Generate a unique color for each campus, based on its name hash.
  Color _campusColor(String campusId) {
    // Use a fixed list of beautiful colors for up to 10 campuses
    const presetColors = [
      Color(0xFF53A09D), // primaryColor
      Color(0xFF7CB342), // green
      Color(0xFF42A5F5), // blue
      Color(0xFFFBC02D), // yellow
      Color(0xFFEF5350), // red
      Color(0xFFAB47BC), // purple
      Color(0xFFFFA726), // orange
      Color(0xFF8D6E63), // brown
      Color(0xFF26A69A), // teal
      Color(0xFF5C6BC0), // indigo
    ];
    final idx = campusId.hashCode.abs() % presetColors.length;
    return presetColors[idx];
  }

  /// Build the pie chart for outstanding registers per campus.
  Widget _buildCampusPieChart() {
    // Count outstanding per campus
    final campusCounts = <String, int>{};
    for (final item in _outstanding) {
      campusCounts[item.campus] = (campusCounts[item.campus] ?? 0) + 1;
    }
    final total = campusCounts.values.fold<int>(0, (a, b) => a + b);

    print('Pie chart data: $campusCounts, total: $total');

    if (total == 0) {
      return const Center(child: Text('No hay datos para mostrar en el gráfico.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Registros pendientes por campus',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: campusCounts.entries.map((entry) {
                final campusId = entry.key;
                final count = entry.value;
                final percentage = (count / total) * 100;
                final campusName = campusNames[campusId] ?? campusId;
                return PieChartSectionData(
                  color: _campusColor(campusId),
                  value: count.toDouble(),
                  title: '${percentage.toStringAsFixed(1)}%',
                  radius: 55,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  badgeWidget: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        campusName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  badgePositionPercentageOffset: 1.3,
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: campusCounts.keys.map((campusId) {
            final campusName = campusNames[campusId] ?? campusId;
            final count = campusCounts[campusId]!;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: _campusColor(campusId),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$campusName: $count',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            );
          }).toList(),
        ),
      ],
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

  /// Build the date range pickers, each with its own header and icon.
  Widget _buildDateRangeHeaderAndPicker() {
    return Row(
      children: [
        // Desde
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, color: primaryColor, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Desde',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _pickStartDate,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(color: primaryColor, width: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Text(
                  DateFormat('yyyy-MM-dd').format(_startDate),
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Hasta
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, color: primaryColor, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Hasta',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _pickEndDate,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(color: primaryColor, width: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Text(
                  DateFormat('yyyy-MM-dd').format(_endDate),
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _loading ? null : _loadOutstanding,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Cargar'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Registro Pendiente de Asistencia'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDateRangeHeaderAndPicker(),
            const SizedBox(height: 24),
            if (_outstanding.isNotEmpty) _buildCampusPieChart(),
            const SizedBox(height: 24),
            Expanded(child: _buildOutstandingTable()),
          ],
        ),
      ),
    );
  }
}
