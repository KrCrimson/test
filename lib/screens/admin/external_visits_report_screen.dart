import 'package:flutter/material.dart';
// TODO: Reemplazar Firestore por API MongoDB

import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class ExternalVisitsReportScreen extends StatefulWidget {
  const ExternalVisitsReportScreen({Key? key}) : super(key: key);

  @override
  State<ExternalVisitsReportScreen> createState() => _ExternalVisitsReportScreenState();
}

class _ExternalVisitsReportScreenState extends State<ExternalVisitsReportScreen> {
  String _selectedTimeRange = 'day'; // Default time range
  String _selectedChartType = 'pie'; // Default chart type
  String _selectedView = 'chart'; // Nuevo: chart o list
  List<Map<String, dynamic>> _visitData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadVisitData();
  }

  Future<void> _loadVisitData() async {
    setState(() {
      _isLoading = true;
      _visitData = [];
    });

    try {
      // Query query = FirebaseFirestore.instance.collection('visitas');
      // TODO: Reemplazar por llamada a API REST de MongoDB

      final now = DateTime.now();
      if (_selectedTimeRange == 'day') {
        // query = query.where('fecha_hora', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(now.year, now.month, now.day)));
      } else if (_selectedTimeRange == 'week') {
        // query = query.where('fecha_hora', isGreaterThanOrEqualTo: Timestamp.fromDate(now.subtract(const Duration(days: 7))));
      } else if (_selectedTimeRange == 'month') {
        // query = query.where('fecha_hora', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(now.year, now.month, 1)));
      }

      // final snapshot = await query.get();

      setState(() {
        // _visitData = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _visitData = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: ${e.toString()}')),
      );
    }
  }

  Widget _buildChart() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_visitData.isEmpty) {
      return const Center(child: Text('No visit data available.'));
    }

    if (_selectedChartType == 'pie') {
      return _buildPieChart();
    } else if (_selectedChartType == 'bar') {
      return _buildBarChart();
    }

    return const Center(child: Text('Invalid chart type.'));
  }

  Widget _buildPieChart() {
    Map<String, int> visitCounts = {};
    for (var visit in _visitData) {
      final name = visit['nombre'] ?? 'Desconocido';
      visitCounts[name] = (visitCounts[name] ?? 0) + 1;
    }

    List<PieChartSectionData> sections = [];
    int totalVisits = visitCounts.values.fold(0, (sum, count) => sum + count);
    final colorList = [
      Colors.indigo,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.amber,
    ];
    int colorIndex = 0;
    visitCounts.forEach((name, count) {
      final percentage = (count / totalVisits) * 100;
      sections.add(
        PieChartSectionData(
          value: percentage,
          title: '${name.split(' ')[0]} ($count)\n${percentage.toStringAsFixed(1)}%',
          color: colorList[colorIndex % colorList.length],
          radius: 60,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
      colorIndex++;
    });

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 40,
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        pieTouchData: PieTouchData(
          enabled: true,
          touchCallback: (event, response) {},
        ),
      ),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildBarChart() {
    Map<String, int> visitCounts = {};
    for (var visit in _visitData) {
      final name = visit['nombre'] ?? 'Desconocido';
      visitCounts[name] = (visitCounts[name] ?? 0) + 1;
    }

    List<BarChartGroupData> barGroups = [];
    final colorList = [
      Colors.indigo,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.amber,
    ];
    int colorIndex = 0;
    visitCounts.forEach((name, count) {
      barGroups.add(
        BarChartGroupData(
          x: visitCounts.keys.toList().indexOf(name),
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(colors: [
                colorList[colorIndex % colorList.length],
                colorList[(colorIndex + 1) % colorList.length].withOpacity(0.7),
              ]),
              width: 18,
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 0,
                color: Colors.grey[200],
              ),
            ),
          ],
        ),
      );
      colorIndex++;
    });

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < visitCounts.keys.toList().length) {
                  final name = visitCounts.keys.toList()[index];
                  final count = visitCounts[name] ?? 0;
                  final shortName = name.length > 10 ? name.substring(0, 10) + '…' : name;
                  return Transform.rotate(
                    angle: -0.6,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          shortName,
                          style: const TextStyle(fontSize: 9, color: Colors.black),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '($count)',
                          style: const TextStyle(fontSize: 9, color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 38,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 10, color: Colors.black),
              ),
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.indigo[100] ?? Colors.indigo,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${visitCounts.keys.toList()[group.x]}\n',
                const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                children: [
                  TextSpan(
                    text: rod.toY.toStringAsFixed(0),
                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                  ),
                ],
              );
            },
          ),
        ),
        alignment: BarChartAlignment.spaceAround,
        maxY: visitCounts.values.isNotEmpty ? (visitCounts.values.reduce((a, b) => a > b ? a : b) * 1.2) : 10,
      ),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildExternalVisitorsList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.celebration, color: Colors.green[300], size: 60),
          const SizedBox(height: 12),
          Text(
            '¡No hay registros de externos!',
            style: GoogleFonts.lato(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.indigo.withOpacity(0.9),
        elevation: 8,
        title: Text(
          'Reporte de Visitas Externas',
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DropdownButton<String>(
                          value: _selectedTimeRange,
                          dropdownColor: Colors.white,
                          style: GoogleFonts.lato(color: Colors.indigo[900]),
                          items: const [
                            DropdownMenuItem(value: 'day', child: Text('Hoy')),
                            DropdownMenuItem(value: 'week', child: Text('Esta semana')),
                            DropdownMenuItem(value: 'month', child: Text('Este mes')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedTimeRange = value!;
                            });
                            _loadVisitData();
                          },
                        ),
                        DropdownButton<String>(
                          value: _selectedChartType,
                          dropdownColor: Colors.white,
                          style: GoogleFonts.lato(color: Colors.indigo[900]),
                          items: const [
                            DropdownMenuItem(value: 'pie', child: Text('Torta')),
                            DropdownMenuItem(value: 'bar', child: Text('Barras')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedChartType = value!;
                            });
                          },
                        ),
                        DropdownButton<String>(
                          value: _selectedView,
                          dropdownColor: Colors.white,
                          style: GoogleFonts.lato(color: Colors.indigo[900]),
                          items: const [
                            DropdownMenuItem(value: 'chart', child: Text('Gráfico')),
                            DropdownMenuItem(value: 'list', child: Text('Lista')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedView = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _selectedView == 'chart'
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: _buildChart(),
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: _buildExternalVisitorsList(),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
