import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  List<Map<String, dynamic>> areasData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAreasData();
  }

  Future<void> _fetchAreasData() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      QuerySnapshot snapshot =
          await firestore.collection('LineasTelefericos').get();

      List<Map<String, dynamic>> fetchedData = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'nombre': data['nombre'] ?? 'Sin nombre',
          'color': data['color'] ?? '#000000', // Default to black if color is missing
        };
      }).toList();

      setState(() {
        areasData = fetchedData;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos las dimensiones de la pantalla
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: Text('Dashboard de Cultivos')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : areasData.isEmpty
              ? Center(child: Text('No hay datos disponibles'))
              : SingleChildScrollView(
                  // Permite el scroll vertical
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildChartTitle('Distribución de Cultivos por Color'),
                        SizedBox(
                          height: screenHeight * 0.3, // Altura adaptada
                          child: _buildPieChartByColor(screenWidth),
                        ),
                        SizedBox(height: 20),
                        _buildChartTitle('Top 5 Cultivos por Nombre'),
                        SizedBox(
                          height: screenHeight * 0.3, // Altura adaptada
                          child: _buildBarChartByName(screenWidth),
                        ),
                        SizedBox(height: 20),
                        _buildChartTitle('Temperatura Promedio por Mes'),
                        SizedBox(
                          height: screenHeight * 0.3, // Altura adaptada
                          child: _buildLineChartTemperature(screenWidth),
                        ),
                        SizedBox(height: 20),
                        _buildChartTitle('Probabilidad de Sequía por Áreas'),
                        SizedBox(
                          height: screenHeight * 0.3, // Altura adaptada
                          child: _buildBarChartDroughtProbability(screenWidth),
                        ),
                        SizedBox(height: 20),
                        _buildChartTitle('Correlación Humedad vs Crecimiento'),
                        SizedBox(
                          height: screenHeight * 0.3, // Altura adaptada
                          child: _buildScatterChartHumidityGrowth(screenWidth),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  // Helper para construir el título del gráfico
  Widget _buildChartTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Gráfico de Torta para la Distribución de Colores adaptado
  Widget _buildPieChartByColor(double screenWidth) {
    List<PieChartSectionData> sections = [];
    Map<String, int> colorCount = {};

    // Contar los colores
    areasData.forEach((area) {
      String color = area['color'];
      colorCount[color] = (colorCount[color] ?? 0) + 1;
    });

    colorCount.forEach((color, count) {
      sections.add(PieChartSectionData(
        color: _parseColor(color),
        value: count.toDouble(),
        title: '$count',
        radius: screenWidth * 0.12, // Radio adaptado al ancho de la pantalla
        titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ));
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: PieChart(PieChartData(
          sections: sections,
          centerSpaceRadius: screenWidth * 0.08, // Espacio central adaptado
          sectionsSpace: 4, // Espacio entre las secciones
          pieTouchData: PieTouchData(enabled: false),
        )),
      ),
    );
  }

  // Gráfico de Barras para los primeros 5 cultivos agrupados por nombre adaptado
  Widget _buildBarChartByName(double screenWidth) {
    List<BarChartGroupData> barGroups = [];
    Map<String, int> nameCount = {};

    areasData.forEach((area) {
      String name = area['nombre'];
      nameCount[name] = (nameCount[name] ?? 0) + 1;
    });

    var top5Names = nameCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    top5Names = top5Names.take(5).toList();

    int index = 0;
    top5Names.forEach((entry) {
      barGroups.add(BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            color: Colors.teal,
            width: screenWidth * 0.04, // Ancho de la barra adaptado
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ));
      index++;
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BarChart(
          BarChartData(
            barGroups: barGroups,
            gridData: FlGridData(show: true),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 35,
                  getTitlesWidget: (value, meta) {
                    final name = top5Names[value.toInt()].key;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        name,
                        style: TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(enabled: false),
          ),
        ),
      ),
    );
  }

  // Función para validar y parsear color hexadecimal
  Color _parseColor(String colorStr) {
    try {
      if (colorStr.startsWith('#')) {
        return Color(int.parse(colorStr.replaceAll("#", "0xff")));
      }
    } catch (e) {
      print('Error parsing color: $colorStr, using default black.');
    }
    return Colors.black;
  }

  Widget _buildLineChartTemperature(double screenWidth) {
    List<FlSpot> temperatureData = [
      FlSpot(0, 15),
      FlSpot(1, 18),
      FlSpot(2, 22),
      FlSpot(3, 25),
      FlSpot(4, 28),
      FlSpot(5, 30),
      FlSpot(6, 32),
      FlSpot(7, 31),
      FlSpot(8, 29),
      FlSpot(9, 25),
      FlSpot(10, 20),
      FlSpot(11, 16),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: temperatureData,
                isCurved: true,
                color: Colors.red,
                barWidth: screenWidth * 0.01, // Ancho de la línea adaptado
                belowBarData: BarAreaData(
                    show: true, color: Colors.red.withOpacity(0.3)),
              ),
            ],
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    const months = [
                      'Ene',
                      'Feb',
                      'Mar',
                      'Abr',
                      'May',
                      'Jun',
                      'Jul',
                      'Ago',
                      'Sep',
                      'Oct',
                      'Nov',
                      'Dic'
                    ];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(months[value.toInt()],
                          style: TextStyle(fontSize: 12)),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarChartDroughtProbability(double screenWidth) {
    List<BarChartGroupData> barGroups = [
      BarChartGroupData(
          x: 0, barRods: [BarChartRodData(toY: 30, color: Colors.orange)]),
      BarChartGroupData(
          x: 1, barRods: [BarChartRodData(toY: 50, color: Colors.orange)]),
      BarChartGroupData(
          x: 2, barRods: [BarChartRodData(toY: 70, color: Colors.orange)]),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BarChart(
          BarChartData(
            barGroups: barGroups,
            gridData: FlGridData(show: true),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Text('Área ${(value + 1).toInt()}');
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScatterChartHumidityGrowth(double screenWidth) {
    List<ScatterSpot> scatterData = [
      ScatterSpot(30, 70),
      ScatterSpot(50, 85),
      ScatterSpot(70, 60),
      ScatterSpot(90, 50),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ScatterChart(
          ScatterChartData(
            scatterSpots: scatterData,
            gridData: FlGridData(show: true),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: Dashboard(),
  ));
}
