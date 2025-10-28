import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../config.dart';

enum FiltroVisitas { dia, semana, mes, anio }

class UserAlarmDetailsScreen extends StatefulWidget {
  const UserAlarmDetailsScreen({super.key});

  @override
  State<UserAlarmDetailsScreen> createState() => _UserAlarmDetailsScreenState();
}

class _UserAlarmDetailsScreenState extends State<UserAlarmDetailsScreen> {
  FiltroVisitas _filtro = FiltroVisitas.dia;

  DateTime get _now => DateTime.now();

  DateTime get _startDate {
    switch (_filtro) {
      case FiltroVisitas.dia:
        return DateTime(_now.year, _now.month, _now.day);
      case FiltroVisitas.semana:
        final weekday = _now.weekday;
        return _now.subtract(Duration(days: weekday - 1));
      case FiltroVisitas.mes:
        return DateTime(_now.year, _now.month, 1);
      case FiltroVisitas.anio:
        return DateTime(_now.year, 1, 1);
    }
  }

  DateTime get _endDate {
    switch (_filtro) {
      case FiltroVisitas.dia:
        return DateTime(_now.year, _now.month, _now.day, 23, 59, 59, 999);
      case FiltroVisitas.semana:
        final weekday = _now.weekday;
        return _now.add(Duration(days: 7 - weekday, hours: 23, minutes: 59, seconds: 59, milliseconds: 999));
      case FiltroVisitas.mes:
        final nextMonth = DateTime(_now.year, _now.month + 1, 1);
        return nextMonth.subtract(const Duration(milliseconds: 1));
      case FiltroVisitas.anio:
        return DateTime(_now.year, 12, 31, 23, 59, 59, 999);
    }
  }

  Future<List<Map<String, dynamic>>> _getVisitas() async {
    final startIso = _startDate.toIso8601String();
    final endIso = _endDate.toIso8601String();
    final response = await http.get(
  Uri.parse('${Config.apiBaseUrl}/visitas?start=$startIso&end=$endIso'),
    );
    if (response.statusCode != 200) return [];
    final data = json.decode(response.body);
    return List<Map<String, dynamic>>.from(data.map((v) {
      final map = Map<String, dynamic>.from(v as Map);
      // Parsear fecha_hora
      final fechaHoraStr = map['fecha_hora'] ?? '';
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
  }

  Color _getColorByCount(int count) {
    if (count <= 2) return Colors.green;
    if (count <= 4) return Colors.amber;
    return Colors.red;
  }

  Future<void> _exportToCsv(List<Map<String, dynamic>> visitas) async {
    try {
      String csvContent = "DNI,Nombre,Asunto,Facultad,Guardia,Puerta,Fecha,Cantidad\n";
      for (var v in visitas) {
        DateTime? fecha;
        if (v['fecha_hora'] is DateTime) {
          fecha = v['fecha_hora'] as DateTime;
        } else {
          fecha = DateTime.tryParse(v['fecha_hora'].toString());
        }
        csvContent += '"${v['dni'] ?? ''}",'
                      '"${v['nombre'] ?? ''}",'
                      '"${v['asunto'] ?? ''}",'
                      '"${v['facultad'] ?? ''}",'
                      '"${v['guardia_nombre'] ?? ''}",'
                      '"${v['puerta'] ?? ''}",'
                      '"${fecha != null ? DateFormat('dd/MM/yyyy HH:mm').format(fecha) : ''}",'
                      '"${v['cantidad'] ?? ''}"\n';
      }
      final bytes = utf8.encode(csvContent);
      final file = XFile.fromData(
        Uint8List.fromList(bytes),
        mimeType: 'text/csv',
        name: 'visitas_externos_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
      );
      await Share.shareXFiles([file], text: 'Visitas de externos');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar: ${e.toString()}')),
      );
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
          'Visitas de Externos',
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
            child: PopupMenuButton<FiltroVisitas>(
              tooltip: 'Filtrar por rango',
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              icon: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.85),
                radius: 20,
                child: const Icon(Icons.filter_alt, color: Colors.deepPurple, size: 26),
              ),
              onSelected: (f) => setState(() => _filtro = f),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: FiltroVisitas.dia,
                  child: Row(
                    children: [Icon(Icons.today, color: Colors.blue), SizedBox(width: 8), Text('Hoy')],
                  ),
                ),
                const PopupMenuItem(
                  value: FiltroVisitas.semana,
                  child: Row(
                    children: [Icon(Icons.calendar_view_week, color: Colors.green), SizedBox(width: 8), Text('Esta semana')],
                  ),
                ),
                const PopupMenuItem(
                  value: FiltroVisitas.mes,
                  child: Row(
                    children: [Icon(Icons.calendar_month, color: Colors.orange), SizedBox(width: 8), Text('Este mes')],
                  ),
                ),
                const PopupMenuItem(
                  value: FiltroVisitas.anio,
                  child: Row(
                    children: [Icon(Icons.calendar_today, color: Colors.redAccent), SizedBox(width: 8), Text('Este año')],
                  ),
                ),
              ],
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
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _getVisitas(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final visitas = snapshot.data ?? [];
              if (visitas.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.celebration, color: Colors.green[300], size: 60),
                      const SizedBox(height: 12),
                      Text(
                        'No hay visitas registradas.',
                        style: GoogleFonts.lato(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              // Agrupa por DNI y cuenta visitas
              final Map<String, List<Map<String, dynamic>>> visitasPorDni = {};
              for (var visita in visitas) {
                final dni = visita['dni'] ?? '';
                if (!visitasPorDni.containsKey(dni)) {
                  visitasPorDni[dni] = [];
                }
                visitasPorDni[dni]!.add(visita);
              }
              final List<Map<String, dynamic>> resumenVisitas = visitasPorDni.entries.map((entry) {
                final dni = entry.key;
                final lista = entry.value;
                final ultimaVisita = lista.last;
                return {
                  'dni': dni,
                  'nombre': ultimaVisita['nombre'] ?? '',
                  'asunto': ultimaVisita['asunto'] ?? '',
                  'facultad': ultimaVisita['facultad'] ?? '',
                  'fecha_hora': ultimaVisita['fecha_hora'],
                  'guardia_nombre': ultimaVisita['guardia_nombre'] ?? '',
                  'puerta': ultimaVisita['puerta'] ?? '',
                  'cantidad': lista.length,
                };
              }).toList();
              return ListView.builder(
                itemCount: resumenVisitas.length,
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemBuilder: (context, index) {
                  final visita = resumenVisitas[index];
                  final color = _getColorByCount(visita['cantidad']);
                  final fecha = visita['fecha_hora'] is DateTime
                      ? visita['fecha_hora'] as DateTime
                      : DateTime.tryParse(visita['fecha_hora'].toString());
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(18),
                      border: Border(
                        left: BorderSide(color: color, width: 7),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      leading: CircleAvatar(
                        backgroundColor: color,
                        radius: 28,
                        child: Text(
                          visita['cantidad'].toString(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      title: Text(
                        visita['nombre'],
                        style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 19, color: Colors.black87),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 2),
                          Text('DNI: ${visita['dni']}', style: GoogleFonts.lato(fontSize: 15, color: Colors.blueGrey[800])),
                          Text('Asunto: ${visita['asunto']}', style: GoogleFonts.lato(fontSize: 15, color: Colors.indigo[700])),
                          Text('Facultad: ${visita['facultad']}', style: GoogleFonts.lato(fontSize: 15, color: Colors.deepPurple)),
                          Text('Guardia: ${visita['guardia_nombre']}', style: GoogleFonts.lato(fontSize: 15, color: Colors.teal[800])),
                          Text('Puerta: ${visita['puerta']}', style: GoogleFonts.lato(fontSize: 15, color: Colors.orange[800])),
                          if (fecha != null)
                            Text('Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(fecha)}', style: GoogleFonts.lato(fontSize: 13, color: Colors.grey[700])),
                        ],
                      ),
                      trailing: Icon(
                        Icons.person,
                        color: color,
                        size: 32,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getVisitas(),
        builder: (context, snapshot) {
          final visitas = snapshot.data ?? [];
          final Map<String, List<Map<String, dynamic>>> visitasPorDni = {};
          for (var visita in visitas) {
            final dni = visita['dni'] ?? '';
            if (!visitasPorDni.containsKey(dni)) {
              visitasPorDni[dni] = [];
            }
            visitasPorDni[dni]!.add(visita);
          }
          final resumenVisitas = visitasPorDni.entries.map((entry) {
            final dni = entry.key;
            final lista = entry.value;
            final ultimaVisita = lista.last;
            return {
              'dni': dni,
              'nombre': ultimaVisita['nombre'] ?? '',
              'asunto': ultimaVisita['asunto'] ?? '',
              'facultad': ultimaVisita['facultad'] ?? '',
              'fecha_hora': ultimaVisita['fecha_hora'],
              'guardia_nombre': ultimaVisita['guardia_nombre'] ?? '',
              'puerta': ultimaVisita['puerta'] ?? '',
              'cantidad': lista.length,
            };
          }).toList();
          return FloatingActionButton.extended(
            backgroundColor: Colors.indigo,
            icon: const Icon(Icons.download, color: Colors.white),
            label: const Text('Exportar CSV', style: TextStyle(color: Colors.white)),
            onPressed: resumenVisitas.isEmpty ? null : () => _exportToCsv(resumenVisitas),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
