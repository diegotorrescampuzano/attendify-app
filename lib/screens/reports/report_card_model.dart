import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ReportCardData {
  final String title;
  final String description;
  final IconData icon;
  final String routeName;

  ReportCardData({
    required this.title,
    required this.description,
    required this.icon,
    required this.routeName,
  });
}

class ReportCard extends StatelessWidget {
  final ReportCardData data;
  final Color primaryColor;
  final VoidCallback onTap;

  const ReportCard({
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
                  color: ColorExtension.darken(primaryColor, 0.2),
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
  static Color darken(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
