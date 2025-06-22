import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'report_card_model.dart'; // <-- Import the shared model

class StudentReportScreen extends StatelessWidget {
  const StudentReportScreen({super.key});

  static const Color backgroundColor = Color(0xFFF0F0E3);
  static const Color primaryColor = Color(0xFF53A09D);

  static final List<ReportCardData> _reports = [
    ReportCardData(
      title: 'Horario del Estudiante',
      description: 'Horario semanal con estado de asistencia',
      icon: FontAwesomeIcons.calendarWeek,
      routeName: '/studentSchedule',
    ),
    ReportCardData(
      title: 'Detalle por Estudiante',
      description: 'Asistencias filtradas por rango de fechas',
      icon: FontAwesomeIcons.userGraduate,
      routeName: '/studentSummary',
    ),
    ReportCardData(
      title: 'Patrones de Ausencia',
      description: 'Estudiantes con ausencias frecuentes',
      icon: FontAwesomeIcons.exclamationTriangle,
      routeName: '/patternSummary',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Reportes de Estudiantes'),
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
