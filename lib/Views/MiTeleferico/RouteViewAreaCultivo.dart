import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gmaps/.env.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_gmaps/models/AreaCultivo/AreaCultivo.dart';
import 'package:flutter_gmaps/Controllers/MiTeleferico/AreaCultivoController.dart';
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
  final AreaCultivoController _lineaTelefericoController = AreaCultivoController();
  List<AreaCultivo> _areasCultivo = [];
  Map<String, PuntoArea> _puntosarea = {};
  Map<String, List<String>> _grafo = {};
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  double _totalDistance = 0.0;
  final Set<String> _processedRoutes = {};

  @override
  void initState() {
    super.initState();
    _loadLineasTeleferico();
  }

  Future<void> _loadLineasTeleferico() async {
    _lineaTelefericoController.getLineasTelefericos().listen((lineas) {
      setState(() {
        _areasCultivo = lineas;

      });
    });
  }
  void _onMapTap(LatLng tappedPoint) async {
    // Calcular el próximo orden del punto basado en el número actual de puntos
    int nuevoOrden = _puntosarea.length + 1;

    // Crear un nuevo punto del área con un id mejorado, usando prefijos y el orden
    String puntoId = 'Punto_${nuevoOrden}_${tappedPoint.latitude.toStringAsFixed(5)}_${tappedPoint.longitude.toStringAsFixed(5)}';

    // Crear el punto de área con la nueva estructura de id
    PuntoArea nuevoPunto = PuntoArea(
      id: puntoId, // id mejorado
      latitud: tappedPoint.latitude,
      longitud: tappedPoint.longitude,
      orden: nuevoOrden,
    );
    // Agregar el nuevo punto al área de cultivo
    _puntosarea[puntoId] = nuevoPunto;
    // Crear y agregar un marcador con ícono personalizado para el punto
    BitmapDescriptor customIcon = await _createCustomMarkerBitmap(Colors.blueAccent);
    Marker nuevoMarker = Marker(
      markerId: MarkerId(puntoId),
      position: tappedPoint,
      icon: customIcon,
      infoWindow: InfoWindow(title: 'Punto $nuevoOrden'),
    );

    setState(() {
      _markers.add(nuevoMarker);  // Agregar el marcador al mapa
      _mostrarAreaEnMapa(_puntosarea.values.toList());  // Actualizar el polígono
    });
  }

  Future<BitmapDescriptor> _createCustomMarkerBitmap(Color color) async {
    final svgString = await rootBundle.loadString('assets/svgs/areaicon.svg');
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 80.0;
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
    // Actualizar los polígonos en el mapa
    _polygons.add(areaPoligono);
  });
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
          onTap: _onMapTap,
          markers: _markers,
          polygons: _polygons,  // Añade el conjunto de polígonos al mapa
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
