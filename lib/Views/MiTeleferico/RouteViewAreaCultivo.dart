import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gmaps/.env.dart';
import 'package:flutter_gmaps/models/MiLinea/lineas_model.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_gmaps/models/MiTeleferico/AreaCultivo.dart';
import 'package:flutter_gmaps/Controllers/MiTeleferico/LineasTelefericoController.dart';
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gmaps/core/directions_repository.dart';
import 'package:flutter_gmaps/models/directions/directions_model.dart';

class RouteViewTeleferico extends ConsumerStatefulWidget {
  final LatLng originPosition;
  final LatLng destinationPosition;

  RouteViewTeleferico({required this.originPosition, required this.destinationPosition});

  @override
  _RouteViewTelefericoState createState() => _RouteViewTelefericoState();
}

class _RouteViewTelefericoState extends ConsumerState<RouteViewTeleferico> {
  late GoogleMapController _googleMapController;
  final LineaTelefericoController _lineaTelefericoController = LineaTelefericoController();
  List<AreaCultivo> _areasCultivo = [];
  Map<String, PuntoArea> _puntosarea = {};
  Map<String, List<String>> _grafo = {};
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  double _totalDistance = 0.0;
  final Set<String> _processedRoutes = {};
  final LatLng _calle1Obrajes = LatLng(-16.5235717, -68.1177334);

  @override
  void initState() {
    super.initState();
    _loadLineasTeleferico();
  }

  Future<void> _loadLineasTeleferico() async {
    _lineaTelefericoController.getLineasTelefericos().listen((lineas) {
      setState(() {
        _areasCultivo = lineas;
        _crearGrafoPuntosArea();
      });
    });
  }

  void _crearGrafoPuntosArea() {
    _puntosarea.clear();
    _grafo.clear();
    for (var area in _areasCultivo) {
      for (int i = 0; i < area.puntoarea.length - 1; i++) {
        final puntoActual = area.puntoarea[i];
        final puntoSiguiente = area.puntoarea[i + 1];
      
      }
    }
  }

  Future<BitmapDescriptor> _createCustomMarkerBitmap(Color color) async {
    final svgString = await rootBundle.loadString('assets/svgs/TelefericoIcon.svg');
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 130.0;

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final Paint borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, borderPaint);

    final DrawableRoot svgDrawableRoot = await svg.fromSvgString(svgString, svgString);
    svgDrawableRoot.scaleCanvasToViewBox(canvas, Size(size, size));
    svgDrawableRoot.clipCanvasToViewBox(canvas);
    svgDrawableRoot.draw(canvas, Rect.fromLTWH(0, 0, size, size));

    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  Future<BitmapDescriptor> _createCustomTransferMarkerBitmap(Color color1, Color color2) async {
    final svgString = await rootBundle.loadString('assets/svgs/TelefericoIcon.svg');
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 130.0;

    final Paint paint1 = Paint()
      ..color = color1
      ..style = PaintingStyle.fill;
    final Paint paint2 = Paint()
      ..color = color2
      ..style = PaintingStyle.fill;
    final Paint borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    canvas.drawArc(Rect.fromCircle(center: Offset(size / 2, size / 2), radius: size / 2), -pi / 2, pi, true, paint1);
    canvas.drawArc(Rect.fromCircle(center: Offset(size / 2, size / 2), radius: size / 2), pi / 2, pi, true, paint2);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, borderPaint);

    final DrawableRoot svgDrawableRoot = await svg.fromSvgString(svgString, svgString);
    svgDrawableRoot.scaleCanvasToViewBox(canvas, Size(size, size));
    svgDrawableRoot.clipCanvasToViewBox(canvas);
    svgDrawableRoot.draw(canvas, Rect.fromLTWH(0, 0, size, size));

    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  Future<BitmapDescriptor> _createCustomBusMarkerBitmap() async {
    // Create a picture recorder to draw the icon
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 130.0;
    final Paint paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    // Draw a circle for the background
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);

    // Draw the bus icon
    TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.directions_bus.codePoint),
      style: TextStyle(
        fontSize: 80.0,
        fontFamily: Icons.directions_bus.fontFamily,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2));

    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  Future<List<LatLng>> _getRouteCoordinates(LatLng origin, LatLng destination) async {
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$googleAPIKey';
    final response = await http.get(Uri.parse(url));
    final jsonResponse = json.decode(response.body);

    if (jsonResponse['status'] == 'OK') {
      final points = jsonResponse['routes'][0]['overview_polyline']['points'];
      _totalDistance += jsonResponse['routes'][0]['legs'][0]['distance']['value'] / 1000; // Convert meters to kilometers
      return _decodePolyline(points);
    } else {
      return [];
    }
  }

  List<LatLng> _decodePolyline(String poly) {
    var list = poly.codeUnits;
    var lList = [];
    int index = 0;
    int len = poly.length;
    int c = 0;

    do {
      var shift = 0;
      int result = 0;

      do {
        c = list[index] - 63;
        result |= (c & 0x1F) << (shift * 5);
        index++;
        shift++;
      } while (c >= 32);

      if (result & 1 == 1) {
        result = ~result;
      }
      var result1 = (result >> 1) * 0.00001;
      lList.add(result1);
    } while (index < len);

    for (var i = 2; i < lList.length; i++) lList[i] += lList[i - 2];

    List<LatLng> points = [];

    for (var i = 0; i < lList.length; i += 2) {
      points.add(LatLng(lList[i], lList[i + 1]));
    }

    return points;
  }


Future<void> _addPolyline(List<LatLng> puntos) async {
  final busMarkerIcon = await _createCustomBusMarkerBitmap();
  for (int i = 0; i < puntos.length - 1; i++) {
    final directions = await DirectionsRepository().getDirections(
      origin: puntos[i],
      destination: puntos[i + 1],
    );

    if (directions != null) {
      setState(() {
        _polylines.add(
          Polyline(
            polylineId: PolylineId('bus_${directions.bounds.toString()}'),
            color: Colors.blue,
            width: 5,
            points: directions.polylinePoints.map((e) => LatLng(e.latitude, e.longitude)).toList(),
          ),
        );

        _markers.add(Marker(
          markerId: MarkerId('bus_marker_${puntos[i]}'),
          position: puntos[i],
          icon: busMarkerIcon,
          infoWindow: InfoWindow(
            title: 'Parada de bus',
            snippet: 'Punto ${i + 1}',
          ),
        ));
      });
    }
  }
}
Set<Polygon> _polygons = {};

void _mostrarAreaEnMapa(List<PuntoArea> puntosArea) {
  // Crear un polígono a partir de los puntos marcados
  final List<LatLng> puntosLatLng = puntosArea.map((punto) => LatLng(punto.latitud, punto.longitud)).toList();

  final Polygon areaPoligono = Polygon(
    polygonId: PolygonId('area_${DateTime.now().millisecondsSinceEpoch}'),
    points: puntosLatLng,
    strokeColor: Colors.blueAccent, // Color del borde
    strokeWidth: 3, // Grosor del borde
    fillColor: Colors.blue.withOpacity(0.3), // Color del relleno con opacidad
  );

  setState(() {
    // Agregar el nuevo polígono al set de polígonos
    _polygons.add(areaPoligono);
  });
}



  double _distanciaEntreEstaciones(String nombreA, String nombreB) {
    final estacionA = _puntosarea[nombreA]!;
    final estacionB = _puntosarea[nombreB]!;
    return Geolocator.distanceBetween(
      estacionA.latitud,
      estacionA.longitud,
      estacionB.latitud,
      estacionB.longitud,
    );
  }

  double _getDouble(dynamic value) {
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else {
      throw ArgumentError('El valor no es ni int ni double');
    }
  }

  double _parseDistance(String distance) {
    final parts = distance.split(' ');
    if (parts.length < 2) return 0.0;

    final value = double.tryParse(parts[0]);
    if (value == null) return 0.0;

    if (parts[1].toLowerCase().contains('km')) {
      return value;
    } else if (parts[1].toLowerCase().contains('m')) {
      return value / 1000.0;
    } else {
      return 0.0;
    }
  }
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Ruta de Teleférico'),
    ),
    body: Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(-16.4897, -68.1193),
            zoom: 14.5,
          ),
          onMapCreated: (controller) {
            _googleMapController = controller;
          },
          markers: _markers,
          polylines: _polylines,
        ),
        Positioned(
          bottom: 50,
          left: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 6.0,
              horizontal: 12.0,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 6.0,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ruta',
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            
              ],
            ),
          ),
        ),
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 6.0,
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              
            ),
          ),
        ),
      ],
    ),
  );
}

}
