import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_gmaps/.env.dart';
import 'package:flutter_gmaps/Views/MiTeleferico/RouteViewAreaCultivo.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gmaps/utils/theme.dart';
import 'package:http/http.dart' as http;
import 'package:google_place/google_place.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gmaps/user_profile/view/user_profile_view.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_gmaps/Controllers/MiTeleferico/AreaCultivoController.dart';
import 'package:flutter_gmaps/models/AreaCultivo/AreaCultivo.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui' as ui;


class HomeView extends ConsumerStatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  HomeView({required this.toggleTheme, required this.isDarkMode});

  static Route route(
      {required VoidCallback toggleTheme, required bool isDarkMode}) {
    return MaterialPageRoute<void>(
        builder: (_) =>
            HomeView(toggleTheme: toggleTheme, isDarkMode: isDarkMode));
  }

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(-16.4897, -68.1193),
    zoom: 14.5,
  );

  late GoogleMapController _googleMapController;
  late LatLng _currentPosition;
  LatLng? _originPosition;
  LatLng? _destinationPosition;
  String _originAddress = '';
  String _destinationAddress = '';
  StreamSubscription<Position>? _positionStream;
  bool _isDarkMode = false;
  int _selectedIndex = 0;
  List<AutocompletePrediction> _originPredictions = [];
  List<AutocompletePrediction> _destinationPredictions = [];
  final GooglePlace googlePlace = GooglePlace(googleAPIKey);
  bool _isLoading = false; // Variable para el loader
  Marker? _destinationMarker; // Variable para el marcador

  List<Marker> _areaMarkers = [];
  List<Polygon> _areaPolygons = [];
  final AreaCultivoController _firebaseController = AreaCultivoController();
  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _loadThemePreference();
    _requestLocationPermission();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _googleMapController.dispose();
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? widget.isDarkMode;
      _updateMapStyle();
    });
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
  }

  Future<void> _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition();
    _currentPosition = LatLng(position.latitude, position.longitude);
    _originPosition = _currentPosition;
    final address = await _getAddressFromLatLng(_currentPosition);
    setState(() {
      _originAddress = address;
    });

    _googleMapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentPosition,
          zoom: 14.5,
        ),
      ),
    );
  }

  Future<String> _getAddressFromLatLng(LatLng position) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$googleAPIKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['results'] != null &&
          jsonResponse['results'].length > 0) {
        return jsonResponse['results'][0]['formatted_address'];
      }
    }
    return '';
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _updateMapStyle() async {
    if (_isDarkMode) {
      _googleMapController.setMapStyle(darkMapStyle);
    } else {
      _googleMapController.setMapStyle(null); // Default style
    }
  }

  void _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = !_isDarkMode;
    await prefs.setBool('isDarkMode', isDarkMode);
    setState(() {
      _isDarkMode = isDarkMode;
      widget.toggleTheme();
      _updateMapStyle();
    });
  }

  void _showOriginDestinationBottomSheet(LatLng destinationPosition) async {
    setState(() {
      _isLoading = true; // Mostrar loader
      _destinationMarker = Marker(
        markerId: MarkerId('destination'),
        position: destinationPosition,
      ); // Agregar marcador
    });

    final address = await _getAddressFromLatLng(destinationPosition);

    setState(() {
      _isLoading = false; // Ocultar loader
      _destinationPosition = destinationPosition;
      _destinationAddress = address;
    });

  }

  Future<LatLng?> _selectLocationOnMap() async {
    LatLng? selectedLocation;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Scaffold(
              appBar: AppBar(
                title: Text('Selecciona la ubicación'),
                actions: [
                  IconButton(
                    icon: Icon(Icons.check),
                    onPressed: () {
                      Navigator.of(context).pop(selectedLocation);
                    },
                  ),
                ],
              ),
              body: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentPosition,
                  zoom: 14.5,
                ),
                onTap: (LatLng position) {
                  setState(() {
                    selectedLocation = position;
                  });
                },
                markers: selectedLocation != null
                    ? {
                        Marker(
                          markerId: MarkerId('selected_location'),
                          position: selectedLocation!,
                        ),
                      }
                    : {},
              ),
            );
          },
        );
      },
    );
    return selectedLocation;
  }

  void _navigateToSelectedTransport() {
    if (_originPosition != null && _destinationPosition != null) {   
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => RouteViewTeleferico(
          originPosition: _originPosition!,
          destinationPosition: _destinationPosition!,
        ),
        ));
      }
  }
  void _focusOnArea(AreaCultivo area) {
    if (_googleMapController == null || area.puntoarea.isEmpty) return;

    // Obtener los límites del área seleccionada
    LatLngBounds bounds = _getBoundsForArea(area.puntoarea);

    // Mover la cámara a la posición del área seleccionada
    _googleMapController.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),  // Ajustar el mapa a los límites del área
    );
  }

  LatLngBounds _getBoundsForArea(List<PuntoArea> puntos) {
    double southWestLat = puntos.first.latitud;
    double southWestLng = puntos.first.longitud;
    double northEastLat = puntos.first.latitud;
    double northEastLng = puntos.first.longitud;

    for (var punto in puntos) {
      if (punto.latitud < southWestLat) southWestLat = punto.latitud;
      if (punto.longitud < southWestLng) southWestLng = punto.longitud;
      if (punto.latitud > northEastLat) northEastLat = punto.latitud;
      if (punto.longitud > northEastLng) northEastLng = punto.longitud;
    }

    return LatLngBounds(
      southwest: LatLng(southWestLat, southWestLng),
      northeast: LatLng(northEastLat, northEastLng),
    );
  }

  //para mostrar las areas de cultivo
  void _showRegisteredAreasModal(BuildContext context, List<AreaCultivo> areas) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Añadir el BottomNavigationBar en la parte superior del modal
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                child: BottomNavigationBar(
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      icon: Icon(Icons.cable),
                      label: 'Tierras',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.local_taxi),
                      label: 'Cultivos',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.local_taxi),
                      label: 'Informacion',
                    ),
                  ],
                  currentIndex: _selectedIndex,
                  selectedItemColor: const Color(0xFF025940),
                  unselectedItemColor: Colors.white,
                  onTap: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                    Navigator.pop(context);  // Cerrar el modal para abrir la nueva vista según la selección
                    if (index == 0) {
                      _loadLineasTeleferico();  // Volver a mostrar tierras registradas
                    } else if (index == 1) {
                      // Aquí puedes implementar la acción para "Cultivos"
                    } else if (index == 2) {
                      // Aquí puedes implementar la acción para "Información"
                    }
                  },
                  backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
                  elevation: 0,
                ),
              ),
              
              // Título del modal
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Tierras Registradas',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              
              // ListView de áreas registradas
              ListView.builder(
                shrinkWrap: true,
                itemCount: areas.length,
                itemBuilder: (context, index) {
                  final area = areas[index];
                  return ListTile(
                    title: Text(area.nombre),  // Nombre de la tierra
                    subtitle: Row(
                      children: [
                        // Mostrar un contenedor con el color
                        Container(
                          width: 20,   // Ancho del círculo de color
                          height: 20,  // Alto del círculo de color
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,  // Hacerlo circular
                            color: Color(int.parse('0xff${area.color.substring(1)}')),  // Convertir el código de color
                          ),
                        ),
                        SizedBox(width: 8),  // Espacio entre el color y el texto
                        Text('Color: ${area.color}'),  // Mostrar el valor del color como texto
                      ],
                    ),
                    trailing: Icon(Icons.arrow_forward),
                    onTap: () {
                      _focusOnArea(area);  // Llamar a la función para enfocar la cámara en el área seleccionada
                      Navigator.pop(context);
                    },
                  );
                },
              ),
              
              SizedBox(height: 20),
              
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);  // Cerrar el modal
                },
                child: Text('Cerrar'),
              ),
            ],
          ),
        ),
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
      ..color = const ui.Color.fromARGB(255, 97, 97, 97)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    // Dibujar el círculo de color personalizado
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, borderPaint);

    // Dibujar el ícono SVG dentro del círculo
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

  Future<void> _loadMarkersAndPolygons(List<AreaCultivo> areas) async {
  for (var area in areas) {
    // Añadir marcadores para cada punto en el área
    for (var point in area.puntoarea) {
      final markerIcon = await _createCustomMarkerBitmap(
        Color(int.parse('0xff${area.color.substring(1)}')),  // Usar el color de cada área
      );
      final marker = Marker(
        markerId: MarkerId('${point.latitud},${point.longitud}'),
        position: LatLng(point.latitud, point.longitud),
        icon: markerIcon,  // Usar el icono personalizado
      );
      _areaMarkers.add(marker);
    }

    // Crear un polígono para representar el área
    final polygon = Polygon(
      polygonId: PolygonId('polygon_${area.nombre}'),
      points: area.puntoarea.map((p) => LatLng(p.latitud, p.longitud)).toList(),
      strokeColor: Colors.black,
      strokeWidth: 3,
      fillColor: Color(int.parse('0xff${area.color.substring(1)}')).withOpacity(0.3),
    );
    _areaPolygons.add(polygon);
  }
  setState(() {});  // Actualizar el mapa con los nuevos marcadores y polígonos
}

  Future<void> _loadLineasTeleferico() async {
    _firebaseController.getLineasTelefericos().listen((lineas) {
      print("Áreas de cultivo obtenidas: ${lineas.length}");
      setState(() {
        _areaMarkers.clear();
        _areaPolygons.clear();
        _loadMarkersAndPolygons(lineas);  // Cargar marcadores y polígonos
      });
      _showRegisteredAreasModal(context, lineas);
  });

}

  @override
  Widget build(BuildContext context) {
    _updateMapStyle();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        title: Image.asset('assets/pngs/LOGO_COMPLETO_BLANCO-01.png',
          height: 140,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.account_circle,
            color: _isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () {
            // Navigate to user profile view
            Navigator.push(context,UserProfileView.route(),);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.brightness_6,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: _toggleTheme,
          ),
          IconButton(
            icon: Icon(
              Icons.notifications,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: () {},
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
        backgroundColor: _isDarkMode
            ? Colors.black
            : Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: _isDarkMode
            ? Colors.white
            : Theme.of(context).appBarTheme.iconTheme?.color,
      ),
      body: Stack(
        children: [
          GoogleMap(
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: (controller) {
              _googleMapController = controller;
              _updateMapStyle();
            },
            markers: Set<Marker>.from(_areaMarkers),  // Muestra todos los marcadores de áreas de cultivo
            polygons: Set<Polygon>.from(_areaPolygons),
            onTap: (LatLng position) {
              _showOriginDestinationBottomSheet(position);
            },
            
          ),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _showOriginDestinationBottomSheet(_currentPosition),
              child: Container(
                decoration: BoxDecoration(
                  color: _isDarkMode
                      ? Colors.black
                      : Theme.of(context)
                          .bottomNavigationBarTheme
                          .backgroundColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 10,
                      offset: Offset(0, -1),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  child: BottomNavigationBar(
                    items: const <BottomNavigationBarItem>[
                      BottomNavigationBarItem(
                        icon: Icon(Icons.cable),
                        label: 'Tierras',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.local_taxi),
                        label: 'Cultivos',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.local_taxi),
                        label: 'Informacion',
                      ),
                    ],
                    currentIndex: _selectedIndex,
                  
                    selectedItemColor: const Color(0xFF025940),
                    // Asigna el color 071D26 a los ítems no seleccionados
                    unselectedItemColor: Colors.white,
                    onTap: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                     if (index == 0) {
                        _loadLineasTeleferico();  // Show areas when "Tierras" is tapped
                      }
                      
                    },
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
