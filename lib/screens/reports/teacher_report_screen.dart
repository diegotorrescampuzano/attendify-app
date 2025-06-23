import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'report_card_model.dart'; // <-- Import the shared model

class TeacherReportScreen extends StatelessWidget {
  const TeacherReportScreen({super.key});

  static const Color backgroundColor = Color(0xFFF0F0E3);
  static const Color primaryColor = Color(0xFF53A09D);

  static final List<ReportCardData> _reports = [

    ReportCardData(
      title: 'Horario por Docente',
      description: 'Horario semanal individual en formato vertical',
      icon: FontAwesomeIcons.calendarAlt,
      routeName: '/teacherSchedule',
    ),
    ReportCardData(
      title: 'Horario de Docentes',
      description: 'Horarios semanales de uno o varios profesores en formato horizontal',
      icon: FontAwesomeIcons.calendarAlt,
      routeName: '/scheduleSummary',
    ),
    ReportCardData(
      title: 'Asistencias Pendientes (Docente)',
      description: 'Asistencia pendiente para docente específico (semana actual) en formato vertical',
      icon: FontAwesomeIcons.exclamationCircle,
      routeName: '/outstandingAttendance',
    ),
    ReportCardData(
      title: 'Asistencias Pendientes',
      description: 'Clases con asistencia pendiente (semana actual) en formato horizontal',
      icon: FontAwesomeIcons.exclamationCircle,
      routeName: '/outstandingCurrentWeek',
    ),
    ReportCardData(
      title: 'Resumen por Docente',
      description: 'Asistencias registradas por docente',
      icon: FontAwesomeIcons.userTie,
      routeName: '/teacherSummary',
    ),
    ReportCardData(
      title: 'Resumen Fuera de Horario (Semana Actual)',
      description: 'Resumen semanal de asistencias registradas fuera/dentro del horario',
      icon: FontAwesomeIcons.clock,
      routeName: '/offtheclockSummary',
    ),
    ReportCardData(
      title: 'Registros Pendientes (Listado)',
      description: 'Registros de asistencia pendientes por docentes',
      icon: FontAwesomeIcons.clipboardList,
      routeName: '/outstandingRegister',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Reportes de Docentes'),
        backgroundColor: primaryColor,
      ),
      body: _buildGrid(),
    );
  }

  Widget _buildGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = constraints.maxWidth > 900 ? 3 :
          constraints.maxWidth > 600 ? 2 : 1;
          return GridView.builder(
            itemCount: _reports.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemBuilder: (context, index) => ReportCard(
              data: _reports[index],
              primaryColor: primaryColor,
              onTap: () => _handleNavigation(context, _reports[index]),
            ),
          );
        },
      ),
    );
  }

  void _handleNavigation(BuildContext context, ReportCardData report) {
    if (report.routeName.isNotEmpty) {
      Navigator.pushNamed(context, report.routeName);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reporte en construcción: ${report.title}')),
      );
    }
  }
}
