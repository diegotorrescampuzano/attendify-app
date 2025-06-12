import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/reports/outstanding_register_service.dart';

// Corporate colors as in homeroom_summary_screen
const Color backgroundColor = Color(0xFFF0F0E3);
const Color primaryColor = Color(0xFF53A09D);

class OutstandingRegisterScreen extends StatefulWidget {
  @override
  State<OutstandingRegisterScreen> createState() => _OutstandingRegisterScreenState();
}

class _OutstandingRegisterScreenState extends State<OutstandingRegisterScreen> {
  // Default both dates to today
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _loading = false;
  List<Map<String, dynamic>> _outstanding = [];

  // Campus selection
  List<Map<String, dynamic>> _campuses = [];
  String? _selectedCampusId;

  // Service instance
  final OutstandingRegisterService _service = OutstandingRegisterService();

  @override
  void initState() {
    super.initState();
    _loadCampuses();
  }

  /// Loads campuses for the dropdown
  Future<void> _loadCampuses() async {
    print('OutstandingRegisterScreen: Loading campuses...');
    final campusSnap = await FirebaseFirestore.instance.collection('campuses').get();
    setState(() {
      _campuses = campusSnap.docs
          .map((doc) => {'id': doc.id, 'name': doc.data()['name'] ?? doc.id})
          .toList();
    });
    print('OutstandingRegisterScreen: Loaded ${_campuses.length} campuses');
  }

  /// Loads outstanding registers for selected date range and campus
  Future<void> _loadOutstanding() async {
    if (_selectedCampusId == null) {
      print('OutstandingRegisterScreen: No campus selected, aborting load');
      return;
    }
    setState(() {
      _loading = true;
    });
    print('OutstandingRegisterScreen: Loading outstanding registers for campus $_selectedCampusId from $_startDate to $_endDate');
    final results = await _service.findOutstandingAttendance(
        _startDate, _endDate, campusId: _selectedCampusId
    );
    // Sort is already handled in the service, but you can double-check here if needed
    setState(() {
      _outstanding = results;
      _loading = false;
    });
    print('OutstandingRegisterScreen: Loaded ${_outstanding.length} outstanding records');
  }

  /// Picks the start date
  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
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

  /// Picks the end date
  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  /// Date pickers styled as in homeroom_summary_screen
  Widget _buildDatePickers() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Desde', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: _pickStartDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: primaryColor, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: primaryColor, size: 18),
                      const SizedBox(width: 8),
                      Text(DateFormat('yyyy-MM-dd').format(_startDate),
                          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hasta', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: _pickEndDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: primaryColor, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: primaryColor, size: 18),
                      const SizedBox(width: 8),
                      Text(DateFormat('yyyy-MM-dd').format(_endDate),
                          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Campus dropdown and Cargar button on a separate row
  Widget _buildCampusAndButtonRow() {
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
                _outstanding = [];
              });
            },
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _loading || _selectedCampusId == null ? null : _loadOutstanding,
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

  /// Helper to get Spanish weekday name from a date string (yyyy-MM-dd)
  String _spanishDayName(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    // Use Spanish locale for day name
    return DateFormat.EEEE('es_ES').format(date);
  }

  Widget _buildOutstandingList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_outstanding.isEmpty) {
      return const Center(child: Text('No hay registros pendientes para los filtros seleccionados.'));
    }
    return ListView.separated(
      itemCount: _outstanding.length,
      separatorBuilder: (_, __) => Divider(),
      itemBuilder: (context, index) {
        final record = _outstanding[index];
        final dayName = record['spanishDayName'] ?? _spanishDayName(record['date'] ?? '');
        return ListTile(
          tileColor: Colors.white,
          title: Text(
            record['teacherName'] ?? 'Sin docente',
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fecha: ${record['date']}  (${dayName[0].toUpperCase()}${dayName.substring(1)})  Campus: ${record['campusName'] ?? ''}'),
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
        title: const Text('Registros Pendientes'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDatePickers(),
            const SizedBox(height: 16),
            _buildCampusAndButtonRow(),
            const SizedBox(height: 16),
            if (_outstanding.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Se encontraron ${_outstanding.length} resultados',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
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
