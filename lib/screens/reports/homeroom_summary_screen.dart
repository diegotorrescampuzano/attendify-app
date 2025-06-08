import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/reports/homeroom_summary_service.dart';

const Map<String, Map<String, dynamic>> attendanceLabels = {
  'A': {'description': 'Asiste', 'color': 0xFF4CAF50},
  'T': {'description': 'Tarde', 'color': 0xFFFF9800},
  'E': {'description': 'Evasión', 'color': 0xFFF44336},
  'I': {'description': 'Inasistencia', 'color': 0xFF757575},
  'IJ': {'description': 'Inasistencia Justificada', 'color': 0xFF607D8B},
  'P': {'description': 'Retiro con acudiente', 'color': 0xFF9C27B0},
};

class HomeroomSummaryScreen extends StatefulWidget {
  const HomeroomSummaryScreen({Key? key}) : super(key: key);

  @override
  State<HomeroomSummaryScreen> createState() => _HomeroomSummaryScreenState();
}

class _HomeroomSummaryScreenState extends State<HomeroomSummaryScreen> {
  static const Color backgroundColor = Color(0xFFF0F0E3);
  static const Color primaryColor = Color(0xFF53A09D);

  final HomeroomSummaryService _service = HomeroomSummaryService();

  List<Map<String, dynamic>> _campuses = [];
  String? _selectedCampusId;

  List<Map<String, dynamic>> _homerooms = [];
  List<String> _selectedHomeroomIds = [];

  List<String> _attendanceTypes = [];
  List<String> _selectedAttendanceTypes = [];

  List<Map<String, dynamic>> _attendanceSummary = [];
  bool _loading = false;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadCampuses();
    _loadAttendanceTypes();
  }

  Future<void> _loadCampuses() async {
    setState(() => _loading = true);
    _campuses = await _service.fetchCampuses();
    setState(() => _loading = false);
  }

  Future<void> _loadHomerooms() async {
    if (_selectedCampusId == null) return;
    setState(() => _loading = true);
    _homerooms = await _service.fetchHomerooms(campusId: _selectedCampusId!);
    setState(() => _loading = false);
  }

  Future<void> _loadAttendanceTypes() async {
    _attendanceTypes = attendanceLabels.keys.toList();
    setState(() {});
  }

  Future<void> _loadAttendanceSummary() async {
    if (_selectedHomeroomIds.isEmpty || _selectedAttendanceTypes.isEmpty) return;
    setState(() => _loading = true);
    _attendanceSummary = await _service.fetchAttendanceSummary(
      homeroomIds: _selectedHomeroomIds,
      attendanceTypes: _selectedAttendanceTypes,
      startDate: _startDate,
      endDate: _endDate,
    );
    setState(() => _loading = false);
  }

  Future<void> _pickStartDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: _endDate,
      locale: const Locale('es', 'ES'),
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

  Future<void> _pickEndDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _showHomeroomMultiSelect() async {
    if (_homerooms.isEmpty) return;
    final selected = Set<String>.from(_selectedHomeroomIds);

    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _homerooms.length,
                  itemBuilder: (context, index) {
                    final homeroom = _homerooms[index];
                    final isSelected = selected.contains(homeroom['id']);
                    return ListTile(
                      onTap: () {
                        if (isSelected) {
                          selected.remove(homeroom['id']);
                        } else {
                          selected.add(homeroom['id']);
                        }
                        Navigator.of(context).pop(Set<String>.from(selected));
                      },
                      leading: Checkbox(
                        value: isSelected,
                        onChanged: (checked) {
                          if (checked == true) {
                            selected.add(homeroom['id']);
                          } else {
                            selected.remove(homeroom['id']);
                          }
                          Navigator.of(context).pop(Set<String>.from(selected));
                        },
                      ),
                      title: Text(homeroom['name'] ?? homeroom['id']),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
    if (result != null) {
      setState(() {
        _selectedHomeroomIds = result.toList();
        _attendanceSummary = [];
      });
    }
  }

  Future<void> _showAttendanceTypeMultiSelect() async {
    if (_attendanceTypes.isEmpty) return;
    final selected = Set<String>.from(_selectedAttendanceTypes);

    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _attendanceTypes.length,
                  itemBuilder: (context, index) {
                    final type = _attendanceTypes[index];
                    final isSelected = selected.contains(type);
                    final color = Color(attendanceLabels[type]?['color'] ?? 0xFF757575);
                    final description = attendanceLabels[type]?['description'] ?? type;
                    return ListTile(
                      onTap: () {
                        if (isSelected) {
                          selected.remove(type);
                        } else {
                          selected.add(type);
                        }
                        Navigator.of(context).pop(Set<String>.from(selected));
                      },
                      leading: Checkbox(
                        value: isSelected,
                        onChanged: (checked) {
                          if (checked == true) {
                            selected.add(type);
                          } else {
                            selected.remove(type);
                          }
                          Navigator.of(context).pop(Set<String>.from(selected));
                        },
                        activeColor: color,
                      ),
                      title: Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(description),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
    if (result != null) {
      setState(() {
        _selectedAttendanceTypes = result.toList();
        _attendanceSummary = [];
      });
    }
  }

  Widget _buildMultiSelectButton({
    required String label,
    required String emptyText,
    required String selectedText,
    required VoidCallback onTap,
    required bool enabled,
    Color? dropdownColor,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.list, color: Colors.grey),
            const SizedBox(width: 10),
            Expanded(
              child: selectedText.isEmpty
                  ? Text(
                emptyText,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                overflow: TextOverflow.ellipsis,
              )
                  : Wrap(
                spacing: 8,
                runSpacing: 4,
                children: selectedText
                    .split(', ')
                    .map((label) => Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ))
                    .toList(),
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  String _formatSimpleDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Widget _buildTable() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_attendanceSummary.isEmpty) return const Text('No hay datos para mostrar.');

    final uniqueTypes = _selectedAttendanceTypes.length == 1;

    if (uniqueTypes) {
      final columns = ['Estudiante', 'Homeroom', 'Tipo', 'Total', 'Detalles'];
      // Group by student/homeroom/type
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final record in _attendanceSummary) {
        final key = '${record['studentName']}|${record['homeroomName']}|${record['label']}';
        grouped.putIfAbsent(key, () => []).add(record);
      }

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: columns
              .map((c) => DataColumn(
              label: Text(
                c,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFF53A09D)),
              )))
              .toList(),
          rows: grouped.entries.map((entry) {
            final first = entry.value.first;
            final total = entry.value.length;
            final details = entry.value
                .map((rec) {
              String formattedDate = '';
              DateTime? dt;
              if (rec['date'] is Timestamp) {
                dt = (rec['date'] as Timestamp).toDate();
              } else if (rec['date'] is DateTime) {
                dt = rec['date'];
              } else if (rec['date'] is String) {
                try {
                  dt = DateTime.parse(rec['date']);
                } catch (_) {}
              }
              if (dt != null) {
                formattedDate = _formatSimpleDate(dt);
              }
              final teacher = rec['teacherName'] ?? '';
              final subject = rec['subjectName'] ?? '';
              final slot = rec['slot'] ?? '';
              return [
                if (formattedDate.isNotEmpty) formattedDate,
                if (teacher.isNotEmpty) teacher,
                if (subject.isNotEmpty) subject,
                if (slot.toString().isNotEmpty) 'S$slot',
              ].join(' - ');
            })
                .join(', ');
            return DataRow(cells: [
              DataCell(Text(first['studentName'] ?? '')),
              DataCell(Text(first['homeroomName'] ?? '')),
              DataCell(
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: Color(attendanceLabels[first['label']]?['color'] ?? 0xFF757575),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(attendanceLabels[first['label']]?['description'] ?? first['label']),
                  ],
                ),
              ),
              DataCell(Text(total.toString())),
              DataCell(Text(details)),
            ]);
          }).toList(),
        ),
      );
    } else {
      // MULTI-TYPE: dynamic type columns
      final typeList = _selectedAttendanceTypes;
      final columns = [
        DataColumn(
            label: Text('Estudiante',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFF53A09D)))),
        DataColumn(
            label: Text('Homeroom',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFF53A09D)))),
        ...typeList.map((type) => DataColumn(
          label: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Color(attendanceLabels[type]?['color'] ?? 0xFF757575),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              attendanceLabels[type]?['description'] ?? type,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        )),
        DataColumn(
            label: Text('Total',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFF53A09D)))),
      ];

      // Group by student/homeroom
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final record in _attendanceSummary) {
        final key = '${record['studentName']}|${record['homeroomName']}';
        grouped.putIfAbsent(key, () => []).add(record);
      }

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: columns,
          rows: grouped.entries.map((entry) {
            final first = entry.value.first;
            final List<int> counts = typeList.map((type) {
              return entry.value.where((rec) => rec['label'] == type).length;
            }).toList();
            final List<DataCell> typeCells = counts.map((count) {
              return DataCell(Text(count.toString()));
            }).toList();
            final int total = counts.fold(0, (sum, c) => sum + c);

            return DataRow(cells: [
              DataCell(Text(first['studentName'] ?? '')),
              DataCell(Text(first['homeroomName'] ?? '')),
              ...typeCells,
              DataCell(Text(total.toString())),
            ]);
          }).toList(),
        ),
      );
    }
  }

  void _showChartDialog() {
    if (_attendanceSummary.isEmpty) return;

    // Prepare data: {homeroomName: {type: total, ...}, ...}
    final Map<String, Map<String, int>> chartData = {};
    for (final record in _attendanceSummary) {
      final homeroom = record['homeroomName'] ?? record['homeroomId'];
      final type = record['label'];
      chartData.putIfAbsent(homeroom, () => {});
      chartData[homeroom]![type] = (chartData[homeroom]![type] ?? 0) + 1;
    }
    final homerooms = chartData.keys.toList();
    final types = _selectedAttendanceTypes;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Gráfico por Homeroom'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.95,
            height: 400,
            child: BarChart(
              BarChartData(
                barGroups: List.generate(homerooms.length, (i) {
                  final homeroom = homerooms[i];
                  return BarChartGroupData(
                    x: i,
                    barRods: List.generate(types.length, (j) {
                      final type = types[j];
                      return BarChartRodData(
                        toY: (chartData[homeroom]?[type] ?? 0).toDouble(),
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                        color: Color(attendanceLabels[type]?['color'] ?? 0xFF757575),
                      );
                    }),
                  );
                }),
                groupsSpace: 24,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= homerooms.length) return Container();
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            homerooms[index],
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                      reservedSize: 80,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                alignment: BarChartAlignment.center,
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: false),
                maxY: _getMaxY(chartData, types) * 1.2,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  double _getMaxY(Map<String, Map<String, int>> chartData, List<String> types) {
    double maxY = 0;
    for (final data in chartData.values) {
      for (final type in types) {
        if ((data[type] ?? 0) > maxY) {
          maxY = (data[type] ?? 0).toDouble();
        }
      }
    }
    return maxY < 5 ? 5 : maxY;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Resumen por Homeroom'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Date range pickers
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fecha inicio:', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
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
                      Text('Fecha fin:', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: _pickEndDate,
                        child: Text(DateFormat('dd/MM/yyyy').format(_endDate)),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
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
              onChanged: (campusId) async {
                setState(() {
                  _selectedCampusId = campusId;
                  _selectedHomeroomIds = [];
                  _homerooms = [];
                  _attendanceSummary = [];
                  _selectedAttendanceTypes = [];
                });
                await _loadHomerooms();
              },
            ),
            const SizedBox(height: 12),
            if (_homerooms.isNotEmpty)
              _buildMultiSelectButton(
                label: 'Homerooms',
                emptyText: 'Seleccionar Homerooms',
                selectedText: _homerooms
                    .where((h) => _selectedHomeroomIds.contains(h['id']))
                    .map((h) => h['name'] ?? h['id'])
                    .join(', '),
                onTap: _showHomeroomMultiSelect,
                enabled: true,
              ),
            if (_selectedHomeroomIds.isNotEmpty && _attendanceTypes.isNotEmpty)
              _buildMultiSelectButton(
                label: 'Tipos de asistencia',
                emptyText: 'Seleccionar tipos de asistencia',
                selectedText: _selectedAttendanceTypes.map((type) {
                  final color = Color(attendanceLabels[type]?['color'] ?? 0xFF757575);
                  final description = attendanceLabels[type]?['description'] ?? type;
                  return '\u25CF $description';
                }).join(', '),
                onTap: _showAttendanceTypeMultiSelect,
                enabled: true,
              ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: (_selectedHomeroomIds.isNotEmpty &&
                  _selectedAttendanceTypes.isNotEmpty)
                  ? _loadAttendanceSummary
                  : null,
              child: const Text('Generar Resumen'),
            ),
            const SizedBox(height: 24),
            Expanded(child: _buildTable()),
            if (_attendanceSummary.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.bar_chart),
                  label: const Text('Generar gráfico'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _showChartDialog,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
