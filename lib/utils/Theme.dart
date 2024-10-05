import 'package:flutter/material.dart';


class Pallete {
  static const Color principal = Color(0xFF038C3E);
  static const Color secundario = Color(0xFFBDBDBD);
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color backgroundColor = Color(0xFF025940);

  static const Color darkGreenColor = Color(0xFF014034);
  static const Color darkGreen2Color = Color(0xFF071D26);
}

final lightTheme = ThemeData(
  primarySwatch: Colors.blue,
  primaryColor: Pallete.principal,
  brightness: Brightness.light,
  
  // AppBar Theme
  appBarTheme: AppBarTheme(
    color: Pallete.principal, // Color de fondo 038C3E
    iconTheme: IconThemeData(color: Pallete.whiteColor), // Íconos en blanco
    titleTextStyle: TextStyle(
      color: Pallete.whiteColor, // Título en blanco
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  
  // BottomNavigationBar Theme
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Pallete.principal, // Color de fondo 038C3E
    selectedItemColor: Pallete.darkGreen2Color, // Color de ítem seleccionado 071D26
    unselectedItemColor: Pallete.whiteColor, // Ítems no seleccionados en blanco
  ),

  inputDecorationTheme: InputDecorationTheme(
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: BorderSide(
        color: Pallete.principal,
        width: 3,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: BorderSide(
        color: Pallete.principal,
      ),
    ),
    contentPadding: const EdgeInsets.all(22),
    hintStyle: const TextStyle(
      fontSize: 18,
    ),
  ),
);

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.blue,
  primaryColor: Colors.teal[700],

  // AppBar Theme
  appBarTheme: AppBarTheme(
    color: Pallete.principal, // Color de fondo 038C3E
    iconTheme: IconThemeData(color: Pallete.whiteColor), // Íconos en blanco
    titleTextStyle: TextStyle(
      color: Pallete.whiteColor, // Título en blanco
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  
  // BottomNavigationBar Theme
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Pallete.principal, // Color de fondo 038C3E
    selectedItemColor: Pallete.darkGreen2Color, // Color de ítem seleccionado 071D26
    unselectedItemColor: Pallete.whiteColor, // Ítems no seleccionados en blanco
  ),

  inputDecorationTheme: InputDecorationTheme(
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: BorderSide(
        color: Pallete.principal,
        width: 3,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: BorderSide(
        color: Pallete.secundario,
      ),
    ),
    contentPadding: const EdgeInsets.all(22),
    hintStyle: const TextStyle(
      fontSize: 18,
    ),
  ),
);


const darkMapStyle = '''[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#212121"
      }
    ]
  },
  {
    "elementType": "labels.icon",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#212121"
      }
    ]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "administrative.country",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#bdbdbd"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#181818"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#1b1b1b"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [
      {
        "color": "#2c2c2c"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#8a8a8a"
      }
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#373737"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#3c3c3c"
      }
    ]
  },
  {
    "featureType": "road.highway.controlled_access",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#4e4e4e"
      }
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "featureType": "transit",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#000000"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#3d3d3d"
      }
    ]
  }
]''';
