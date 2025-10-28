import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class AlarmDetailsScreen extends StatelessWidget {
  const AlarmDetailsScreen({super.key});

  Future<List<dynamic>> _fetchUnrecordedExits() async {
    final response = await http.get(Uri.parse('http://localhost:3000/asistencias?tipo=entrada&estado=activo'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al cargar datos');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personas sin salida'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _fetchUnrecordedExits(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay personas sin salida.'));
          }

          final individuals = snapshot.data!;

          return ListView.builder(
            itemCount: individuals.length,
            itemBuilder: (context, index) {
              final data = individuals[index];
              final nombre = data['nombre'] ?? 'Desconocido';
              final apellido = data['apellido'] ?? 'Desconocido';
              final dni = data['dni'] ?? 'Sin DNI';
              DateTime? fechaHora;
              if (data['fecha_hora'] != null) {
                try {
                  fechaHora = DateTime.parse(data['fecha_hora']);
                } catch (_) {
                  fechaHora = null;
                }
              }

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: Text('$nombre $apellido'),
                  subtitle: Text(
                    'DNI: $dni\n'
                    'Fecha de entrada: ${fechaHora != null ? DateFormat('dd/MM/yyyy HH:mm').format(fechaHora) : 'Sin fecha'}',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
