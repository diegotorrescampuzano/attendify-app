import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  // Corporate colors
  static const Color backgroundColor = Color(0xFFF0F0E3);
  static const Color primaryColor = Color(0xFF53A09D);

  // Define report data model
  static final List<_ReportCardData> _reports = [
    _ReportCardData(
      title: 'Resumen Fuera de Horario',
      description: 'Resumen semanal de asistencias registradas fuera o dentro del horario por docente, incluyendo el retraso promedio.',
      icon: FontAwesomeIcons.clock,
      routeName: '/offtheclockSummary',
    ),
    _ReportCardData(
      title: 'Registros Pendientes Semana Actual',
      description: 'Lista de registros de asistencia que aún no han sido completados por docentes esta semana.',
      icon: FontAwesomeIcons.clipboardList,
      routeName: '/outstandingRegister',
    ),
    _ReportCardData(
      title: 'Horario de Docentes',
      description: 'Visualiza los horarios semanales de los docentes por campus y selecciona uno o varios para ver sus clases y bloques libres.',
      icon: FontAwesomeIcons.calendarAlt,
      routeName: '/scheduleSummary',
    ),
    _ReportCardData(
      title: 'Horario por Docente',
      description: 'Visualiza el horario semanal de un docente por campus.',
      icon: FontAwesomeIcons.calendarAlt,
      routeName: '/teacherSchedule',
    ),
    _ReportCardData(
      title: 'Asistencias Pendientes (Semana Actual)',
      description: 'Visualiza rápidamente qué docentes tienen clases con asistencia pendiente de registrar esta semana. Los bloques pendientes se muestran en rojo y los registrados en verde.',
      icon: FontAwesomeIcons.exclamationCircle,
      routeName: '/outstandingCurrentWeek',
    ),
    _ReportCardData(
      title: 'Asistencias Pendientes (Semana Actual)',
      description: 'Visualiza rápidamente la asistencia pendiente de registrar esta semana para un docente. Los bloques pendientes se muestran en rojo y los registrados en verde.',
      icon: FontAwesomeIcons.exclamationCircle,
      routeName: '/outstandingAttendance',
    ),
    _ReportCardData(
      title: 'Horario del Estudiante',
      description: 'Visualiza el horario semanal del estudiante con el estado de asistencia por materia y franja horaria.',
      icon: FontAwesomeIcons.calendarWeek, // Or another relevant icon
      routeName: '/studentSchedule',
    ),
    _ReportCardData(
      title: 'Asistencia por Salón',
      description: 'Estadísticas de asistencia para un salón o grupo específico.',
      icon: FontAwesomeIcons.chalkboardTeacher,
      routeName: '/homeroomSummary',
    ),
    _ReportCardData(
      title: 'Detalle de Asistencia por Estudiante',
      description:
      'Asistencias de estudiantes filtradas por rango de fechas, agrupadas por asignatura.',
      icon: FontAwesomeIcons.userGraduate,
      routeName: '/studentSummary', // add this route here
    ),
    _ReportCardData(
      title: 'Resumen de Asistencias por Docente',
      description:
      'Cantidad de asistencias registradas por el docente en un rango de fechas, agrupadas por tipo y asignatura.',
      icon: FontAwesomeIcons.userTie,
      routeName: '/teacherSummary',
    ),
    _ReportCardData(
      title: 'Patrones de Ausencia',
      description: 'Identificación de estudiantes con ausencias continuas o frecuentes.',
      icon: FontAwesomeIcons.exclamationTriangle,
      routeName: '/patternSummary',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Reportes de Asistencia'),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 1;
            final width = constraints.maxWidth;
            if (width > 900) {
              crossAxisCount = 3;
            } else if (width > 600) {
              crossAxisCount = 2;
            }
            return GridView.builder(
              itemCount: _reports.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemBuilder: (context, index) {
                final report = _reports[index];
                return _ReportCard(
                  data: report,
                  primaryColor: primaryColor,
                  onTap: () {
                    if (report.routeName.isNotEmpty) {
                      Navigator.pushNamed(context, report.routeName);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Reporte en construcción: ${report.title}')),
                      );
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ReportCardData {
  final String title;
  final String description;
  final IconData icon;
  final String routeName;

  _ReportCardData({
    required this.title,
    required this.description,
    required this.icon,
    required this.routeName,
  });
}

class _ReportCard extends StatelessWidget {
  final _ReportCardData data;
  final Color primaryColor;
  final VoidCallback onTap;

  const _ReportCard({
    required this.data,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        splashColor: primaryColor.withOpacity(0.2),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                data.icon,
                size: 36,
                color: primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                data.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor.darken(0.2),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data.description,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.bottomRight,
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension ColorExtension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
