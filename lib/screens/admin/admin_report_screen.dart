import 'package:flutter/material.dart';
// TODO: Reemplazar Firestore por API MongoDB

import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config.dart';

class AdminReportScreen extends StatefulWidget {
  const AdminReportScreen({Key? key}) : super(key: key);

  @override
  State<AdminReportScreen> createState() => _AdminReportScreenState();
}

class _AdminReportScreenState extends State<AdminReportScreen> {
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTimeRange? _dateRange;
  String _selectedTipo = 'todos';
  String _selectedFacultad = 'todas';
  String _selectedEscuela = 'todas';
  String _selectedTurno = 'todos';
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _asistencias = [];
  List<String> _facultades = [];
  List<String> _escuelas = [];

  @override
  void initState() {
    super.initState();
    _fetchFacultades();
    _loadAsistencias();
  }

  Future<void> _fetchFacultades() async {
    try {
  final response = await http.get(Uri.parse('${Config.apiBaseUrl}/facultades'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _facultades = List<String>.from(data.map((f) => f['siglas']));
        });
      } else {
        setState(() {
          _facultades = [];
        });
      }
    } catch (e) {
      setState(() {
        _facultades = [];
      });
    }
  }

  Future<void> _fetchEscuelas(String facultad) async {
    if (facultad == 'todas') {
      setState(() => _escuelas = []);
      return;
    }
    try {
  final response = await http.get(Uri.parse('${Config.apiBaseUrl}/escuelas?siglas_facultad=$facultad'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _escuelas = List<String>.from(data.map((e) => e['siglas']));
        });
      } else {
        setState(() {
          _escuelas = [];
        });
      }
    } catch (e) {
      setState(() {
        _escuelas = [];
      });
    }
  }

  Future<void> _loadAsistencias() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
  String url = '${Config.apiBaseUrl}/asistencias?';
      if (_dateRange != null) {
        final start = _dateRange!.start.toIso8601String();
        final end = _dateRange!.end.toIso8601String();
        url += 'start=$start&end=$end&';
      }
      if (_selectedTipo != 'todos') {
        url += 'tipo=${_selectedTipo}&';
      }
      if (_selectedFacultad != 'todas') {
        url += 'siglas_facultad=${_selectedFacultad}&';
      }
      if (_selectedEscuela != 'todas' && _selectedEscuela.isNotEmpty) {
        url += 'siglas_escuela=${_selectedEscuela}&';
      }
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> asistencias = List<Map<String, dynamic>>.from(data.map((a) {
          final map = Map<String, dynamic>.from(a as Map);
          // Parsear fecha_hora
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
        }));
        // Filtro por turno (mañana/tarde) en memoria
        if (_selectedTurno == 'mañana') {
          asistencias = asistencias.where((a) {
            final hora = (a['fecha_hora'] as DateTime).hour;
            return hora >= 8 && hora < 13;
          }).toList();
        } else if (_selectedTurno == 'tarde') {
          asistencias = asistencias.where((a) {
            final hora = (a['fecha_hora'] as DateTime).hour;
            return hora >= 13 && hora <= 21;
          }).toList();
        }
        setState(() {
          _asistencias = asistencias;
          _isLoading = false;
        });
      } else {
        throw Exception('Error al cargar asistencias');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}\n'
            'Verifica que la colección y los campos coincidan exactamente en nombre y mayúsculas/minúsculas. '
            'Si el error es de índice, usa el enlace que da el error para crearlo de nuevo.';
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
      await _loadAsistencias();
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
          'Reporte de Asistencias',
          style: GoogleFonts.lato(
            textStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.amber),
            tooltip: 'Refrescar',
            onPressed: _loadAsistencias,
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
                    child: _buildFiltros(context),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                          ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                          : _buildListado(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltros(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              elevation: 2,
            ),
            icon: const Icon(Icons.date_range),
            onPressed: () => _selectDateRange(context),
            label: Text(
              _dateRange == null
                  ? 'Seleccionar rango'
                  : (_dateRange!.start == _dateRange!.end
                      ? DateFormat('dd/MM/yy').format(_dateRange!.start)
                      : '${DateFormat('dd/MM/yy').format(_dateRange!.start)} - ${DateFormat('dd/MM/yy').format(_dateRange!.end)}'),
            ),
          ),
          const SizedBox(width: 8),
          if (_dateRange != null)
            ActionChip(
              label: const Text('Limpiar'),
              avatar: const Icon(Icons.clear, size: 18),
              backgroundColor: Colors.red[100],
              onPressed: () async {
                setState(() {
                  _dateRange = null;
                });
                await _loadAsistencias();
              },
            ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _selectedTipo,
            dropdownColor: Colors.white,
            style: GoogleFonts.lato(color: Colors.indigo[900]),
            items: const [
              DropdownMenuItem(value: 'todos', child: Text('Todos')),
              DropdownMenuItem(value: 'entrada', child: Text('Entradas')),
              DropdownMenuItem(value: 'salida', child: Text('Salidas')),
            ],
            onChanged: (value) async {
              setState(() => _selectedTipo = value!);
              await _loadAsistencias();
            },
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _selectedFacultad,
            dropdownColor: Colors.white,
            style: GoogleFonts.lato(color: Colors.indigo[900]),
            items: [
              const DropdownMenuItem(value: 'todas', child: Text('Todas las facultades')),
              ..._facultades.map((f) => DropdownMenuItem(value: f, child: Text(f))),
            ],
            onChanged: (value) async {
              setState(() {
                _selectedFacultad = value!;
                _selectedEscuela = 'todas';
              });
              await _fetchEscuelas(_selectedFacultad);
              await _loadAsistencias();
            },
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _selectedEscuela,
            dropdownColor: Colors.white,
            style: GoogleFonts.lato(color: Colors.indigo[900]),
            items: [
              const DropdownMenuItem(value: 'todas', child: Text('Todas las escuelas')),
              ..._escuelas.map((e) => DropdownMenuItem(value: e, child: Text(e))),
            ],
            onChanged: (value) async {
              setState(() => _selectedEscuela = value!);
              await _loadAsistencias();
            },
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _selectedTurno,
            dropdownColor: Colors.white,
            style: GoogleFonts.lato(color: Colors.indigo[900]),
            items: const [
              DropdownMenuItem(value: 'todos', child: Text('Todos los turnos')),
              DropdownMenuItem(value: 'mañana', child: Text('Mañana (8-12)')),
              DropdownMenuItem(value: 'tarde', child: Text('Tarde (13-21)')),
            ],
            onChanged: (value) async {
              setState(() => _selectedTurno = value!);
              await _loadAsistencias();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListado() {
    if (_asistencias.isEmpty) {
      return Center(
        child: Text('No hay asistencias registradas.',
            style: GoogleFonts.lato(fontSize: 18, color: Colors.white)),
      );
    }
    return ListView.builder(
      itemCount: _asistencias.length,
      itemBuilder: (context, index) {
        final asistencia = _asistencias[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: asistencia['tipo'] == 'entrada' ? Colors.green[200] : Colors.red[200],
                child: Icon(
                  asistencia['tipo'] == 'entrada' ? Icons.login : Icons.logout,
                  color: asistencia['tipo'] == 'entrada' ? Colors.green[900] : Colors.red[900],
                ),
              ),
              title: Text(
                '${asistencia['nombre']} ${asistencia['apellido']}',
                style: GoogleFonts.lato(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DNI: ${asistencia['dni']}'),
                  Text('Facultad: ${asistencia['siglas_facultad'] ?? '-'}'),
                  Text('Escuela: ${asistencia['siglas_escuela'] ?? '-'}'),
                  Text('Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(asistencia['fecha_hora'])}'),
                  Text('Tipo: ${asistencia['tipo']}'),
                  Text('Registrado por: ${asistencia['registrado_por']?['nombre'] ?? '-'}'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
