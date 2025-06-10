import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/license_service.dart';

class LicenseScreen extends StatefulWidget {
  const LicenseScreen({super.key});

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  Map<String, dynamic>? _license;
  bool _loading = true;
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadLicense();
    _loadVersion();
  }

  Future<void> _loadLicense() async {
    print('[LicenseScreen] Loading license data...');
    final license = await LicenseService.getLicense();
    setState(() {
      _license = license;
      _loading = false;
    });
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = '${info.version}+${info.buildNumber}';
    });
    print('[LicenseScreen] App version: $_version');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0E3),
      appBar: AppBar(
        title: const Text('Información de la Licencia'),
        backgroundColor: const Color(0xFF53A09D),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _license == null
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'No se encontraron datos de licencia.',
            style: TextStyle(fontSize: 18),
          ),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _license!['name'] ?? 'Sin nombre',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF53A09D),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _license!['description'] ?? 'Sin descripción',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Text(
                          'Estado: ',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          _license!['active'] == true
                              ? 'Activa'
                              : 'Inactiva',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _license!['active'] == true
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    if (_license!['expiryDate'] != null) ...[
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final expiryDate = _license!['expiryDate'].toDate();
                          final now = DateTime.now();
                          final daysLeft = expiryDate
                              .difference(DateTime(now.year, now.month, now.day))
                              .inDays;
                          return Row(
                            children: [
                              const Text(
                                'Expiración: ',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                expiryDate.toString().split(' ')[0],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  daysLeft >= 0
                                      ? '($daysLeft días restantes)'
                                      : '(expirada)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: daysLeft >= 0
                                        ? Colors.blueGrey
                                        : Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                    if (_license!['warnDaysBeforeExpiry'] != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            'Aviso previo: ',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${_license!['warnDaysBeforeExpiry']} días antes',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    FutureBuilder<bool>(
                      future: LicenseService.isLicenseAboutToExpire(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox.shrink();
                        }
                        if (snapshot.hasData && snapshot.data == true) {
                          return Card(
                            color: Colors.orange[100],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_outlined,
                                    color: Colors.orange[800],
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'La licencia expirará pronto. Por favor, contacte al administrador.',
                                      style: TextStyle(
                                        color: Colors.orange[800],
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Versión de la app: $_version',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
