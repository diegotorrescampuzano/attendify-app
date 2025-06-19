import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../services/notification_service.dart'; // Asegúrate de tener este servicio implementado

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  static const Color backgroundColor = Color(0xFFF0F0E3);
  static const Color primaryColor = Color(0xFF53A09D);

  bool _notificationsEnabled = true; // Puedes cargar este valor de preferencias

  @override
  void initState() {
    super.initState();
    // Aquí podrías cargar el valor real desde SharedPreferences o Firestore
  }

  void _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });
    // Aquí puedes guardar el valor en preferencias y programar/cancelar notificaciones
    if (value) {
      await NotificationService().scheduleReminders();
    } else {
      await NotificationService().cancelAllNotifications();
    }
  }

  void _testNotification() async {
    await NotificationService().showNotification(
      title: 'Notificación de prueba',
      body: '¡Esta es una notificación de prueba!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: primaryColor,
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notificaciones',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: SwitchListTile(
                title: const Text(
                  'Recordatorios de asistencia',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                subtitle: const Text('Recibe recordatorios cada hora del día para registrar la asistencia.'),
                value: _notificationsEnabled,
                activeColor: primaryColor,
                onChanged: _toggleNotifications,
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.notifications_active),
                label: const Text('Probar notificación'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _testNotification,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
