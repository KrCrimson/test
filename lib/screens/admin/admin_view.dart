import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config.dart';
// TODO: Reemplazar Firestore y FirebaseAuth por API MongoDB

import 'add_edit_user_dialog.dart';
import 'user_card.dart';
import 'admin_report_chart_screen.dart';
import 'admin_report_screen.dart';
import 'external_visits_report_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../login_screen.dart';
import 'pending_exit_screen.dart';

class AdminView extends StatefulWidget {
  const AdminView({Key? key}) : super(key: key);

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    // Si tienes lógica de cierre de sesión con tu backend, agrégala aquí
    // Por ahora solo navega al login
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildSideMenu(),
      appBar: AppBar(
        backgroundColor: Colors.indigo.withOpacity(0.95),
        elevation: 0,
        title: Text(
          'Dashboard Administrativo',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
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
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: Column(
          children: [
            _buildDashboardHeader(),
            _buildStatsCards(),
            _buildSearchSection(),
            Expanded(child: _buildGuardiaList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber[700],
        elevation: 8,
        onPressed: () {
          showAddEditUserDialog(
            context,
            userRole: 'guardia',
          );
        },
        tooltip: 'Agregar Usuario',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGuardiaList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey, width: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.people, color: Colors.indigo[700]),
                const SizedBox(width: 8),
                Text(
                  'Gestión de Guardias',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<http.Response>(
              future: http.get(Uri.parse('${Config.apiBaseUrl}/usuarios?role=guardia')),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: Colors.red[600]),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final List<dynamic> usersRaw = json.decode(snapshot.data!.body);
                final users = usersRaw.where((user) {
                  final nombre = user['nombre']?.toString().toLowerCase() ?? '';
                  final dni = user['dni']?.toString().toLowerCase() ?? '';
                  final facultad = user['puerta_acargo']?.toString().toLowerCase() ?? '';
                  return nombre.contains(_searchQuery.toLowerCase()) ||
                      dni.contains(_searchQuery.toLowerCase()) ||
                      facultad.contains(_searchQuery.toLowerCase());
                }).toList();

                // Group users by faculty
                Map<String, List<dynamic>> groupedUsers = {};
                List<dynamic> unassignedUsers = [];
                for (var user in users) {
                  final facultadRaw = user['puerta_acargo'];
                  final facultad = (facultadRaw == null || 
                                  facultadRaw.toString().trim().isEmpty || 
                                  facultadRaw.toString().toLowerCase() == 'sin asignar')
                      ? null
                      : facultadRaw;
                  if (facultad == null) {
                    unassignedUsers.add(user);
                  } else {
                    if (!groupedUsers.containsKey(facultad)) {
                      groupedUsers[facultad] = [];
                    }
                    groupedUsers[facultad]!.add(user);
                  }
                }

                final allSections = [
                  ...groupedUsers.keys.map((facultad) => 
                      _SectionData(facultad, groupedUsers[facultad]!)),
                ];
                if (unassignedUsers.isNotEmpty) {
                  allSections.add(_SectionData('Sin Puerta Asignada', unassignedUsers));
                }

                if (allSections.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron guardias',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: allSections.length,
                  itemBuilder: (context, index) {
                    final section = allSections[index];
                    final facultad = section.facultad;
                    final usersInFacultad = section.users;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: facultad == 'Sin Puerta Asignada' 
                                  ? Colors.red[50] 
                                  : Colors.indigo[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: facultad == 'Sin Puerta Asignada'
                                    ? Colors.red[200]!
                                    : Colors.indigo[200]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  facultad == 'Sin Puerta Asignada' 
                                      ? Icons.warning 
                                      : Icons.door_front_door,
                                  color: facultad == 'Sin Puerta Asignada'
                                      ? Colors.red[700]
                                      : Colors.indigo[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    facultad,
                                    style: GoogleFonts.roboto(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: facultad == 'Sin Puerta Asignada'
                                          ? Colors.red[800]
                                          : Colors.indigo[800],
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: facultad == 'Sin Puerta Asignada'
                                        ? Colors.red[100]
                                        : Colors.indigo[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${usersInFacultad.length}',
                                    style: GoogleFonts.lato(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: facultad == 'Sin Puerta Asignada'
                                          ? Colors.red[800]
                                          : Colors.indigo[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: usersInFacultad.length,
                          itemBuilder: (context, index) {
                            final user = usersInFacultad[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2),
                              child: UserCard(
                                user: user,
                                onEdit: () => showAddEditUserDialog(
                                  context,
                                  user: user,
                                  userRole: 'guardia',
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideMenu() {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.admin_panel_settings,
                      size: 40,
                      color: Colors.indigo[700],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Administrador',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                    onTap: () {
                      Navigator.pop(context);
                    },
                    isActive: true,
                  ),
                  _buildDrawerItem(
                    icon: Icons.bar_chart,
                    title: 'Reportes de Asistencias',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AdminReportChartScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.analytics,
                    title: 'Reporte General',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AdminReportScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.people,
                    title: 'Visitas Externas',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ExternalVisitsReportScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.pending_actions,
                    title: 'Salidas Pendientes',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PendingExitScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(color: Colors.white54),
                  _buildDrawerItem(
                    icon: Icons.logout,
                    title: 'Cerrar Sesión',
                    onTap: () {
                      Navigator.pop(context);
                      _signOut();
                    },
                    isLogout: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isActive = false,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isActive 
            ? Colors.white.withOpacity(0.2)
            : Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isLogout ? Colors.red[300] : Colors.white,
        ),
        title: Text(
          title,
          style: GoogleFonts.lato(
            color: isLogout ? Colors.red[300] : Colors.white,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildDashboardHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.admin_panel_settings,
              color: Colors.indigo[700],
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Bienvenido, Administrador!',
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Gestiona tu sistema de seguridad',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FutureBuilder<http.Response>(
            future: http.get(Uri.parse('${Config.apiBaseUrl}/usuarios?role=guardia')),
        builder: (context, snapshot) {
          int totalGuardias = 0;
          int guardiasAsignados = 0;
          if (snapshot.hasData && snapshot.data!.statusCode == 200) {
            final List<dynamic> users = json.decode(snapshot.data!.body);
            totalGuardias = users.length;
            guardiasAsignados = users
                .where((user) => user['puerta_acargo'] != null &&
                    user['puerta_acargo'].toString().trim().isNotEmpty &&
                    user['puerta_acargo'].toString().toLowerCase() != 'sin asignar')
                .length;
          }
          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Guardias',
                  totalGuardias.toString(),
                  Icons.security,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Asignados',
                  guardiasAsignados.toString(),
                  Icons.assignment_turned_in,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Sin Asignar',
                  (totalGuardias - guardiasAsignados).toString(),
                  Icons.assignment_late,
                  Colors.orange,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          Text(
            title,
            style: GoogleFonts.lato(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search, color: Colors.indigo),
            labelText: 'Buscar (Nombre, DNI, Facultad)',
            labelStyle: TextStyle(color: Colors.blueGrey[600]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.0),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
      ),
    );
  }
}

class _SectionData {
  final String facultad;
  final List<dynamic> users;
  _SectionData(this.facultad, this.users);
}
