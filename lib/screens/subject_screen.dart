import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For weekday formatting and date formatting
import '../services/subject_service.dart';

class SubjectScreen extends StatefulWidget {
  final Map<String, dynamic> campus;
  final Map<String, dynamic> educationalLevel;
  final Map<String, dynamic> grade;
  final Map<String, dynamic> homeroom; // Includes 'id' and 'ref' (DocumentReference)

  const SubjectScreen({
    super.key,
    required this.campus,
    required this.educationalLevel,
    required this.grade,
    required this.homeroom,
  });

  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends State<SubjectScreen> {
  late Future<List<Map<String, dynamic>>> _subjectsFuture;
  late String _weekdayKey;

  // Map English weekday names to Spanish as static const
  static const Map<String, String> englishToSpanishWeekdays = {
    'monday': 'Lunes',
    'tuesday': 'Martes',
    'wednesday': 'Miércoles',
    'thursday': 'Jueves',
    'friday': 'Viernes',
    'saturday': 'Sábado',
    'sunday': 'Domingo',
  };

  // Time slots every 30 minutes from 7:00 AM to 6:00 PM
  final List<String> timeSlots = [
    '07:00 AM', '07:30 AM', '08:00 AM', '08:30 AM', '09:00 AM', '09:30 AM',
    '10:00 AM', '10:30 AM', '11:00 AM', '11:30 AM', '12:00 PM', '12:30 PM',
    '01:00 PM', '01:30 PM', '02:00 PM', '02:30 PM', '03:00 PM', '03:30 PM',
    '04:00 PM', '04:30 PM', '05:00 PM', '05:30 PM', '06:00 PM',
  ];

  DateTime _selectedDate = DateTime.now();
  late String _selectedTime;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _weekdayKey = DateFormat('EEEE').format(now).toLowerCase();

    final homeroomRef = widget.homeroom['ref'];
    _subjectsFuture = SubjectService.getSubjectsForHomeroomByDay(homeroomRef, _weekdayKey);

    _selectedTime = timeSlots[0];
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('es'), // Optional: Spanish locale
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;

        // Update weekday key and refresh subjects for new day
        _weekdayKey = DateFormat('EEEE').format(_selectedDate).toLowerCase();
        final homeroomRef = widget.homeroom['ref'];
        _subjectsFuture = SubjectService.getSubjectsForHomeroomByDay(homeroomRef, _weekdayKey);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final spanishWeekday = englishToSpanishWeekdays[_weekdayKey] ?? _weekdayKey;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0E3),
      appBar: AppBar(
        title: const Text('Selecciona la Asignatura'),
        backgroundColor: const Color(0xFF53A09D),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Card(
              color: const Color(0xFFE6F4F1),
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.info_outline, color: Color(0xFF53A09D), size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Selecciona la asignatura correspondiente al salón y día actual para continuar con el registro de asistencia.',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Display hierarchy info
            Text(
              widget.campus['name'] ?? '',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.educationalLevel['name'] ?? '',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              widget.grade['name'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              widget.homeroom['name'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            // Instruction text
            const Padding(
              padding: EdgeInsets.only(bottom: 12.0),
              child: Text(
                'Selecciona la fecha y hora para la asistencia de la clase:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),

            // Row with calendar picker and time dropdown
            Row(
              children: [
                // Calendar picker button
                Expanded(
                  flex: 1,
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today, color: Color(0xFF53A09D)),
                    label: Text(
                      DateFormat('dd/MM/yyyy').format(_selectedDate),
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFF53A09D)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Time picker dropdown
                Expanded(
                  flex: 1,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Hora',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedTime,
                        isExpanded: true,
                        items: timeSlots.map((time) {
                          return DropdownMenuItem<String>(
                            value: time,
                            child: Text(time),
                          );
                        }).toList(),
                        onChanged: (newTime) {
                          if (newTime != null) {
                            setState(() {
                              _selectedTime = newTime;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Current weekday display in Spanish
            Text(
              'Asignaturas para el día: $spanishWeekday',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 10),

            // Subjects list
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _subjectsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No se encontraron asignaturas para hoy.'));
                  }

                  final subjects = snapshot.data!;

                  return ListView.builder(
                    itemCount: subjects.length,
                    itemBuilder: (context, index) {
                      final subject = subjects[index];
                      return Card(
                        elevation: 2,
                        child: ListTile(
                          leading: const Icon(Icons.menu_book, color: Color(0xFF53A09D)),
                          title: Text(
                            subject['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(subject['description']),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // TODO: Navigate to attendance screen or next step
                            // You can pass selected date and time here as well
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
