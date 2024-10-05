import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_gmaps/Controllers/MiTeleferico/AreaCultivoController.dart';
import 'package:flutter_gmaps/models/AreaCultivo/AreaCultivo.dart';

class AreasHandler {
  static final AreaCultivoController _firebaseController = AreaCultivoController();

  // Método para cargar las líneas y generar markers y polylines
  static Future<void> loadLineasTeleferico({
  required Function(List<Marker>) onMarkersLoaded,
  required Function(List<Polygon>) onPolygonsLoaded,  // Cambié de polylines a polygons
}) async {
  _firebaseController.getLineasTelefericos().listen((lineas) async {
    List<Marker> markers = [];
    List<Polygon> polygons = [];  // Ahora generamos polígonos

    for (var linea in lineas) {
      // Crear el markerIcon para toda la línea solo una vez
      final markerIcon = await _createCustomMarkerBitmap(Color(int.parse('0xff${linea.color.substring(1)}')));

      List<LatLng> puntos = [];  // Lista para almacenar los puntos del área

      // Crear markers para cada punto de área y agregarlos a la lista de puntos
      for (var puntoArea in linea.puntoarea) {
        final marker = Marker(
          markerId: MarkerId('${puntoArea.latitud}_${puntoArea.longitud}'),
          position: LatLng(puntoArea.latitud, puntoArea.longitud),
          icon: markerIcon,
        );
        markers.add(marker);

        // Añadir el punto a la lista de puntos del polígono
        puntos.add(LatLng(puntoArea.latitud, puntoArea.longitud));
      }

      // Crear un polígono si hay más de 2 puntos (mínimo 3 para formar un polígono)
      if (puntos.length >= 3) {
        polygons.add(Polygon(
          polygonId: PolygonId('polygon_${linea.nombre}'),
          points: puntos,
          strokeWidth: 3,
          strokeColor: Colors.black,  // Borde del polígono
          fillColor: Color(int.parse('0x88${linea.color.substring(1)}')),  // Color de relleno semitransparente
        ));
      }
    }

    // Pasar markers y polígonos de vuelta a los callbacks
    onMarkersLoaded(markers);
    onPolygonsLoaded(polygons);  // Devuelvo los polígonos generados
  });
}

  // Método para crear el icono del marker a partir de un SVG y color
  static Future<BitmapDescriptor> _createCustomMarkerBitmap(Color color) async {
    // Cargar el SVG de los assets
    final svgString = await rootBundle.loadString('assets/svgs/areaicon.svg');
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 130.0;

    // Dibujar el círculo del marcador
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final Paint borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, borderPaint);

    // Dibujar el contenido SVG sobre el marcador
    final DrawableRoot svgDrawableRoot = await svg.fromSvgString(svgString, svgString);
    svgDrawableRoot.scaleCanvasToViewBox(canvas, Size(size, size));
    svgDrawableRoot.clipCanvasToViewBox(canvas);
    svgDrawableRoot.draw(canvas, Rect.fromLTWH(0, 0, size, size));

    // Convertir el dibujo a un bitmap
    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image img = await picture.toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }
}
