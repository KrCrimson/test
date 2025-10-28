import 'dart:convert'; // Para utf8
import 'dart:typed_data'; // Para Uint8List
import 'package:flutter/material.dart';
// TODO: Reemplazar Firestore y FirebaseAuth por API MongoDB
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'pending_all_exit_screen.dart'; // Importa la pantalla de pendientes de salida
import 'user_alarm_details_screen.dart'; // Importa la pantalla de alarma
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../config.dart';

class UserHistoryScreen extends StatefulWidget {
  const UserHistoryScreen({super.key});

  @override
  State<UserHistoryScreen> createState() => _UserHistoryScreenState();
}

class _UserHistoryScreenState extends State<UserHistoryScreen> {
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final FirebaseAuth _auth = FirebaseAuth.instance;
  String _selectedFilter = 'todos';
  DateTimeRange? _dateRange;
  bool _isLoading = true;
  String? _errorMessage;
  final List<Map<String, dynamic>> _attendanceData = [];

  // NUEVO: Filtros avanzados
  String? _dniFilter;
  String? _nombreFilter;
  String? _facultadFilter;
  String? _escuelaFilter;
  List<String> _facultadesDisponibles = [];
  List<String> _escuelasDisponibles = [];

  // Controladores para los campos de texto
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFacultadesEscuelas();
    _loadInitialData();
  }

  @override
  void dispose() {
    _dniController.dispose();
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _loadFacultadesEscuelas() async {
    try {
      final response = await http.get(
  Uri.parse('${Config.apiBaseUrl}/facultades'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _facultadesDisponibles = List<String>.from(data.map((f) => f['siglas']));
        });
      } else {
        setState(() {
          _facultadesDisponibles = [];
        });
      }
    } catch (e) {
      setState(() {
        _facultadesDisponibles = [];
      });
    }
  }

  Future<void> _loadEscuelasPorFacultad(String facultadSiglas) async {
    if (facultadSiglas.isEmpty) {
      setState(() => _escuelasDisponibles = []);
      return;
    }
    try {
      final response = await http.get(
  Uri.parse('${Config.apiBaseUrl}/escuelas?siglas_facultad=$facultadSiglas'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _escuelasDisponibles = List<String>.from(data.map((e) => e['siglas']));
        });
      } else {
        setState(() {
          _escuelasDisponibles = [];
        });
      }
    } catch (e) {
      setState(() {
        _escuelasDisponibles = [];
      });
    }
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Obtener todos los registros de asistencias desde la API REST
      final response = await http.get(
  Uri.parse('${Config.apiBaseUrl}/asistencias'),
      );
      if (response.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error al cargar asistencias';
        });
        return;
      }
      List<dynamic> allRecordsRaw = json.decode(response.body);
      List<Map<String, dynamic>> allRecords = allRecordsRaw.map((r) {
        final map = Map<String, dynamic>.from(r as Map);
        final fechaHoraStr = map['fecha_hora'] ?? map['fecha'] ?? '';
        DateTime fechaHora;
        try {
          fechaHora = DateTime.parse(fechaHoraStr);
        } catch (_) {
          fechaHora = DateTime.now();
        }
        return {
          ...map,
          'fecha_hora': fechaHora,
        };
      }).toList();

      // Filtrar por tipo (entrada/salida)
      if (_selectedFilter == 'entrada' || _selectedFilter == 'salida') {
        allRecords = allRecords.where((record) => record['tipo'] == _selectedFilter).toList();
      }

      // Filtrar por facultad
      if (_facultadFilter != null && _facultadFilter!.isNotEmpty) {
        allRecords = allRecords.where((record) => record['siglas_facultad'] == _facultadFilter).toList();
      }

      // Filtrar por escuela
      if (_escuelaFilter != null && _escuelaFilter!.isNotEmpty) {
        allRecords = allRecords.where((record) => record['siglas_escuela'] == _escuelaFilter).toList();
      }

      // Filtrar por rango de fechas
      if (_dateRange != null) {
        final start = DateTime(_dateRange!.start.year, _dateRange!.start.month, _dateRange!.start.day, 0, 0, 0);
        final end = DateTime(_dateRange!.end.year, _dateRange!.end.month, _dateRange!.end.day, 23, 59, 59, 999);
        allRecords = allRecords.where((record) {
          final fecha = record['fecha_hora'] as DateTime;
          return fecha.isAfter(start.subtract(const Duration(seconds: 1))) && fecha.isBefore(end.add(const Duration(seconds: 1)));
        }).toList();
      }

      // Filtrar en memoria por DNI
      if (_dniFilter != null && _dniFilter!.trim().isNotEmpty) {
        final dniFilterLower = _dniFilter!.trim().toLowerCase();
        allRecords = allRecords.where((record) {
          final dni = record['dni']?.toString().toLowerCase() ?? '';
          return dni.contains(dniFilterLower);
        }).toList();
      }

      // Filtrar en memoria por nombre y apellido
      if (_nombreFilter != null && _nombreFilter!.trim().isNotEmpty) {
        final nombreFilterLower = _nombreFilter!.trim().toLowerCase();
        allRecords = allRecords.where((record) {
          final nombre = record['nombre']?.toString().toLowerCase() ?? '';
          final apellido = record['apellido']?.toString().toLowerCase() ?? '';
          final nombreCompleto = '$nombre $apellido';
          return nombreCompleto.contains(nombreFilterLower) || nombre.contains(nombreFilterLower) || apellido.contains(nombreFilterLower);
        }).toList();
      }

      setState(() {
        _attendanceData.clear();
        _attendanceData.addAll(allRecords);
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
      await _loadInitialData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.indigo.withOpacity(0.9),
        elevation: 8,
        title: Text(
          'Mis Registros de Asistencia',
          style: GoogleFonts.lato(
            textStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Tooltip(
              message: 'Alumnos dentro después de las 9',
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.85),
                radius: 22,
                child: IconButton(
                  icon: const Icon(Icons.warning_amber_rounded, size: 28),
                  color: Colors.orangeAccent,
                  splashRadius: 24,
                  onPressed: () {
                    // TODO: Implementar PendingAllExitScreen
                     Navigator.push(
                       context,
                       MaterialPageRoute(
                         builder: (context) => PendingAllExitScreen(registros: _attendanceData),
                       ),
                     );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Tooltip(
              message: 'Visitas de externos',
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.85),
                radius: 22,
                child: IconButton(
                  icon: const Icon(Icons.groups_2_rounded, size: 28),
                  color: Colors.teal,
                  splashRadius: 24,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserAlarmDetailsScreen(registros: _attendanceData),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Tooltip(
              message: 'Refrescar registros',
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.85),
                radius: 22,
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 28),
                  color: Colors.indigo,
                  splashRadius: 24,
                  onPressed: _loadInitialData,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: PopupMenuButton<String>(
              tooltip: 'Filtrar por tipo',
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              icon: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.85),
                radius: 20,
                child: const Icon(Icons.filter_list_rounded, color: Colors.deepPurple, size: 26),
              ),
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'todos',
                  child: Row(
                    children: [
                      Icon(Icons.list_alt, color: Colors.blueGrey),
                      SizedBox(width: 8),
                      Text('Todos los registros'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'entrada',
                  child: Row(
                    children: [
                      Icon(Icons.login, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Solo entradas'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'salida',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text('Solo salidas'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) async {
                setState(() => _selectedFilter = value);
                await _loadInitialData();
              },
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF536976),
              Color(0xFF292E49),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _dniController,
                                decoration: const InputDecoration(
                                  labelText: 'DNI (búsqueda por similitud)',
                                  hintText: 'Ej: 12345...',
                                ),
                                onChanged: (v) {
                                  _dniFilter = v;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _nombreController,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre/Apellido (búsqueda por similitud)',
                                  hintText: 'Ej: Juan, García...',
                                ),
                                onChanged: (v) {
                                  _nombreFilter = v;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _facultadFilter,
                                decoration: const InputDecoration(labelText: 'Facultad'),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('Todas las facultades')),
                                  ..._facultadesDisponibles.map((f) => DropdownMenuItem(value: f, child: Text(f))),
                                ],
                                onChanged: (v) async {
                                  setState(() {
                                    _facultadFilter = v;
                                    _escuelaFilter = null; // Reset escuela cuando cambie facultad
                                  });
                                  if (v != null && v.isNotEmpty) {
                                    await _loadEscuelasPorFacultad(v);
                                  } else {
                                    setState(() => _escuelasDisponibles = []);
                                  }
                                },
                                isExpanded: true,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _escuelaFilter,
                                decoration: const InputDecoration(labelText: 'Escuela'),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('Todas las escuelas')),
                                  ..._escuelasDisponibles.map((e) => DropdownMenuItem(value: e, child: Text(e))),
                                ],
                                onChanged: (v) {
                                  setState(() => _escuelaFilter = v);
                                },
                                isExpanded: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.filter_alt),
                                label: const Text('Aplicar filtros'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo[700],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: _loadInitialData,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.clear),
                                label: const Text('Limpiar filtros'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[300],
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () async {
                                  setState(() {
                                    _dniFilter = null;
                                    _nombreFilter = null;
                                    _facultadFilter = null;
                                    _escuelaFilter = null;
                                    _dateRange = null;
                                    _escuelasDisponibles = [];
                                  });
                                  // Limpiar los controladores de texto
                                  for (final controller in [_dniController, _nombreController]) {
                                    controller.clear();
                                  }
                                  await _loadInitialData();
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.date_range),
                                label: Text(_dateRange == null
                                    ? 'Rango de fechas'
                                    : '${DateFormat('dd/MM/yyyy').format(_dateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_dateRange!.end)}'),
                                onPressed: () => _selectDateRange(context),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadInitialData,
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'export',
            backgroundColor: Colors.amber[700],
            tooltip: 'Exportar a CSV',
            child: const Icon(Icons.download, color: Colors.white),
            onPressed: _exportToCsv,
          ),
          const SizedBox(height: 14),
          FloatingActionButton(
            heroTag: 'logout',
            backgroundColor: Colors.redAccent,
            tooltip: 'Cerrar sesión',
            child: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              // await FirebaseAuth.instance.signOut();
              // if (mounted) {
              //   Navigator.of(context).pushReplacementNamed('/login');
              // }
            },
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    if (_attendanceData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No se encontraron registros',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              'Prueba cambiando los filtros',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _attendanceData.length,
      itemBuilder: (context, index) {
        final record = _attendanceData[index];
        return _buildAttendanceItem(record);
      },
    );
  }

  Widget _buildAttendanceItem(Map<String, dynamic> record) {
    final fechaHora = DateFormat('dd/MM/yyyy HH:mm').format(record['fecha_hora']);
    final tipo = record['tipo']?.toString().toUpperCase() ?? '';
    final entradaTipo = record['entrada_tipo'] ?? 'Desconocido';
    final puerta = record['puerta'] ?? '-';

    final isEntrada = record['tipo'] == 'entrada';
    final cardColor = isEntrada ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE); // Verde claro o rojo claro
    final borderColor = isEntrada ? Colors.green : Colors.redAccent;
    final iconColor = isEntrada ? Colors.green[700] : Colors.redAccent;
    final iconData = isEntrada ? Icons.login_rounded : Icons.logout_rounded;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border(
          left: BorderSide(color: borderColor, width: 7),
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.13),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: iconColor?.withOpacity(0.15),
          radius: 28,
          child: Icon(iconData, color: iconColor, size: 32),
        ),
        title: Text(
          '${record['nombre'] ?? ''} ${record['apellido'] ?? ''}'.trim(),
          style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 19, color: Colors.black87),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 2),
            Text('DNI: ${record['dni'] ?? 'No disponible'}', style: GoogleFonts.lato(fontSize: 15, color: Colors.blueGrey[800])),
            Text('${record['siglas_facultad'] ?? ''} - ${record['siglas_escuela'] ?? ''}', style: GoogleFonts.lato(fontSize: 15, color: Colors.indigo[700])),
            Text(fechaHora, style: GoogleFonts.lato(fontSize: 13, color: Colors.grey[700])),
            Text('Entrada por: $entradaTipo | Puerta: $puerta', style: GoogleFonts.lato(fontSize: 13, color: Colors.deepPurple)),
          ],
        ),
        trailing: SizedBox(
          height: 40,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isEntrada ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tipo,
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.bold,
                    color: isEntrada ? Colors.green[800] : Colors.red[800],
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Icon(Icons.door_front_door, color: Colors.teal[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportToCsv() async {
    try {
      String csvContent = "Nombre,Apellido,DNI,Código,Facultad,Escuela,Tipo,Fecha,Hora\n";
      
      for (var record in _attendanceData) {
        final date = DateFormat('dd/MM/yyyy').format(record['fecha_hora']);
        final time = record['hora'] ?? DateFormat('HH:mm').format(record['fecha_hora']);
        
        csvContent += '"${record['nombre'] ?? ''}",'
                     '"${record['apellido'] ?? ''}",'
                     '"${record['dni'] ?? ''}",'
                     '"${record['codigo_universitario'] ?? ''}",'
                     '"${record['siglas_facultad'] ?? ''}",'
                     '"${record['siglas_escuela'] ?? ''}",'
                     '"${record['tipo'] ?? ''}",'
                     '"$date","$time"\n';
      }

      final bytes = utf8.encode(csvContent);
      final file = XFile.fromData(
        Uint8List.fromList(bytes),
        mimeType: 'text/csv',
        name: 'mis_asistencias_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv'
      );

      await Share.shareXFiles([file], text: 'Mis registros de asistencia');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar: ${e.toString()}')),
      );
    }
  }
}
// Pantalla para alumnos dentro después de las 9
class PendingAllExitScreen extends StatelessWidget {
  final List<Map<String, dynamic>> registros;
  const PendingAllExitScreen({super.key, required this.registros});

  @override
  Widget build(BuildContext context) {
    final pendientes = registros.where((r) {
      final fecha = r['fecha_hora'] is DateTime ? r['fecha_hora'] : DateTime.tryParse(r['fecha_hora'].toString()) ?? DateTime.now();
      return r['tipo'] == 'entrada' && fecha.hour >= 9;
    }).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Alumnos dentro después de las 9')),
      body: pendientes.isEmpty
          ? const Center(child: Text('No hay alumnos pendientes.'))
          : ListView.builder(
              itemCount: pendientes.length,
              itemBuilder: (context, i) {
                final r = pendientes[i];
                return ListTile(
                  title: Text('${r['nombre'] ?? ''} ${r['apellido'] ?? ''}'),
                  subtitle: Text('DNI: ${r['dni'] ?? ''} - ${fechaToString(r['fecha_hora'])}'),
                );
              },
            ),
    );
  }
}

// Pantalla para visitas de externos
class UserAlarmDetailsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> registros;
  const UserAlarmDetailsScreen({super.key, required this.registros});

  @override
  Widget build(BuildContext context) {
    final externos = registros.where((r) => r['tipo'] == 'externo').toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Visitas de externos')),
      body: externos.isEmpty
          ? const Center(child: Text('No hay visitas de externos.'))
          : ListView.builder(
              itemCount: externos.length,
              itemBuilder: (context, i) {
                final r = externos[i];
                return ListTile(
                  title: Text('${r['nombre'] ?? ''} ${r['apellido'] ?? ''}'),
                  subtitle: Text('DNI: ${r['dni'] ?? ''} - ${fechaToString(r['fecha_hora'])}'),
                );
              },
            ),
    );
  }
}

String fechaToString(dynamic fecha) {
  if (fecha is DateTime) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }
  try {
    final f = DateTime.parse(fecha.toString());
    return '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year} ${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return fecha.toString();
  }
}