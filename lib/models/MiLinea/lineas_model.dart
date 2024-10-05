import 'package:cloud_firestore/cloud_firestore.dart';

class Zona {
  final String nombreZona;
  final double longitud;
  final double latitud;
  final int order;

  Zona({
    required this.nombreZona,
    required this.longitud,
    required this.latitud,
    required this.order,
  });

  factory Zona.fromMap(Map<String, dynamic> map) {
    return Zona(
      nombreZona: map['nombreZona'] as String? ?? '',
      longitud: (map['longitud'] ?? 0).toDouble(),
      latitud: (map['latitud'] ?? 0).toDouble(),
      order: map['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombreZona': nombreZona,
      'longitud': longitud,
      'latitud': latitud,
      'order': order,
    };
  }
}

