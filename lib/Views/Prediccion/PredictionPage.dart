import 'package:flutter/material.dart';
import 'package:flutter_gmaps/Controllers/MiTeleferico/AreaCultivoController.dart';
import 'package:flutter_gmaps/Views/MiTeleferico/Registro/ListAreasCultivo.dart';
import 'package:flutter_gmaps/models/AreaCultivo/AreaCultivo.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:flutter_gmaps/Views/home_view.dart';
class PredictionPage extends StatefulWidget {
 final double latitude;
  final double longitude;
  final List<PuntoArea> puntosarea;
  final String color;
  final String nombre;  // Añadir nombre como variable final

  PredictionPage({
    required this.latitude, 
    required this.longitude, 
    required this.puntosarea,
    required this.color,
    required this.nombre,  // Asegúrate de recibir el nombre aquí
  });


  @override
  _PredictionPageState createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  Map<String, double> cropPredictionResult = {};
  bool isLoading = true; // Para controlar el estado de carga
  String selectedCultivo = '';
  
final AreaCultivoController areaController = AreaCultivoController();

  @override
  void initState() {
    super.initState();
    makeCropPrediction();
  }

  // Función para obtener datos de la NASA (para predicción de cultivos)
  Future<Map<String, dynamic>> fetchNasaData(
      double latitude, double longitude) async {
    final startDate = "20241002"; // Ajusta la fecha según sea necesario
    final endDate = "20241002";
    final parameters = "PRECTOTCORR,PS,QV2M,T2M,WS10M,WS50M";
    final nasaUrl = Uri.parse(
        'https://power.larc.nasa.gov/api/temporal/hourly/point'
        '?start=$startDate&end=$endDate&latitude=$latitude&longitude=$longitude'
        '&community=ag&parameters=$parameters&format=json&time-standard=lst');

    final response = await http.get(nasaUrl);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener datos de la API de la NASA');
    }
  }

  // Función para hacer la predicción de cultivos en el servidor Flask
  Future<void> makeCropPrediction() async {
    try {
      double latitude = widget.latitude;
      double longitude = widget.longitude;

      // 1. Obtener datos de la API de la NASA
      Map<String, dynamic> nasaData = await fetchNasaData(latitude, longitude);

      // 2. Extraer los datos de temperatura, humedad y precipitación de la API de la NASA
      var temperatureData = nasaData['properties']['parameter']['T2M'] ?? {};
      var humidityData = nasaData['properties']['parameter']['QV2M'] ?? {};
      var precipitationData =
          nasaData['properties']['parameter']['PRECTOTCORR'] ?? {};

      // Calcular promedios
      double temperatureAvg = temperatureData.isNotEmpty
          ? temperatureData.values.reduce((a, b) => a + b) /
              temperatureData.length
          : 0.0;
      double humidityAvg = humidityData.isNotEmpty
          ? humidityData.values.reduce((a, b) => a + b) / humidityData.length
          : 0.0;
      double precipitationAvg = precipitationData.isNotEmpty
          ? precipitationData.values.reduce((a, b) => a + b) /
              precipitationData.length
          : 0.0;

      // 3. Crear el vector de entrada para la predicción
      List<double> inputData = [
        100.0, // N
        90.0, // P
        100.0, // K
        temperatureAvg, // Temperatura
        7.0, // pH
        humidityAvg, // Humedad
        precipitationAvg // Precipitación
      ];

      // 4. Hacer la solicitud POST al servidor Flask
      final url = Uri.parse(
          'http://172.172.12.7:5000/predecirCrop'); // Cambia por tu IP del servidor Flask
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({'input': inputData}),
      );

      // 5. Verificar si la solicitud fue exitosa
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          cropPredictionResult = Map<String, double>.from(data);
          isLoading = false; // Terminar la carga
        });
      } else {
        print("Error: ${response.statusCode}");
        setState(() {
          isLoading = false; // Terminar la carga incluso si hay error
        });
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false; // Terminar la carga en caso de error
      });
    }
  }

  void _handleCultivoSelection(String cultivo, double probabilidad) async {
  // Alerta si la probabilidad es menor al 50%
  if (probabilidad < 0.50) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Advertencia'),
          content: Text('El cultivo seleccionado tiene una probabilidad de éxito inferior al 50%. Toma precauciones antes de continuar.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  // Marcar el cultivo como seleccionado y continuar
  setState(() {
    selectedCultivo = cultivo;
  });

  // Guardar el área de cultivo con el cultivo seleccionado
  await _saveAreaWithCultivo(cultivo);

  // Navegar a la pantalla de HomePage después de guardar
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => ListLineasTelefericoScreen()),  // Ajusta con tu pantalla de HomePage
  );
}

Future<void> _saveAreaWithCultivo(String cultivo) async {
  try {
    // Generar un ID único para el área de cultivo
    final String lineaId = Uuid().v4();

    // Crear el objeto AreaCultivo con los datos recibidos
    final linea = AreaCultivo(
      id: lineaId,  // Usar el ID generado para el área de cultivo
      nombre: widget.nombre,  // Acceder al nombre correctamente
      color: widget.color,  // El color seleccionado
      cultivo: cultivo,  // Guardar el tipo de cultivo seleccionado
      puntoarea: widget.puntosarea,  // Los puntos del área pasados desde la pantalla anterior
    );

    // Guardar la línea en Firestore
    await areaController.saveLineaTeleferico(linea);

    print("Área guardada con el cultivo seleccionado: $cultivo");
  } catch (e) {
    print("Error al guardar el área de cultivo: $e");
  }
}



  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Predicción de Cultivos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            isLoading
                ? Center(
                    // Usamos Center para centrar todo
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.green, // Indicador verde
                        ),
                        SizedBox(height: 20),
                        Text('Realizando predicción, por favor espera...'),
                      ],
                    ),
                  )
                : cropPredictionResult.isNotEmpty
                    ? Expanded(
                        child: ListView(
                          children: cropPredictionResult.entries.map((entry) {
                            final probabilidad = entry.value * 100;
                            return ListTile(
                              title: Text(entry.key),
                              subtitle: Text(
                                'Probabilidad: ${probabilidad.toStringAsFixed(2)}%',
                              ),
                              trailing: ElevatedButton(
                                onPressed: () => _handleCultivoSelection(
                                    entry.key, entry.value),
                                child: Text('Seleccionar'),
                              ),
                            );
                          }).toList(),
                        ),
                      )
                    : Center(
                        child:
                            Text('No se obtuvieron predicciones de cultivos.'),
                      ),
            if (selectedCultivo.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  'Cultivo seleccionado: $selectedCultivo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
