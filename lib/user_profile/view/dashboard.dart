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
      QuerySnapshot snapshot = await firestore.collection('LineasTelefericos').get();

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

  // Función para validar y parsear color hexadecimal
  Color _parseColor(String colorStr) {
    try {
      if (colorStr.startsWith('#')) {
        // Convertimos el string hexadecimal a un int, reemplazando "#" por "0xff" para que sea válido
        return Color(int.parse(colorStr.replaceAll("#", "0xff")));
      }
    } catch (e) {
      print('Error parsing color: $colorStr, using default black.');
    }
    // Si falla, devolvemos un color por defecto (negro)
    return Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard de Cultivos')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : areasData.isEmpty
              ? Center(child: Text('No hay datos disponibles'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildChartTitle('Distribución de Cultivos por Color'),
                      Expanded(child: _buildPieChart()),
                      SizedBox(height: 20),
                      _buildChartTitle('Cantidad de Cultivos por Color (Bar Chart)'),
                      Expanded(child: _buildBarChart()),
                    ],
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

  // Gráfico de Torta para la Distribución de Colores
  Widget _buildPieChart() {
    List<PieChartSectionData> sections = [];
    Map<String, int> colorCount = {};

    // Contar los colores
    areasData.forEach((area) {
      String color = area['color'];
      colorCount[color] = (colorCount[color] ?? 0) + 1;
    });

    colorCount.forEach((color, count) {
      sections.add(PieChartSectionData(
        color: _parseColor(color), // Usamos la función de validación de color
        value: count.toDouble(),
        title: '$count',
        radius: 50, // Aumentamos el radio para separar mejor las secciones
        titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ));
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: PieChart(PieChartData(
          sections: sections,
          centerSpaceRadius: 40,
          sectionsSpace: 4, // Espacio entre las secciones
          pieTouchData: PieTouchData(enabled: false), // Desactivamos interacción
        )),
      ),
    );
  }

  // Gráfico de Barras para Cultivos agrupados por color
  Widget _buildBarChart() {
    List<BarChartGroupData> barGroups = [];
    Map<String, int> colorCount = {};

    // Contar los colores
    areasData.forEach((area) {
      String color = area['color'];
      colorCount[color] = (colorCount[color] ?? 0) + 1;
    });

    int index = 0;
    colorCount.forEach((color, count) {
      barGroups.add(BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            color: _parseColor(color), // Usamos la función de validación de color
            width: 16,
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
            gridData: FlGridData(show: true), // Mostramos líneas de la cuadrícula
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 35,
                  getTitlesWidget: (value, meta) {
                    final colorCode = colorCount.keys.elementAt(value.toInt());
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        colorCode,
                        style: TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis, // Evitamos superposición
                      ),
                    );
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(enabled: false), // Desactivamos interacción para mejor visualización
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
