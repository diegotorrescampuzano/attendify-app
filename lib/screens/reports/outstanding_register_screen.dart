import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  List<Map<String, dynamic>> _campuses = [];
  String? _selectedCampusId;

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
    });
    print('OutstandingRegisterScreen: Loading outstanding registers for campus $_selectedCampusId for current week (till today)');
    final results = await _service.findOutstandingAttendance(
      campusId: _selectedCampusId!,
    );
    setState(() {
      _outstanding = results;
      _loading = false;
    });
    print('OutstandingRegisterScreen: Loaded ${_outstanding.length} outstanding records');
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
      ],
    );
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
        title: const Text('Registros Pendientes'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCampusDropdown(),
            const SizedBox(height: 16),
            _buildLoadButtonRow(),
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
