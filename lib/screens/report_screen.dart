// lib/screens/report_screen.dart (Main Category Selector)
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  // Corporate colors
  static const Color backgroundColor = Color(0xFFF0F0E3);
  static const Color primaryColor = Color(0xFF53A09D);

  // Define category data model
  static final List<_CategoryCardData> _categories = [
    _CategoryCardData(
      title: 'Reportes de Docentes',
      description: 'Reportes relacionados con docentes y su asistencia',
      icon: FontAwesomeIcons.userTie,
      routeName: '/teacher-reports',
    ),
    _CategoryCardData(
      title: 'Reportes de Estudiantes',
      description: 'Reportes relacionados con estudiantes',
      icon: FontAwesomeIcons.userGraduate,
      routeName: '/student-reports',
    ),
    _CategoryCardData(
      title: 'Reportes de Salones',
      description: 'Reportes por grupo/homeroom',
      icon: FontAwesomeIcons.chalkboardTeacher,
      routeName: '/homeroom-reports',
    ),
    _CategoryCardData(
      title: 'Reportes Generales',
      description: 'Otros reportes del sistema',
      icon: FontAwesomeIcons.chartBar,
      routeName: '/general-reports',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Categorías de Reportes'),
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
              itemCount: _categories.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemBuilder: (context, index) {
                final category = _categories[index];
                return _MenuCard(
                  title: category.title,
                  description: category.description,
                  icon: category.icon,
                  primaryColor: primaryColor,
                  onTap: () => Navigator.pushNamed(context, category.routeName),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _CategoryCardData {
  final String title;
  final String description;
  final IconData icon;
  final String routeName;

  _CategoryCardData({
    required this.title,
    required this.description,
    required this.icon,
    required this.routeName,
  });
}

class _MenuCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color primaryColor;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.description,
    required this.icon,
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
              FaIcon(icon, size: 36, color: primaryColor),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor.darken(0.2),
                ),
              ),
              const SizedBox(height: 8),
              Text(description, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.bottomRight,
                child: Icon(Icons.arrow_forward_ios, size: 16, color: primaryColor),
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
