import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/reports/outstanding_register_service.dart';

const Color backgroundColor = Color(0xFFF0F0E3);
const Color primaryColor = Color(0xFF53A09D);

class OutstandingRegisterScreen extends StatefulWidget {
  @override
  State<OutstandingRegisterScreen> createState() => _OutstandingRegisterScreenState();
}

class _OutstandingRegisterScreenState extends State<OutstandingRegisterScreen> {
  bool _loading = false;
  List<Map<String, dynamic>> _outstanding = [];
  List<Map<String, dynamic>> _filteredOutstanding = [];

  List<Map<String, dynamic>> _campuses = [];
  String? _selectedCampusId;

  String? _selectedGradeName;
  String? _selectedTeacherName;

  List<String> _gradeNames = [];
  List<String> _teacherNames = [];

  final OutstandingRegisterService _service = OutstandingRegisterService();

  @override
  void initState() {
    super.initState();
    _loadCampuses();
  }

  Future<void> _loadCampuses() async {
    print('OutstandingRegisterScreen: Loading campuses...');
    final campusSnap = await FirebaseFirestore.instance.collection('campuses').get();
    setState(() {
      _campuses = campusSnap.docs
          .map((doc) => {'id': doc.id, 'name': doc.data()['name'] ?? doc.id})
          .toList();
      _selectedCampusId = null;
    });
    print('OutstandingRegisterScreen: Loaded ${_campuses.length} campuses');
  }

  Future<void> _loadOutstanding() async {
    if (_selectedCampusId == null) {
      print('OutstandingRegisterScreen: Missing campus, aborting load');
      return;
    }
    setState(() {
      _loading = true;
      _outstanding = [];
      _filteredOutstanding = [];
      _selectedGradeName = null;
      _selectedTeacherName = null;
      _gradeNames = [];
      _teacherNames = [];
    });
    print('OutstandingRegisterScreen: Loading outstanding registers for campus $_selectedCampusId for current week (till today)');
    final results = await _service.findOutstandingAttendance(
      campusId: _selectedCampusId!,
    );
    final gradeNames = <String>{};
    final teacherNames = <String>{};
    for (var r in results) {
      if ((r['gradeName'] ?? '').toString().isNotEmpty) gradeNames.add(r['gradeName']);
      if ((r['teacherName'] ?? '').toString().isNotEmpty) teacherNames.add(r['teacherName']);
    }
    print('First outstanding record: ${results.isNotEmpty ? results.first : "none"}');
    setState(() {
      _outstanding = results;
      _filteredOutstanding = List<Map<String, dynamic>>.from(results);
      _gradeNames = gradeNames.toList()..sort();
      _teacherNames = teacherNames.toList()..sort();
      _loading = false;
    });
    print('OutstandingRegisterScreen: Loaded ${_outstanding.length} outstanding records');
  }

  void _applyFilters() {
    setState(() {
      _filteredOutstanding = _outstanding.where((r) {
        final matchesGrade = _selectedGradeName == null || r['gradeName'] == _selectedGradeName;
        final matchesTeacher = _selectedTeacherName == null || r['teacherName'] == _selectedTeacherName;
        return matchesGrade && matchesTeacher;
      }).toList();
    });
  }

  void _clearGradeFilter() {
    setState(() {
      _selectedGradeName = null;
      _applyFilters();
    });
  }

  void _clearTeacherFilter() {
    setState(() {
      _selectedTeacherName = null;
      _applyFilters();
    });
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

  Widget _buildGradeFilterRow() {
    if (_outstanding.isEmpty || _gradeNames.isEmpty) return SizedBox.shrink();
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedGradeName,
            decoration: InputDecoration(
              labelText: 'Filtrar por grado',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon: _selectedGradeName != null
                  ? IconButton(
                icon: Icon(Icons.clear, color: primaryColor),
                onPressed: _clearGradeFilter,
              )
                  : null,
            ),
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text('Todos'),
              ),
              ..._gradeNames.map((g) => DropdownMenuItem<String>(
                value: g,
                child: Text(g),
              ))
            ],
            onChanged: (gradeName) {
              setState(() {
                _selectedGradeName = gradeName;
                _applyFilters();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherFilterRow() {
    if (_outstanding.isEmpty || _teacherNames.isEmpty) return SizedBox.shrink();
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedTeacherName,
            decoration: InputDecoration(
              labelText: 'Filtrar por docente',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon: _selectedTeacherName != null
                  ? IconButton(
                icon: Icon(Icons.clear, color: primaryColor),
                onPressed: _clearTeacherFilter,
              )
                  : null,
            ),
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text('Todos'),
              ),
              ..._teacherNames.map((t) => DropdownMenuItem<String>(
                value: t,
                child: Text(t),
              ))
            ],
            onChanged: (teacherName) {
              setState(() {
                _selectedTeacherName = teacherName;
                _applyFilters();
              });
            },
          ),
        ),
      ],
    );
  }

  void _showTeacherChart(BuildContext context) {
    if (_filteredOutstanding.isEmpty) return;

    final Map<String, int> counts = {};
    for (final r in _filteredOutstanding) {
      final teacher = r['teacherName'] ?? 'Sin docente';
      counts[teacher] = (counts[teacher] ?? 0) + 1;
    }
    final total = counts.values.fold<int>(0, (a, b) => a + b);

    final List<PieChartSectionData> sections = [];
    final List<Color> chartColors = [
      primaryColor,
      Colors.teal,
      Colors.orange,
      Colors.purple,
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.brown,
      Colors.cyan,
      Colors.deepOrange,
      Colors.indigo,
      Colors.lime,
    ];
    int colorIdx = 0;
    counts.forEach((teacher, count) {
      final percent = total == 0 ? 0.0 : count / total * 100;
      sections.add(
        PieChartSectionData(
          color: chartColors[colorIdx % chartColors.length],
          value: count.toDouble(),
          title: '${percent.toStringAsFixed(1)}%',
          radius: 60,
          titleStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
      colorIdx++;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Porcentaje de pendientes por docente', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 320,
          height: 320,
          child: Column(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 40,
                    sectionsSpace: 4,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...counts.entries.map((e) => Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    color: chartColors[_teacherNames.indexOf(e.key) % chartColors.length],
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text('${e.key}', style: TextStyle(fontWeight: FontWeight.bold))),
                  Text('${e.value}', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                ],
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cerrar', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }

  Widget _buildLoadAndChartButtonRow() {
    final enableChart = !_loading && _selectedCampusId != null && _filteredOutstanding.isNotEmpty;
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: enableChart
              ? () => _showTeacherChart(context)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: primaryColor,
            side: BorderSide(color: primaryColor, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          ),
          icon: Icon(Icons.pie_chart, color: primaryColor),
          label: Text('Generar gráfico', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _loading || _selectedCampusId == null
                  ? null
                  : _loadOutstanding,
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
          ),
        ),
      ],
    );
  }

  Widget _buildOutstandingList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_filteredOutstanding.isEmpty) {
      return const Center(child: Text('No hay registros pendientes para los filtros seleccionados.'));
    }
    return ListView.separated(
      itemCount: _filteredOutstanding.length,
      separatorBuilder: (_, __) => Divider(),
      itemBuilder: (context, index) {
        final record = _filteredOutstanding[index];
        final dayName = record['spanishDayName'] ?? '';
        return ListTile(
          tileColor: Colors.white,
          title: Text(
            record['teacherName'] ?? '',
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fecha: ${record['date']}  (${dayName.isNotEmpty ? dayName[0].toUpperCase() + dayName.substring(1) : ''})  Campus: ${record['campusName'] ?? ''}'),
              if ((record['gradeName'] ?? '').isNotEmpty)
                Text('Grado: ${record['gradeName']}'),
              if ((record['subjectName'] ?? '').isNotEmpty)
                Text('Materia: ${record['subjectName']}'),
              if ((record['homeroomName'] ?? '').isNotEmpty)
                Text('Homeroom: ${record['homeroomName']}'),
              if ((record['slot'] ?? '').isNotEmpty)
                Text('Slot: ${record['slot']}'),
              if ((record['time'] ?? '').isNotEmpty)
                Text('Hora: ${record['time']}'),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color(0xFFF44336).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(record['status'] ?? '', style: const TextStyle(color: Color(0xFFF44336), fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Pendientes Semana Actual'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCampusDropdown(),
            const SizedBox(height: 16),
            _buildLoadAndChartButtonRow(),
            const SizedBox(height: 16),
            _buildGradeFilterRow(),
            const SizedBox(height: 16),
            _buildTeacherFilterRow(),
            const SizedBox(height: 24), // More space before result count
            if (_filteredOutstanding.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Se encontraron ${_filteredOutstanding.length} resultados',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 16),
                  ),
                ),
              ),
            Expanded(child: _buildOutstandingList()),
          ],
        ),
      ),
    );
  }
}
