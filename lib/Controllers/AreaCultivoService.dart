import 'package:flutter/material.dart';
import 'package:flutter_gmaps/Controllers/MiTeleferico/AreaCultivoController.dart';
import 'package:flutter_gmaps/models/AreaCultivo/AreaCultivo.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AreaCultivoService {
  final AreaCultivoController _firebaseController = AreaCultivoController();
  List<Marker> _newMarkers = [];
  List<Polygon> _newPolygons = [];

  // Mapa de colores predefinidos que coinciden con los nombres registrados
  final Map<String, Color> colorMap = {
    'Rojo': Colors.red,
    'Verde': Colors.green,
    'Azul': Colors.blue,
    'Amarillo': Colors.yellow,
    'Morado': Colors.purple,
    'Naranja': Colors.orange,
    'Rosa': Colors.pink,
  };

  // Función para cargar las áreas de cultivo desde Firebase
  Stream<List<AreaCultivo>> getAreasCultivo() {
    return _firebaseController.getLineasTelefericos();
  }

  // Función para cargar los markers y polígonos
  Future<void> loadMarkersAndPolygons(
    List<AreaCultivo> areasCultivo,
    Function(List<Marker>, List<Polygon>) updateMapMarkersAndPolygons,
  ) async {
    _newMarkers.clear();
    _newPolygons.clear();

    for (var area in areasCultivo) {
      // Obtener el color desde el nombre registrado en el área de cultivo
      Color color = colorMap[area.color] ?? Colors.black; // Color por defecto: negro

      // Crear los markers
      for (var puntoarea in area.puntoarea) {
        final marker = Marker(
          markerId: MarkerId('${puntoarea.latitud},${puntoarea.longitud}'),
          position: LatLng(puntoarea.latitud, puntoarea.longitud),
          icon: BitmapDescriptor.defaultMarker, // Personalizar icono si es necesario
        );
        _newMarkers.add(marker);
      }

      // Crear el polígono
      final polygon = Polygon(
        polygonId: PolygonId('polygon_${area.nombre}'),
        points: area.puntoarea.map((punto) => LatLng(punto.latitud, punto.longitud)).toList(),
        strokeColor: color,
        strokeWidth: 3,
        fillColor: color.withOpacity(0.3),
      );
      _newPolygons.add(polygon);
    }

    // Actualizar los markers y polígonos en el mapa
    updateMapMarkersAndPolygons(_newMarkers, _newPolygons);
  }
}
