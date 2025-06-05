// Importaciones
import 'dart:convert'; // Para decodificar base64
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/app_drawer.dart';
import '../screens/campus_screen.dart';
import '../screens/report_screen.dart';
import '../screens/profile_screen.dart';
import '../widgets/bottom_navbar.dart';
import '../services/home_service.dart';
import '../services/dashboard/campus_attendance_service.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late Future<Map<String, dynamic>> _schoolFuture;
  late Future<List<Map<String, dynamic>>> _dashboardFuture;

  // Store campus names for display
  List<String> _campusNames = [];

  @override
  void initState() {
    super.initState();
    _schoolFuture = HomeService.getSchoolData();
    _dashboardFuture = _loadDashboardForTeacher();
  }

  Future<List<Map<String, dynamic>>> _loadDashboardForTeacher() async {
    final userData = AuthService.currentUserData;
    if (userData == null) return [];
    final teacherRefId = userData['refId'];
    if (teacherRefId == null) return [];

    final teacherData = await DashboardService.getTeacherDataByRefId(teacherRefId);
    if (teacherData == null) return [];

    final assignedCampusesRefs = teacherData['assignedCampuses'] as List<dynamic>? ?? [];
    if (assignedCampusesRefs.isEmpty) return [];

    List<Map<String, dynamic>> combinedSummary = [];
    List<String> campusNames = [];

    for (var campusRef in assignedCampusesRefs) {
      String campusId;
      if (campusRef is DocumentReference) {
        campusId = campusRef.id;
      } else if (campusRef is String) {
        campusId = campusRef;
      } else {
        continue;
      }

      // Fetch campus name for display
      final campusDoc = await FirebaseFirestore.instance.collection('campuses').doc(campusId).get();
      if (campusDoc.exists) {
        final campusName = campusDoc.data()?['name'] ?? campusId;
        campusNames.add(campusName);
      } else {
        campusNames.add(campusId);
      }

      final campusSummary = await DashboardService.getAttendanceSummaryByGradeFilteredByCampus(campusId);
      combinedSummary.addAll(campusSummary);
    }

    // Store campus names to state for UI
    setState(() {
      _campusNames = campusNames;
    });

    // Group by gradeId to merge duplicates
    Map<String, Map<String, dynamic>> grouped = {};
    for (var item in combinedSummary) {
      final gradeId = item['gradeId'] as String;
      if (!grouped.containsKey(gradeId)) {
        grouped[gradeId] = Map<String, dynamic>.from(item);
      } else {
        grouped[gradeId]!['expected'] += item['expected'] as int;
        grouped[gradeId]!['asiste'] += item['asiste'] as int;
        grouped[gradeId]!['conNovedad'] += item['conNovedad'] as int;
      }
    }

    return grouped.values.toList();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildBarChart(int asiste, int conNovedad) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (asiste > conNovedad ? asiste : conNovedad).toDouble() + 5,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 0:
                    return const Text('Asiste', style: TextStyle(color: Colors.green));
                  case 1:
                    return const Text('Con Novedad', style: TextStyle(color: Colors.orange));
                  default:
                    return const Text('');
                }
              },
              reservedSize: 40,
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(toY: asiste.toDouble(), color: Colors.green, width: 30),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(toY: conNovedad.toDouble(), color: Colors.orange, width: 30),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text('Error al cargar datos: ${snapshot.error}'),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No hay datos de asistencia para hoy.', textAlign: TextAlign.center),
          );
        }

        final summary = snapshot.data!;

        int totalAsiste = 0;
        int totalConNovedad = 0;
        for (var g in summary) {
          totalAsiste += g['asiste'] as int? ?? 0;
          totalConNovedad += g['conNovedad'] as int? ?? 0;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_campusNames.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Text(
                  'Resumen de asistencia para campus: ${_campusNames.join(", ")}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF53A09D)),
                  textAlign: TextAlign.center,
                ),
              ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Text(
                'Resumen de asistencia por grado (hoy)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF53A09D)),
                textAlign: TextAlign.left,
              ),
            ),
            ...summary.map((g) => Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF53A09D),
                  child: Text(
                    (g['gradeName'] as String).isNotEmpty ? (g['gradeName'] as String)[0] : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(g['gradeName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Esperados: ${g['expected']}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Asiste: ${g['asiste']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    Text('Con Novedad: ${g['conNovedad']}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 220,
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        const Text(
                          'Asistencia General',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF53A09D)),
                        ),
                        const SizedBox(height: 12),
                        Expanded(child: _buildBarChart(totalAsiste, totalConNovedad)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWelcomePage() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _schoolFuture,
      builder: (context, snapshot) {
        final logoWidget = () {
          if (snapshot.hasData && snapshot.data!['logo'].isNotEmpty) {
            final bytes = base64Decode(snapshot.data!['logo']);
            return Image.memory(bytes, height: 80);
          }
          return const SizedBox.shrink();
        }();

        final nameWidget = () {
          if (snapshot.hasData) {
            return Text(
              snapshot.data!['name'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            );
          }
          return const SizedBox.shrink();
        }();

        return Container(
          color: const Color(0xFFF0F0E3),
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/attendify_logo.png',
                      height: 160,
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      '¡Bienvenido a Attendify!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF53A09D),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Con esta aplicación podrás registrar y gestionar la asistencia de tus estudiantes de forma rápida, segura y eficiente.',
                      style: TextStyle(fontSize: 18, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        child: Column(
                          children: [
                            logoWidget,
                            const SizedBox(height: 12),
                            nameWidget,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildDashboardSection(),
                    const SizedBox(height: 40),
                    // Removed the "Tomar Asistencia" button as requested
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      _buildWelcomePage(),
      CampusScreen(),
      ReportScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendify'),
        backgroundColor: const Color(0xFF53A09D),
      ),
      drawer: const AppDrawer(),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
