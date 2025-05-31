import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  static const Color backgroundColor = Color(0xFFF0F0E3);
  static const Color primaryColor = Color(0xFF53A09D);

  static final List<_ReportCardData> _reports = [
    _ReportCardData(
      title: 'Resumen de Asistencias por Docente',
      description:
      'Cantidad de asistencias registradas por el docente en un rango de fechas, agrupadas por tipo y asignatura.',
      icon: FontAwesomeIcons.userTie,
      routeName: '/report/teacher-summary',
    ),
    _ReportCardData(
      title: 'Detalle de Asistencia por Estudiante',
      description:
      'Asistencias de estudiantes filtradas por rango de fechas, agrupadas por asignatura.',
      icon: FontAwesomeIcons.userGraduate,
      routeName: '/report/student-detail',
    ),
    _ReportCardData(
      title: 'Resumen de Asistencia por Asignatura',
      description: 'Resumen de asistencias por asignatura en un rango de fechas.',
      icon: FontAwesomeIcons.bookOpen,
      routeName: '/report/subject-overview',
    ),
    _ReportCardData(
      title: 'Asistencia por Salón',
      description: 'Estadísticas de asistencia para un salón o grupo específico.',
      icon: FontAwesomeIcons.chalkboardTeacher,
      routeName: '/report/class-attendance',
    ),
    _ReportCardData(
      title: 'Patrones de Ausencia',
      description: 'Identificación de estudiantes con ausencias continuas o frecuentes.',
      icon: FontAwesomeIcons.exclamationTriangle,
      routeName: '/report/absence-patterns',
    ),
    _ReportCardData(
      title: 'Asistencia por Periodo',
      description: 'Asistencia agrupada por periodos o franjas horarias.',
      icon: FontAwesomeIcons.clock,
      routeName: '/report/attendance-by-period',
    ),
    _ReportCardData(
      title: 'Registros Pendientes por Docente',
      description: 'Lista de registros de asistencia que aún no han sido completados por docentes.',
      icon: FontAwesomeIcons.clipboardList,
      routeName: '/report/teacher-pending',
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
        child: MasonryGridView.count(
          crossAxisCount: 2, // 2 columns grid
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          itemCount: _reports.length,
          itemBuilder: (context, index) {
            final report = _reports[index];
            return _ReportCard(
              data: report,
              primaryColor: primaryColor,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Abrir reporte: ${report.title}')),
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
