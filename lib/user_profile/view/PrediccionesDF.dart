import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Predicción de Cultivos, Sequía e Inundaciones',
      theme: ThemeData(
        textTheme: GoogleFonts.latoTextTheme(),
        primarySwatch: Colors.teal,
      ),
      home: PredictionPage(),
    );
  }
}

class PredictionPage extends StatefulWidget {
  @override
  _PredictionPageState createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  String droughtPredictionResult = "";
  String floodPredictionResult = "";
  List<double> precipitationAverages = [];
  double? latitude;
  double? longitude;
  bool isLoadingLocation = true; // Flag to track loading state for location
  bool isLoadingFloodPrediction = false; // Flag for flood prediction loading
  bool isLoadingDroughtPrediction = false; // Flag for drought prediction loading

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // Fetch the current position of the device
  Future<void> _determinePosition() async {
    setState(() {
      isLoadingLocation = true;
    });
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return Future.error('Los servicios de ubicación están deshabilitados.');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return Future.error('Los permisos de ubicación están denegados');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return Future.error(
            'Los permisos de ubicación están permanentemente denegados.');
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
        isLoadingLocation = false; // Disable the location spinner
        _makePredictions(); // Start predictions after getting location
      });
    } catch (e) {
      print("Error obteniendo ubicación: $e");
      setState(() {
        isLoadingLocation = false;
      });
    }
  }

  // Start predictions automatically after getting the location
  void _makePredictions() {
    makeFloodPrediction();
    makeDroughtPrediction();
  }

  // Fetch data from NASA
  Future<Map<String, dynamic>> fetchNasaData(double latitude, double longitude) async {
    final startDate = "20241002";
    final endDate = "20241002";
    final parameters = "PRECTOTCORR,PS,QV2M,T2M,WS10M,WS50M";
    final nasaUrl = Uri.parse(
      'https://power.larc.nasa.gov/api/temporal/hourly/point'
      '?start=$startDate&end=$endDate&latitude=$latitude&longitude=$longitude'
      '&community=ag&parameters=$parameters&format=json&time-standard=lst'
    );

    final response = await http.get(nasaUrl);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener datos de la API de la NASA');
    }
  }

  // Fetch precipitation data from NASA
  Future<Map<String, dynamic>> fetchPrecipitationData(
      double latitude, double longitude, String startDate, String endDate) async {
    final nasaUrl = Uri.parse(
      'https://power.larc.nasa.gov/api/temporal/daily/point'
      '?parameters=PRECTOTCORR&community=RE&longitude=$longitude&latitude=$latitude'
      '&start=$startDate&end=$endDate&format=JSON',
    );

    final response = await http.get(nasaUrl);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener datos de precipitación de la API de la NASA');
    }
  }

  // Drought prediction logic
  Future<void> makeDroughtPrediction() async {
    setState(() {
      isLoadingDroughtPrediction = true;
    });
    try {
      if (latitude == null || longitude == null) {
        print('Ubicación no disponible.');
        return;
      }

      Map<String, dynamic> nasaData = await fetchNasaData(latitude!, longitude!);

      var parameterData = nasaData['properties']['parameter'];
      var precipitationData = parameterData['PRECTOTCORR'] ?? {};
      var temperatureData = parameterData['T2M'] ?? {};
      var humidityData = parameterData['QV2M'] ?? {};
      var pressureData = parameterData['PS'] ?? {};
      var wind10mData = parameterData['WS10M'] ?? {};
      var wind50mData = parameterData['WS50M'] ?? {};

      double avgPrecipitation = precipitationData.isNotEmpty
          ? precipitationData.values.reduce((a, b) => a + b) / precipitationData.length
          : 0.0;
      double avgTemp = temperatureData.isNotEmpty
          ? temperatureData.values.reduce((a, b) => a + b) / temperatureData.length
          : 0.0;
      double avgHumidity = humidityData.isNotEmpty
          ? humidityData.values.reduce((a, b) => a + b) / humidityData.length
          : 0.0;
      double avgPressure = pressureData.isNotEmpty
          ? pressureData.values.reduce((a, b) => a + b) / pressureData.length
          : 0.0;
      double avgWind10m = wind10mData.isNotEmpty
          ? wind10mData.values.reduce((a, b) => a + b) / wind10mData.length
          : 0.0;
      double avgWind50m = wind50mData.isNotEmpty
          ? wind50mData.values.reduce((a, b) => a + b) / wind50mData.length
          : 0.0;

      double t2mdew = avgTemp - ((100 - avgHumidity) / 5);
      double t2mwet = avgTemp - 2;
      double t2m_max = avgTemp + 5;
      double t2m_min = avgTemp - 5;
      double t2m_range = t2m_max - t2m_min;
      double ws10m_max = avgWind10m + 2;
      double ws10m_min = avgWind10m - 2;
      double ws10m_range = ws10m_max - ws10m_min;
      double ws50m_max = avgWind50m + 3;
      double ws50m_min = avgWind50m - 3;
      double ws50m_range = ws50m_max - ws50m_min;

      List<int> droughtData = [
        avgPrecipitation.round(),
        avgPressure.round(),
        avgHumidity.round(),
        avgTemp.round(),
        t2mdew.round(),
        t2mwet.round(),
        t2m_max.round(),
        t2m_min.round(),
        t2m_range.round(),
        avgTemp.round(),
        avgWind10m.round(),
        ws10m_max.round(),
        ws10m_min.round(),
        ws10m_range.round(),
        avgWind50m.round(),
        ws50m_max.round(),
        ws50m_min.round(),
        ws50m_range.round()
      ];

      final url = Uri.parse('http://172.172.12.7:5000/predecirDrought');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({'input': droughtData}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          droughtPredictionResult = data['prediction'].toString();
        });
      } else {
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() {
        isLoadingDroughtPrediction = false;
      });
    }
  }

  // Flood prediction logic
  Future<void> makeFloodPrediction() async {
    setState(() {
      isLoadingFloodPrediction = true;
    });
    try {
      if (latitude == null || longitude == null) {
        print('Ubicación no disponible.');
        return;
      }

      DateTime now = DateTime.now();
      List<double> monthlyAverages = [];

      for (int i = 0; i < 12; i++) {
        DateTime endDate = DateTime(now.year, now.month - i, 0);
        DateTime startDate = DateTime(endDate.year, endDate.month, 1);

        String startDateStr = DateFormat('yyyyMMdd').format(startDate);
        String endDateStr = DateFormat('yyyyMMdd').format(endDate);

        Map<String, dynamic> precipitationData = await fetchPrecipitationData(latitude!, longitude!, startDateStr, endDateStr);
        var precipitationValues = precipitationData['properties']['parameter']['PRECTOTCORR'] ?? {};

        double monthlyTotal = precipitationValues.isNotEmpty ? precipitationValues.values.reduce((a, b) => a + b) : 0.0;
        double monthlyAverage = precipitationValues.isNotEmpty ? monthlyTotal / precipitationValues.length : 0.0;

        monthlyAverages.insert(0, monthlyAverage);
      }

      setState(() {
        precipitationAverages = monthlyAverages;
      });

      final url = Uri.parse('http://172.172.12.7:5000/predecirFlood');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({'input': monthlyAverages}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          floodPredictionResult = data['prediction'].toString();
        });
      } else {
        print('Error al enviar la predicción: ${response.statusCode}');
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() {
        isLoadingFloodPrediction = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Predicción Ambiental'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade200, Colors.teal.shade800],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 200),
              SizedBox(width: 500),
              // Flood Prediction Section
              _buildPredictionSection(
                title: 'Predicción de Inundación',
                isLoading: isLoadingFloodPrediction,
                result: floodPredictionResult.isNotEmpty
                    ? (floodPredictionResult == "1"
                        ? 'Riesgo de Inundación'
                        : 'Sin riesgo de Inundación')
                    : 'No se obtuvo ninguna predicción de inundación',
              ),
              SizedBox(height: 20),
              // Drought Prediction Section
              _buildPredictionSection(
                title: 'Predicción de Sequía',
                isLoading: isLoadingDroughtPrediction,
                result: droughtPredictionResult.isNotEmpty
                    ? 'Nivel $droughtPredictionResult'
                    : 'No se obtuvo ninguna predicción de sequía',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPredictionSection({
    required String title,
    required bool isLoading,
    required String result,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 10),
        isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                color: Colors.white.withOpacity(0.9),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    result,
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ),
              ),
      ],
    );
  }
}
