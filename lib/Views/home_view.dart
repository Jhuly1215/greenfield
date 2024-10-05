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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      child: BottomNavigationBar(
                        items: const <BottomNavigationBarItem>[
                          BottomNavigationBarItem(
                            icon: Icon(Icons.directions_bus),
                            label: 'Tierras',
                          ),
                          BottomNavigationBarItem(
                            icon: Icon(Icons.directions_transit),
                            label: 'Cultivos',
                          ),
                          BottomNavigationBarItem(
                            icon: Icon(Icons.cable),
                            label: 'Informacion',
                          ),
                        ],
                        currentIndex: _selectedIndex,
                        selectedItemColor: _isDarkMode
                            ? Colors.blue
                            : Theme.of(context)
                                .bottomNavigationBarTheme
                                .selectedItemColor,
                        unselectedItemColor: _isDarkMode
                            ? Colors.black
                            : Theme.of(context)
                                .bottomNavigationBarTheme
                                .unselectedItemColor,
                        onTap: (index) {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    TextField(
                             
                                      decoration: InputDecoration(
                                        labelText: 'Cultivos',
                            
                                        prefixIcon: Icon(Icons.location_on),
                                      ),
                                      onChanged: (value) async {
                                        if (value.isNotEmpty) {
                                          var result = await googlePlace
                                              .autocomplete
                                              .get(value);
                                          if (result != null &&
                                              result.predictions != null) {
                                            setState(() {
                                              _originPredictions =
                                                  result.predictions!;
                                            });
                                          }
                                        } else {
                                          setState(() {
                                            _originPredictions = [];
                                          });
                                        }
                                      },
                                    ),
                                    _originPredictions.isNotEmpty
                                        ? Container(
                                            height: 100,
                                            child: ListView.builder(
                                              itemCount:
                                                  _originPredictions.length,
                                              itemBuilder: (context, index) {
                                                return ListTile(
                                                  title: Text(
                                                      _originPredictions[index]
                                                              .description ??
                                                          ''),
                                                  onTap: () async {
                                                    final placeId =
                                                        _originPredictions[
                                                                index]
                                                            .placeId!;
                                                    final details =
                                                        await googlePlace
                                                            .details
                                                            .get(placeId);
                                                    if (details != null &&
                                                        details.result !=
                                                            null) {
                                                      final location = details
                                                          .result!
                                                          .geometry!
                                                          .location!;
                                                      setState(() {
                                                        _originPosition =
                                                            LatLng(
                                                                location.lat!,
                                                                location.lng!);
                                                        _originAddress = details
                                                            .result!
                                                            .formattedAddress!;
                                                  
                                                        _originPredictions = [];
                                                      });
                                                    }
                                                  },
                                                );
                                              },
                                            ),
                                          )
                                        : Container(),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit_location),
                                onPressed: () async {
                                  LatLng? result = await _selectLocationOnMap();
                                  if (result != null) {
                                    final address =
                                        await _getAddressFromLatLng(result);
                                    setState(() {
                                      _originPosition = result;
                                      _originAddress = address;
          
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    TextField(
                                     
                                      decoration: InputDecoration(
                                        labelText: 'Destino',
                                        hintText: 'Selecciona el destino',
                                        prefixIcon: Icon(Icons.flag),
                                      ),
                                      onChanged: (value) async {
                                        if (value.isNotEmpty) {
                                          var result = await googlePlace
                                              .autocomplete
                                              .get(value);
                                          if (result != null &&
                                              result.predictions != null) {
                                            setState(() {
                                              _destinationPredictions =
                                                  result.predictions!;
                                            });
                                          }
                                        } else {
                                          setState(() {
                                            _destinationPredictions = [];
                                          });
                                        }
                                      },
                                    ),
                                    _destinationPredictions.isNotEmpty
                                        ? Container(
                                            height: 100,
                                            child: ListView.builder(
                                              itemCount: _destinationPredictions
                                                  .length,
                                              itemBuilder: (context, index) {
                                                return ListTile(
                                                  title: Text(
                                                      _destinationPredictions[
                                                                  index]
                                                              .description ??
                                                          ''),
                                                  onTap: () async {
                                                    final placeId =
                                                        _destinationPredictions[
                                                                index]
                                                            .placeId!;
                                                    final details =
                                                        await googlePlace
                                                            .details
                                                            .get(placeId);
                                                    if (details != null &&
                                                        details.result !=
                                                            null) {
                                                      final location = details
                                                          .result!
                                                          .geometry!
                                                          .location!;
                                                      setState(() {
                                                        _destinationPosition =
                                                            LatLng(
                                                                location.lat!,
                                                                location.lng!);
                                                        _destinationAddress =
                                                            details.result!
                                                                .formattedAddress!;
                                                       
                                                               
                                                            _destinationAddress;
                                                        _destinationPredictions =
                                                            [];
                                                      });
                                                    }
                                                  },
                                                );
                                              },
                                            ),
                                          )
                                        : Container(),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit_location),
                                onPressed: () async {
                                  LatLng? result = await _selectLocationOnMap();
                                  if (result != null) {
                                    final address =
                                        await _getAddressFromLatLng(result);
                                    setState(() {
                                      _destinationPosition = result;
                                      _destinationAddress = address;
                                    
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _navigateToSelectedTransport();
                            },
                            child: Text('Buscar Ruta'),
                          ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('Cerrar'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    _updateMapStyle();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        title: Image.asset(
          'assets/pngs/Logo Menta_Mesa de trabajo 1.png',
          height: 70,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.account_circle,
            color: _isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () {
            // Navigate to user profile view
            Navigator.push(
              context,
              UserProfileView.route(),
            );
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
            onTap: (LatLng position) {
              _showOriginDestinationBottomSheet(position);
            },
            markers: _destinationMarker != null
                ? {
                    _destinationMarker!,
                  }
                : {},
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
                    ],
                    currentIndex: _selectedIndex,
                    selectedItemColor: _isDarkMode
                        ? Colors.blue
                        : Theme.of(context)
                            .bottomNavigationBarTheme
                            .selectedItemColor,
                    unselectedItemColor: _isDarkMode
                        ? Colors.black
                        : Theme.of(context)
                            .bottomNavigationBarTheme
                            .unselectedItemColor,
                    onTap: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                      _showOriginDestinationBottomSheet(_currentPosition);
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
