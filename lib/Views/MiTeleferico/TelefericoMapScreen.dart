import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_gmaps/Controllers/MiTeleferico/LineasTelefericoController.dart';
import 'package:flutter_gmaps/models/MiTeleferico/AreaCultivo.dart';

class TelefericosHandler {
  static final LineaTelefericoController _firebaseController = LineaTelefericoController();

  // Método para cargar las líneas y generar markers y polylines
  static Future<void> loadLineasTeleferico({
    required Function(List<Marker>) onMarkersLoaded,
    required Function(List<Polyline>) onPolylinesLoaded,
  }) async {
    _firebaseController.getLineasTelefericos().listen((lineas) async {
      List<Marker> markers = [];
      List<Polyline> polylines = [];

      for (var linea in lineas) {
        // Crear el markerIcon para toda la línea solo una vez
        final markerIcon = await _createCustomMarkerBitmap(Color(int.parse('0xff${linea.color.substring(1)}')));

        // Crear markers para cada punto de área
        for (var puntoArea in linea.puntoarea) {
          final marker = Marker(
            markerId: MarkerId('${puntoArea.latitud}_${puntoArea.longitud}'), // Usar latitud y longitud como ID único
            position: LatLng(puntoArea.latitud, puntoArea.longitud),
            icon: markerIcon,
          );
          markers.add(marker);
        }

        // Crear polylines entre los puntos de área
        if (linea.puntoarea.length > 1) {
          for (int i = 0; i < linea.puntoarea.length - 1; i++) {
            final color = Color(int.parse('0xff${linea.color.substring(1)}'));

            // Polyline para el borde
            polylines.add(Polyline(
              polylineId: PolylineId('border_polyline_${linea.nombre}_$i'),
              color: Colors.black,
              width: 9,
              points: [
                LatLng(linea.puntoarea[i].latitud, linea.puntoarea[i].longitud),
                LatLng(linea.puntoarea[i + 1].latitud, linea.puntoarea[i + 1].longitud),
              ],
            ));

            // Polyline para el color de la línea
            polylines.add(Polyline(
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

      // Pasar markers y polylines de vuelta a los callbacks
      onMarkersLoaded(markers);
      onPolylinesLoaded(polylines);
    });
  }

  // Método para crear el icono del marker a partir de un SVG y color
  static Future<BitmapDescriptor> _createCustomMarkerBitmap(Color color) async {
    // Cargar el SVG de los assets
    final svgString = await rootBundle.loadString('assets/svgs/TelefericoIcon.svg');
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
