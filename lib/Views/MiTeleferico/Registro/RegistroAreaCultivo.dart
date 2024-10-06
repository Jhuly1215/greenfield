import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gmaps/.env.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_gmaps/Controllers/MiTeleferico/AreaCultivoController.dart';
import 'package:flutter_gmaps/models/AreaCultivo/AreaCultivo.dart';
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
 final List<Polygon> _newPolygons = [];
  GoogleMapController? _mapController;
  String _selectedColorName = '';
  Color _selectedColor = Colors.black;
  bool _colorSelected = false;
  TextEditingController _lineNameController = TextEditingController();
  final AreaCultivoController _firebaseController = AreaCultivoController();
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
        _loadMarkersAndPolygons();
      });
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _loadMarkersAndPolygons();
  }

  Future<void> _loadMarkersAndPolygons() async {
  _newMarkers.clear();
  _newPolygons.clear();

  for (var linea in _areasCultivo) {
    // Crear los markers
    for (var puntoarea in linea.puntoarea) {
      final markerIcon = await _createCustomMarkerBitmap(Color(int.parse('0xff${linea.color.substring(1)}')));

      final marker = Marker(
        markerId: MarkerId('${puntoarea.latitud},${puntoarea.longitud}'),
        position: LatLng(puntoarea.latitud, puntoarea.longitud),
        icon: markerIcon,
      );
      _newMarkers.add(marker);
    }

    // Crear el polígono
    final polygon = Polygon(
      polygonId: PolygonId('polygon_${linea.nombre}'),
      points: linea.puntoarea.map((punto) => LatLng(punto.latitud, punto.longitud)).toList(),
      strokeColor: Colors.black,
      strokeWidth: 3,
      fillColor: Color(int.parse('0xff${linea.color.substring(1)}')).withOpacity(0.3),
    );
    _newPolygons.add(polygon);
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
    final markerIcon = await _createCustomMarkerBitmap(_selectedColor);

    setState(() {
      // Añadir el nuevo marker a la lista de markers
      final marker = Marker(
        markerId: MarkerId(pos.toString()),
        position: pos,
        icon: markerIcon,
      );
      _newMarkers.add(marker);
      
      // Añadir la nueva posición a la lista de estaciones
      _stations.add(pos);

      // Llamar a la función que actualiza el polígono con los nuevos puntos
      _updatePolygon();
    });
  }
  

  void _editStation(LatLng pos, String currentName, String currentLocation) {

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          title: Text('Editar Estación'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            
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
                   

                    final updatedMarker = Marker(
                      markerId: MarkerId(pos.toString()),
                      position: pos,
                      
                      icon: _newMarkers[index].icon,
                      
                    );

                    _newMarkers[index] = updatedMarker;
                    _updatePolygon();
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
                
                    _newMarkers.removeAt(index);
                    _updatePolygon();
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
    final svgString = await rootBundle.loadString('assets/svgs/radio_button_unchecked.svg');
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 50.0;

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final Paint borderPaint = Paint()
      ..color = const ui.Color.fromARGB(255, 97, 97, 97)
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
      _newPolygons.clear();
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
  void _updatePolygon() {
    _newPolygons.clear(); // Limpiar los polígonos anteriores

    if (_stations.isNotEmpty) {
      final polygon = Polygon(
        polygonId: PolygonId('new_polygon'),
        points: _stations, // Usar los puntos actualizados de las estaciones
        strokeColor: Colors.black,
        strokeWidth: 3,
        fillColor: _selectedColor.withOpacity(0.3), // Color con opacidad
      );
      _newPolygons.add(polygon); // Añadir el nuevo polígono a la lista
    }

    setState(() {}); // Actualizar el estado para reflejar los cambios
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrar area de cultivo'),
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
              decoration: InputDecoration(labelText: 'Nombre del Area de Cultivo'),
            ),
            SizedBox(height: 10),
            Text('Seleccionar color del Area', style: TextStyle(fontSize: 16)),
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
      polygons: Set.from(_newPolygons),
      onTap: _addStation,
    );
  }
}
