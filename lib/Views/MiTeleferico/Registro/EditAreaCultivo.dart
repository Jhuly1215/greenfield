import 'dart:ui' as ui;
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gmaps/.env.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_gmaps/Controllers/MiTeleferico/AreaCultivoController.dart';
import 'package:flutter_gmaps/models/AreaCultivo/AreaCultivo.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class EditarLineaScreen extends StatefulWidget {
  final AreaCultivo linea;

  EditarLineaScreen({required this.linea});

  @override
  _EditarLineaScreenState createState() => _EditarLineaScreenState();
}

class _EditarLineaScreenState extends State<EditarLineaScreen> {
  final List<Marker> _newMarkers = [];
  final List<LatLng> _stations = [];
  final List<Polygon> _newPolygons = [];
  GoogleMapController? _mapController;
  Color _selectedColor = Colors.black;
  bool _colorSelected = false;
  TextEditingController _lineNameController = TextEditingController();
  TextEditingController _cultivoController = TextEditingController(); // Controlador para el cultivo
  final AreaCultivoController _firebaseController = AreaCultivoController();

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(-16.488997, -68.1248959),
    zoom: 11.5,
  );

  @override
  void initState() {
    super.initState();
    _lineNameController.text = widget.linea.nombre;
    _cultivoController.text = widget.linea.cultivo; // Setear el cultivo actual
    _selectedColor = Color(int.parse('0xff${widget.linea.color.substring(1)}'));
    _colorSelected = true;
    _stations.addAll(widget.linea.puntoarea.map((e) => LatLng(e.latitud, e.longitud)));
    _loadMarkers();
    _updatePolygon();
  }

  Future<void> _loadMarkers() async {
    final markerIcon = await _createCustomMarkerBitmap(_selectedColor);

    for (var punto in widget.linea.puntoarea) {
      final markerId = MarkerId(punto.id);

      final marker = Marker(
        markerId: markerId,
        position: LatLng(punto.latitud, punto.longitud),
        icon: markerIcon,
        draggable: true,
        onDragEnd: (newPosition) {
          _updateStationPosition(punto, newPosition);
        },
        onTap: () {
          _confirmDeleteMarker(punto);
        },
      );

      _newMarkers.add(marker);
    }

    setState(() {});
  }

  void _updateStationPosition(PuntoArea punto, LatLng newPosition) {
    setState(() {
      punto.latitud = newPosition.latitude;
      punto.longitud = newPosition.longitude;

      final List<Marker> updatedMarkers = [];
      for (var marker in _newMarkers) {
        if (marker.markerId == MarkerId(punto.id)) {
          final updatedMarker = Marker(
            markerId: marker.markerId,
            position: newPosition,
            icon: marker.icon,
            draggable: marker.draggable,
            onTap: marker.onTap,
            onDragEnd: marker.onDragEnd,
          );
          updatedMarkers.add(updatedMarker);
        } else {
          updatedMarkers.add(marker);
        }
      }

      _newMarkers
        ..clear()
        ..addAll(updatedMarkers);
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _confirmDeleteMarker(PuntoArea punto) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Eliminar punto'),
          content: Text('¿Estás seguro de que deseas eliminar este punto?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteStation(punto);
                Navigator.of(context).pop();
              },
              child: Text('Eliminar'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        );
      },
    );
  }

  void _deleteStation(PuntoArea punto) {
    setState(() {
      final index = _stations.indexWhere((pos) => pos.latitude == punto.latitud && pos.longitude == punto.longitud);
      if (index != -1) {
        _stations.removeAt(index);
        _newMarkers.removeWhere((marker) => marker.markerId.value == punto.id);
        _updatePolygon();
      }
    });
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

    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image img = await picture.toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  void _saveLinea() async {
    if (_lineNameController.text.isNotEmpty && _stations.isNotEmpty) {
      final puntosarea = _stations.asMap().entries.map((entry) {
        final index = entry.key;
        final LatLng pos = entry.value;
        final existingPunto = widget.linea.puntoarea.firstWhere(
          (p) => p.latitud == pos.latitude && p.longitud == pos.longitude,
          orElse: () => PuntoArea(id: Uuid().v4(), longitud: pos.longitude, latitud: pos.latitude, orden: index),
        );
        return PuntoArea(
          id: existingPunto.id,
          longitud: pos.longitude,
          latitud: pos.latitude,
          orden: index,
        );
      }).toList();

      final linea = AreaCultivo(
        id: widget.linea.id,
        nombre: _lineNameController.text,
        color: '#${_selectedColor.value.toRadixString(16).substring(2)}',
        cultivo: _cultivoController.text,  // Guardar el cultivo actualizado
        puntoarea: puntosarea,
      );

      await _firebaseController.updateLineaTeleferico(linea.id, linea);

      setState(() {
        _newMarkers.clear();
        _newPolygons.clear();
        _stations.clear();
        _lineNameController.clear();
        _colorSelected = false;
      });

      Navigator.of(context).pop();
    }
  }

  void _updatePolygon() {
    _newPolygons.clear();

    if (_stations.isNotEmpty) {
      final polygon = Polygon(
        polygonId: PolygonId('new_polygon'),
        points: _stations,
        strokeColor: Colors.black,
        strokeWidth: 3,
        fillColor: _selectedColor.withOpacity(0.3),
      );
      _newPolygons.add(polygon);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Area de Cultivo'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveLinea,
          ),
        ],
      ),
      body: _colorSelected ? _buildMapScreen() : _buildColorSelectionScreen(),
    );
  }

  Widget _buildColorSelectionScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _lineNameController,
              decoration: InputDecoration(labelText: 'Nombre del Area'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _cultivoController,
              decoration: InputDecoration(labelText: 'Cultivo'),
            ),
            SizedBox(height: 10),
            Text('Seleccionar Color del Area', style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            ColorPicker(
              pickerColor: _selectedColor,
              onColorChanged: (color) {
                setState(() {
                  _selectedColor = color;
                });
              },
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_lineNameController.text.isNotEmpty) {
                  setState(() {
                    _colorSelected = true;
                  });
                }
              },
              child: Text('Siguiente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapScreen() {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: _initialCameraPosition,
          onMapCreated: _onMapCreated,
          markers: Set.from(_newMarkers),
          polygons: Set.from(_newPolygons),
          onTap: (pos) {
            _addStation(pos);
          },
        ),
      ],
    );
  }

  void _addStation(LatLng pos) {
    // Agregar una estación nueva
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Agregar punto de área'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final markerIcon = await _createCustomMarkerBitmap(_selectedColor);
                setState(() {
                  final marker = Marker(
                    markerId: MarkerId(Uuid().v4()), // Usar un nuevo ID
                    position: pos,
                    icon: markerIcon,
                    draggable: true,
                    onDragEnd: (newPosition) => _updateStationPosition(
                      PuntoArea(id: Uuid().v4(), latitud: pos.latitude, longitud: pos.longitude, orden: _stations.length),
                      newPosition,
                    ),
                  );
                  _newMarkers.add(marker);
                  _stations.add(pos);
                  _updatePolygon();
                });
                Navigator.of(context).pop();
              },
              child: Text('Agregar'),
            ),
          ],
        );
      },
    );
  }
}
