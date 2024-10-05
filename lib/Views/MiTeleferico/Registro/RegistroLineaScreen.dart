import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gmaps/.env.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_gmaps/Controllers/MiTeleferico/LineasTelefericoController.dart';
import 'package:flutter_gmaps/models/MiTeleferico/AreaCultivo.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart'; // Añadir esta importación para generar IDs únicos

class RegistroLineaScreen extends StatefulWidget {
  @override
  _RegistroLineaScreenState createState() => _RegistroLineaScreenState();
}

class _RegistroLineaScreenState extends State<RegistroLineaScreen> {
  final List<Marker> _newMarkers = [];
  final List<LatLng> _stations = [];
  final List<String> _stationNames = [];
  final List<String> _locationNames = [];
  final List<Polyline> _newPolylines = [];
  GoogleMapController? _mapController;
  String _selectedColorName = '';
  Color _selectedColor = Colors.black;
  bool _colorSelected = false;
  TextEditingController _lineNameController = TextEditingController();
  final LineaTelefericoController _firebaseController = LineaTelefericoController();
  List<AreaCultivo> _areasCultivo = [];

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(-16.488997, -68.1248959),
    zoom: 11.5,
  );

  @override
  void initState() {
    super.initState();
    _loadLineasTeleferico();
  }

  Future<void> _loadLineasTeleferico() async {
    _firebaseController.getLineasTelefericos().listen((lineas) {
      setState(() {
        _areasCultivo = lineas;
        _loadMarkersAndPolylines();
      });
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _loadMarkersAndPolylines();
  }

  Future<void> _loadMarkersAndPolylines() async {
    _newMarkers.clear();
    _newPolylines.clear();

    for (var linea in _areasCultivo) {
      for (var puntoarea in linea.puntoarea) {
        final markerIcon = await _createCustomMarkerBitmap(Color(int.parse('0xff${linea.color.substring(1)}')));

        final marker = Marker(
          markerId: MarkerId('${puntoarea.latitud},${puntoarea.longitud}'),
          position: LatLng(puntoarea.latitud, puntoarea.longitud),
          
          icon: markerIcon,
        );
        _newMarkers.add(marker);
      }

      if (linea.puntoarea.length > 1) {
        for (int i = 0; i < linea.puntoarea.length - 1; i++) {
          final color = Color(int.parse('0xff${linea.color.substring(1)}'));

          _newPolylines.add(Polyline(
            polylineId: PolylineId('border_polyline_${linea.nombre}_$i'),
            color: Colors.black,
            width: 9,
            points: [
              LatLng(linea.puntoarea[i].latitud, linea.puntoarea[i].longitud),
              LatLng(linea.puntoarea[i + 1].latitud, linea.puntoarea[i + 1].longitud),
            ],
          ));

          _newPolylines.add(Polyline(
            polylineId: PolylineId('polyline_${linea.nombre}_$i'),
            color: color,
            width: 5,
            points: [
              LatLng(linea.puntoarea[i].latitud, linea.puntoarea[i].longitud),
              LatLng(linea.puntoarea[i + 1].latitud, linea.puntoarea[i + 1].longitud),
            ],
          ));
        }
      }
    }

    setState(() {});
  }

  Future<String> _getGooglePlaceName(LatLng pos) async {
    final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${pos.latitude},${pos.longitude}&key=$googleAPIKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['results'] != null && jsonResponse['results'].length > 0) {
        return jsonResponse['results'][0]['formatted_address'];
      }
    }
    return '';
  }

  void _addStation(LatLng pos) async {
    final stationNameController = TextEditingController();
    final locationNameController = TextEditingController();
    final locationNameGoogle = await _getGooglePlaceName(pos);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          title: Text('Agregar Punto de Area'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nombre de la Ubicación Google: $locationNameGoogle'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final stationName = stationNameController.text;
                final locationName = locationNameController.text;

                if (stationName.isNotEmpty && locationName.isNotEmpty) {
                  final markerIcon = await _createCustomMarkerBitmap(_selectedColor);

                  setState(() {
                    _stationNames.add(stationName);
                    _locationNames.add(locationName);

                    final marker = Marker(
                      markerId: MarkerId(pos.toString()),
                      position: pos,
                      infoWindow: InfoWindow(title: stationName, snippet: locationName),
                      icon: markerIcon,
                      onTap: () {
                        _editStation(pos, stationName, locationName);
                      },
                    );
                    _newMarkers.add(marker);
                    _stations.add(pos);

                    _updatePolylines();
                  });

                  Navigator.of(context).pop();
                }
              },
              child: Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  void _editStation(LatLng pos, String currentName, String currentLocation) {
    final stationNameController = TextEditingController(text: currentName);
    final locationNameController = TextEditingController(text: currentLocation);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          title: Text('Editar Estación'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: stationNameController,
                decoration: InputDecoration(
                  labelText: 'Nombre de la Estación',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: locationNameController,
                decoration: InputDecoration(
                  labelText: 'Nombre de la Ubicación',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  final index = _stations.indexOf(pos);
                  if (index != -1) {
                    _stationNames[index] = stationNameController.text;
                    _locationNames[index] = locationNameController.text;

                    final updatedMarker = Marker(
                      markerId: MarkerId(pos.toString()),
                      position: pos,
                      infoWindow: InfoWindow(
                        title: stationNameController.text,
                        snippet: locationNameController.text,
                      ),
                      icon: _newMarkers[index].icon,
                      onTap: () {
                        _editStation(pos, stationNameController.text, locationNameController.text);
                      },
                    );

                    _newMarkers[index] = updatedMarker;
                    _updatePolylines();
                  }
                });
                Navigator.of(context).pop();
              },
              child: Text('Guardar'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  final index = _stations.indexOf(pos);
                  if (index != -1) {
                    _stations.removeAt(index);
                    _stationNames.removeAt(index);
                    _locationNames.removeAt(index);
                    _newMarkers.removeAt(index);
                    _updatePolylines();
                  }
                });
                Navigator.of(context).pop();
              },
              child: Text('Eliminar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        );
      },
    );
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

  void _saveLinea() async {
  if (_selectedColorName.isNotEmpty && _stations.isNotEmpty) {
    final puntosarea = _stations.asMap().entries.map((entry) {
      final index = entry.key;
      final LatLng pos = entry.value;

      // Generar un ID único para cada PuntoArea
      final String puntoId = Uuid().v4();

      return PuntoArea(
        id: puntoId,  // Asignar un ID único para el punto
        longitud: pos.longitude,
        latitud: pos.latitude,
        orden: index,
      );
    }).toList();

    // Generar un ID único para la nueva línea
    final String lineaId = Uuid().v4();

    final linea = AreaCultivo(
      id: lineaId,  // Usar el ID generado para la línea
      nombre: _selectedColorName,
      color: '#${_selectedColor.value.toRadixString(16).substring(2)}',  // Color en formato hexadecimal
      puntoarea: puntosarea,  // Asignar la lista de puntos de área
    );

    // Guardar la línea en Firestore
    await _firebaseController.saveLineaTeleferico(linea);

    setState(() {
      _newMarkers.clear();
      _newPolylines.clear();
      _stations.clear();
      _stationNames.clear();
      _locationNames.clear();
      _lineNameController.clear();
      _colorSelected = false;
    });

    // Recargar la lista de líneas
    _loadLineasTeleferico();
  }
}

  void _selectColorAndName() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _lineNameController,
                    decoration: InputDecoration(labelText: 'Nombre del Area del cultivo'),
                  ),
                  SizedBox(height: 10),
                  Text('Seleccionar Color del Area', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 10.0,
                    runSpacing: 10.0,
                    children: [
                      _buildColorOption(Colors.red, 'Rojo'),
                      _buildColorOption(Colors.green, 'Verde'),
                      _buildColorOption(Colors.blue, 'Azul'),
                      _buildColorOption(Colors.yellow, 'Amarillo'),
                      _buildColorOption(Colors.purple, 'Morado'),
                      _buildColorOption(Colors.orange, 'Naranja'),
                      _buildColorOption(Colors.pink, 'Rosa'),
                      GestureDetector(
                        onTap: () => _selectCustomColor(),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[200],
                            border: Border.all(color: Colors.black),
                          ),
                          child: Icon(Icons.add, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_lineNameController.text.isNotEmpty) {
                        setState(() {
                          _selectedColorName = _lineNameController.text;
                          _colorSelected = true;
                        });
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text('Siguiente'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildColorOption(Color color, String name) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = color;
        });
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: _selectedColor == color ? Colors.black : Colors.transparent, width: 2),
        ),
      ),
    );
  }

  void _selectCustomColor() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          title: Text('Seleccionar Color Personalizado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Seleccionar'),
            ),
          ],
        );
      },
    );
  }

  void _updatePolylines() {
    _newPolylines.clear();
    if (_stations.length > 1) {
      for (int i = 0; i < _stations.length - 1; i++) {
        _newPolylines.add(Polyline(
          polylineId: PolylineId('border_polyline_$i'),
          color: Colors.black,
          width: 9,
          points: [
            LatLng(_stations[i].latitude, _stations[i].longitude),
            LatLng(_stations[i + 1].latitude, _stations[i + 1].longitude),
          ],
        ));

        _newPolylines.add(Polyline(
          polylineId: PolylineId('polyline_$i'),
          color: _selectedColor,
          width: 5,
          points: [
            LatLng(_stations[i].latitude, _stations[i].longitude),
            LatLng(_stations[i + 1].latitude, _stations[i + 1].longitude),
          ],
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrar Línea de Teleférico'),
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
              decoration: InputDecoration(labelText: 'Nombre del Color de la Línea'),
            ),
            SizedBox(height: 10),
            Text('Seleccionar Color de la Línea', style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Wrap(
              spacing: 10.0,
              runSpacing: 10.0,
              children: [
                _buildColorOption(Colors.red, 'Rojo'),
                _buildColorOption(Colors.green, 'Verde'),
                _buildColorOption(Colors.blue, 'Azul'),
                _buildColorOption(Colors.yellow, 'Amarillo'),
                _buildColorOption(Colors.purple, 'Morado'),
                _buildColorOption(Colors.orange, 'Naranja'),
                _buildColorOption(Colors.pink, 'Rosa'),
                GestureDetector(
                  onTap: () => _selectCustomColor(),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.black),
                    ),
                    child: Icon(Icons.add, color: Colors.black),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_lineNameController.text.isNotEmpty) {
                  setState(() {
                    _selectedColorName = _lineNameController.text;
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
    return GoogleMap(
      initialCameraPosition: _initialCameraPosition,
      onMapCreated: _onMapCreated,
      markers: Set.from(_newMarkers),
      polylines: Set.from(_newPolylines),
      onTap: _addStation,
    );
  }
}
