import 'package:flutter/material.dart';
// TODO: Reemplazar Firestore por API MongoDB
import 'package:google_fonts/google_fonts.dart';

class PendingExitScreen extends StatelessWidget {
  const PendingExitScreen({Key? key}) : super(key: key);

  Future<List<Map<String, dynamic>>> _getPendingVisitors() async {
    // Suponiendo que en la colección 'visitas' hay un campo 'salida_registrada' (bool)
    // final snapshot = await FirebaseFirestore.instance
    //     .collection('visitas')
    //     .where('salida_registrada', isEqualTo: false)
    //     .get();
    // TODO: Reemplazar por llamada a API REST de MongoDB
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.indigo.withOpacity(0.9),
        elevation: 8,
        title: Text(
          'Personas sin salida',
          style: GoogleFonts.lato(
            textStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
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
              const SizedBox(height: 16),
              // Header visual destacado
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(18),
                    child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Personas pendientes de salida',
                style: GoogleFonts.lato(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getPendingVisitors(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.celebration, color: Colors.green[300], size: 60),
                            const SizedBox(height: 12),
                            Text(
                              '¡No hay personas pendientes de salida!',
                              style: GoogleFonts.lato(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }
                    final visitors = snapshot.data!;
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: ListView.separated(
                        key: ValueKey(visitors.length),
                        itemCount: visitors.length,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final v = visitors[index];
                          return Card(
                            elevation: 6,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              leading: CircleAvatar(
                                backgroundColor: Colors.red[100],
                                radius: 28,
                                child: const Icon(Icons.person, color: Colors.red, size: 32),
                              ),
                              title: Text(
                                v['nombre'] ?? 'Desconocido',
                                style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 19, color: Colors.indigo[900]),
                              ),
                              subtitle: Text(
                                'DNI: ${v['dni'] ?? '-'}',
                                style: GoogleFonts.lato(fontSize: 16, color: Colors.blueGrey[700]),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
