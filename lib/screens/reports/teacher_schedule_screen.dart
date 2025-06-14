import 'package:flutter/material.dart';
import '../../../services/reports/teacher_schedule_service.dart';

const Color backgroundColor = Color(0xFFF0F0E3);
const Color primaryColor = Color(0xFF53A09D);

const List<String> days = [
  'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
];
const Map<String, String> daysEs = {
  'monday': 'Lunes',
  'tuesday': 'Martes',
  'wednesday': 'Miércoles',
  'thursday': 'Jueves',
  'friday': 'Viernes',
  'saturday': 'Sábado',
  'sunday': 'Domingo',
};
const List<String> slotTimes = [
  '07:00-08:00',
  '08:00-09:00',
  '09:00-10:00',
  '10:00-11:00',
  '11:00-12:00',
  '12:00-13:00',
  '13:00-14:00',
  '14:00-15:00',
];

class TeacherScheduleScreen extends StatefulWidget {
  const TeacherScheduleScreen({Key? key}) : super(key: key);

  @override
  State<TeacherScheduleScreen> createState() => _TeacherScheduleScreenState();
}

class _TeacherScheduleScreenState extends State<TeacherScheduleScreen> {
  final TeacherScheduleService _service = TeacherScheduleService();

  List<Map<String, dynamic>> _campuses = [];
  String? _selectedCampusId;
  List<Map<String, dynamic>> _teachers = [];
  String? _selectedTeacherId;

  Map<String, Map<int, Map<String, String>>> _schedule = {};
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
      _selectedCampusId = null;
      _teachers = [];
      _selectedTeacherId = null;
      _schedule = {};
      _loading = false;
    });
  }

  Future<void> _loadTeachers() async {
    if (_selectedCampusId == null) return;
    setState(() => _loading = true);
    final teachers = await _service.fetchTeachers(campusId: _selectedCampusId!);
    setState(() {
      _teachers = teachers;
      _selectedTeacherId = null;
      _schedule = {};
      _loading = false;
    });
  }

  Future<void> _loadSchedule() async {
    if (_selectedTeacherId == null || _selectedCampusId == null) return;
    setState(() => _loading = true);
    final schedule = await _service.fetchTeacherSchedule(
      teacherId: _selectedTeacherId!,
      campusId: _selectedCampusId!,
    );
    setState(() {
      _schedule = schedule;
      _loading = false;
    });
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<Map<String, dynamic>> items,
    required String valueKey,
    required String labelKey,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items.map<DropdownMenuItem<T>>((item) {
        return DropdownMenuItem<T>(
          value: item[valueKey],
          child: Text(item[labelKey] ?? ''),
        );
      }).toList(),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildScheduleTable() {
    if (_schedule.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Text('No hay horario para mostrar.'),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(primaryColor.withOpacity(0.1)),
          columns: [
            const DataColumn(label: Text('Slot/Hora')),
            ...days.map((d) => DataColumn(label: Text(daysEs[d]!))),
          ],
          rows: List<DataRow>.generate(8, (slotIdx) {
            final slotNum = slotIdx + 1;
            return DataRow(
              cells: [
                DataCell(Text('S$slotNum\n${slotTimes[slotIdx]}')),
                ...days.map((day) {
                  final info = _schedule[day]?[slotNum];
                  final subject = info?['subject'] ?? 'Libre';
                  final homeroom = info?['homeroom'] ?? '';
                  final isLibre = subject == 'Libre' || subject.isEmpty;
                  return DataCell(Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isLibre
                          ? Colors.grey.withOpacity(0.13)
                          : primaryColor.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          subject,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isLibre ? Colors.grey : primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (homeroom.isNotEmpty && !isLibre)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              homeroom,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ));
                }).toList(),
              ],
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Horario semanal del docente'),
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
            _buildDropdown<String>(
              label: 'Campus',
              value: _selectedCampusId,
              items: _campuses,
              valueKey: 'id',
              labelKey: 'name',
              onChanged: (v) {
                setState(() {
                  _selectedCampusId = v;
                  _selectedTeacherId = null;
                  _teachers = [];
                  _schedule = {};
                });
                _loadTeachers();
              },
            ),
            const SizedBox(height: 12),
            _buildDropdown<String>(
              label: 'Docente',
              value: _selectedTeacherId,
              items: _teachers,
              valueKey: 'id',
              labelKey: 'name',
              onChanged: (v) {
                setState(() {
                  _selectedTeacherId = v;
                  _schedule = {};
                });
                _loadSchedule();
              },
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildScheduleTable()),
          ],
        ),
      ),
    );
  }
}
