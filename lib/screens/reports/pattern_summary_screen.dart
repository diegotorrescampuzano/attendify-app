import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/reports/pattern_summary_service.dart';

const Color backgroundColor = Color(0xFFF0F0E3);
const Color primaryColor = Color(0xFF53A09D);

const Map<String, Map<String, dynamic>> attendanceLabels = {
  'A': {'description': 'Asiste', 'color': 0xFF4CAF50},
  'T': {'description': 'Tarde', 'color': 0xFFFF9800},
  'E': {'description': 'Evasión', 'color': 0xFFF44336},
  'I': {'description': 'Inasistencia', 'color': 0xFF757575},
  'IJ': {'description': 'Inasistencia Justificada', 'color': 0xFF607D8B},
  'P': {'description': 'Retiro con acudiente', 'color': 0xFF9C27B0},
};

class PatternSummaryScreen extends StatefulWidget {
  const PatternSummaryScreen({Key? key}) : super(key: key);

  @override
  State<PatternSummaryScreen> createState() => _PatternSummaryScreenState();
}

class _PatternSummaryScreenState extends State<PatternSummaryScreen> {
  final PatternSummaryService _service = PatternSummaryService();
  List<Map<String, dynamic>> _campuses = [];
  String? _selectedCampusId;
  List<Map<String, dynamic>> _patternSummary = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCampuses();
  }

  Future<void> _loadCampuses() async {
    setState(() => _loading = true);
    final campuses = await _service.fetchCampuses();
    setState(() {
      _campuses = campuses;
      _loading = false;
    });
  }

  Future<void> _loadPatternSummary() async {
    if (_selectedCampusId == null) return;
    setState(() => _loading = true);
    final summary = await _service.fetchPatternSummaryForCampus(_selectedCampusId!);
    setState(() {
      _patternSummary = summary;
      _loading = false;
    });
  }

  Widget _buildCampusDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCampusId,
      items: _campuses.map<DropdownMenuItem<String>>((campus) {
        return DropdownMenuItem<String>(
          value: campus['id'],
          child: Text(campus['name'] ?? ''),
        );
      }).toList(),
      decoration: InputDecoration(
        labelText: 'Selecciona un campus',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onChanged: (String? value) {
        setState(() {
          _selectedCampusId = value;
          _patternSummary = [];
        });
      },
    );
  }

  Widget _buildPatternTable() {
    if (_patternSummary.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Text('No se encontraron patrones de asistencia diferentes a "Asiste" esta semana.'),
      );
    }
    return Expanded(
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(primaryColor.withOpacity(0.1)),
              columns: [
                const DataColumn(label: Text('Estudiante')),
                const DataColumn(label: Text('Grupo')),
                ...attendanceLabels.entries
                    .where((e) => e.key != 'A')
                    .map((e) => DataColumn(label: Text(e.value['description']))),
              ],
              rows: _patternSummary.map((student) {
                final patterns = student['patterns'] as Map<String, int>;
                return DataRow(cells: [
                  DataCell(Text(
                    student['studentName'] ?? '',
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                  )),
                  DataCell(Text(student['homeroomName'] ?? '')),
                  ...attendanceLabels.entries
                      .where((e) => e.key != 'A')
                      .map((e) => DataCell(
                    patterns.containsKey(e.key)
                        ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(e.value['color']).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        patterns[e.key].toString(),
                        style: TextStyle(
                          color: Color(e.value['color']),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                        : const SizedBox.shrink(),
                  )),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartLegend(Map<String, int> totalPatterns) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: attendanceLabels.entries
          .where((e) => e.key != 'A')
          .map((e) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Color(e.value['color']),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${e.value['description']}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 8),
            Text(
              '(${totalPatterns[e.key] ?? 0})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ))
          .toList(),
    );
  }

  Widget _buildChartButton() {
    if (_patternSummary.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.pie_chart),
        label: const Text('Ver gráfico de patrones'),
        onPressed: () => _showPatternChart(),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  void _showPatternChart() {
    // Aggregate all patterns by label
    final Map<String, int> totalPatterns = {};
    for (final student in _patternSummary) {
      final patterns = student['patterns'] as Map<String, int>;
      patterns.forEach((label, count) {
        totalPatterns[label] = (totalPatterns[label] ?? 0) + count;
      });
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Distribución de patrones de asistencia',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    sections: attendanceLabels.entries
                        .where((e) => e.key != 'A')
                        .map((e) {
                      final count = totalPatterns[e.key] ?? 0;
                      final total = totalPatterns.values.fold(0, (p, v) => p + v);
                      final percent = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0';
                      return PieChartSectionData(
                        color: Color(e.value['color']),
                        value: count.toDouble(),
                        title: '$percent%',
                        radius: 60,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildChartLegend(totalPatterns),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cerrar', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weekStart = DateFormat('dd/MM/yyyy').format(_service.getFirstDayOfWeek());
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Resumen de patrones de asistencia'),
        backgroundColor: primaryColor,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Semana actual: $weekStart - $today',
              style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
            ),
            const SizedBox(height: 16),
            _buildCampusDropdown(),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Buscar patrones'),
              onPressed: _selectedCampusId == null ? null : _loadPatternSummary,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildPatternTable(),
            _buildChartButton(),
          ],
        ),
      ),
    );
  }
}
