import 'dart:ui' as ui;
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gmaps/.env.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_gmaps/Controllers/MiTeleferico/AreaCultivoController.dart';
import 'package:flutter_gmaps/models/MiTeleferico/AreaCultivo.dart';
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
  final List<String> _stationNames = [];
  final List<String> _locationNames = [];
  final List<Polyline> _newPolylines = [];
  GoogleMapController? _mapController;
  Color _selectedColor = Colors.black;
  bool _colorSelected = false;
  TextEditingController _lineNameController = TextEditingController();
  final AreaCultivoController _firebaseController = AreaCultivoController();
  int _startIndex = -1; // Indice de la estación de inicio para editar conexiones
  bool _editConnectionsMode = false; // Modo para editar conexiones

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(-16.488997, -68.1248959),
    zoom: 11.5,
  );

  @override
  void initState() {
    super.initState();
    _lineNameController.text = widget.linea.nombre;
    _selectedColor = Color(int.parse('0xff${widget.linea.color.substring(1)}'));
    _colorSelected = true;
    _stations.addAll(widget.linea.puntoarea.map((e) => LatLng(e.latitud, e.longitud)));
    _loadMarkers();
    _updatePolylines();
  }

  Future<void> _loadMarkers() async {
    final markerIcon = await _createCustomMarkerBitmap(_selectedColor);

    for (var punto in widget.linea.puntoarea) {
      final markerId = MarkerId(punto.id);  // Usar 'id' como MarkerId

      final marker = Marker(
        markerId: markerId,  // Usar el 'id' como MarkerId
        position: LatLng(punto.latitud, punto.longitud),
        icon: markerIcon,
        draggable: true,

        // Al hacer tap en el marcador
        onTap: () {
          if (_editConnectionsMode) {
            _setEndIndexForConnection(_stations.indexOf(LatLng(punto.latitud, punto.longitud)));
          }
        },

        // Al finalizar el arrastre, actualizar la posición de la estación
        onDragEnd: (newPosition) {
          _updateStationPosition(punto, newPosition);
        },
      );

      _newMarkers.add(marker);
    }

    setState(() {});
  }

  void _updateStationPosition(PuntoArea punto, LatLng newPosition) {
  // Actualizar la latitud y longitud del punto
    setState(() {
    punto.latitud = newPosition.latitude;
    punto.longitud = newPosition.longitude;

    // Crear una nueva lista de markers
    final List<Marker> updatedMarkers = [];

    // Iterar sobre los marcadores actuales y actualizar el que coincida con el 'id' del punto
    for (var marker in _newMarkers) {
      if (marker.markerId == MarkerId(punto.id)) {
        // Crear un nuevo marker con la nueva posición
        final updatedMarker = Marker(
          markerId: marker.markerId,
          position: newPosition, // Actualizar la posición
          infoWindow: marker.infoWindow, // Mantener el resto de los parámetros
          icon: marker.icon,
          draggable: marker.draggable,
          onTap: marker.onTap,
          onDragEnd: marker.onDragEnd,
        );
        updatedMarkers.add(updatedMarker); // Añadir el marker actualizado a la nueva lista
      } else {
        updatedMarkers.add(marker); // Añadir los marcadores no modificados
      }
    }

    // Reemplazar la lista original de _newMarkers con la nueva lista actualizada
    _newMarkers
      ..clear() // Limpiar la lista actual
      ..addAll(updatedMarkers); // Agregar los nuevos markers actualizados
  });
}

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
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
          title: Text('Agregar Estación'),
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
              SizedBox(height: 10),
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
                        if (_editConnectionsMode) {
                          _setEndIndexForConnection(_stations.indexOf(pos));
                        } else {
                          _editStation(pos, stationName, locationName);
                        }
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
                        if (_editConnectionsMode) {
                          _setEndIndexForConnection(index);
                        } else {
                          _editStation(pos, stationNameController.text, locationNameController.text);
                        }
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

      // Si ya existe un id para el punto, lo conservamos, sino generamos uno nuevo
      final existingPunto = widget.linea.puntoarea.firstWhere((p) => p.latitud == pos.latitude && p.longitud == pos.longitude, orElse: () => PuntoArea(id: Uuid().v4(), longitud: pos.longitude, latitud: pos.latitude, orden: index));

      return PuntoArea(
        id: existingPunto.id, // Preservar el id existente o generar uno nuevo
        longitud: pos.longitude,
        latitud: pos.latitude,
        orden: index,
      );
    }).toList();

    // Crear la nueva área de cultivo con los puntos actualizados
    final linea = AreaCultivo(
      id: widget.linea.id,
      nombre: _lineNameController.text,
      color: '#${_selectedColor.value.toRadixString(16).substring(2)}',
      puntoarea: puntosarea,
    );

    // Actualizar la línea en la base de datos
    await _firebaseController.updateLineaTeleferico(linea.id, linea);

    setState(() {
      _newMarkers.clear();
      _newPolylines.clear();
      _stations.clear();
      _stationNames.clear();
      _locationNames.clear();
      _lineNameController.clear();
      _colorSelected = false;
      _editConnectionsMode = false; // Desactivar el modo de edición de conexiones al guardar
    });

    Navigator.of(context).pop();
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
                    decoration: InputDecoration(labelText: 'Nombre del Area'),
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

  void _setStartIndexForConnection(int index) {
    setState(() {
      _startIndex = index;
    });
  }

  void _setEndIndexForConnection(int endIndex) {
    if (_startIndex != -1 && endIndex != _startIndex) {
      setState(() {
        final startStation = _stations[_startIndex];
        final endStation = _stations[endIndex];

        _newPolylines.add(Polyline(
          polylineId: PolylineId('custom_polyline_${_startIndex}_$endIndex'),
          color: _selectedColor,
          width: 5,
          points: [startStation, endStation],
        ));
        _startIndex = -1; // Reset start index after setting the connection
      });
    }
  }

  void _toggleEditConnectionsMode() {
    setState(() {
      _editConnectionsMode = !_editConnectionsMode;
      _startIndex = -1; // Reset start index if mode is toggled
    });
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
          IconButton(
            icon: Icon(_editConnectionsMode ? Icons.close : Icons.link),
            onPressed: _toggleEditConnectionsMode,
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
          polylines: Set.from(_newPolylines),
          onTap: _addStation,
        ),
        if (_editConnectionsMode)
          Positioned(
            bottom: 20,
            left: 20,
            child: ElevatedButton(
              onPressed: _toggleEditConnectionsMode,
              child: Text('Salir del Modo de Edición de Area'),
            ),
          ),
      ],
    );
  }
}
