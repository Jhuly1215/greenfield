class LineaTeleferico {
  String id;
  String nombre;
  String color;
  String colorValue;
  List<Estacion> estaciones;

  LineaTeleferico({
    required this.id,
    required this.nombre,
    required this.color,
    required this.colorValue,
    required this.estaciones,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'color': color,
      'colorValue': colorValue,
      'estaciones': estaciones.map((e) => e.toMap()).toList(),
    };
  }
}

class Estacion {
  String nombreEstacion;
  String nombreUbicacion;
  String nombreUbicacionGoogle;
  double longitud;
  double latitud;
  int orden;

  Estacion({
    required this.nombreEstacion,
    required this.nombreUbicacion,
    required this.nombreUbicacionGoogle,
    required this.longitud,
    required this.latitud,
    required this.orden,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombreEstacion': nombreEstacion,
      'nombreUbicacion': nombreUbicacion,
      'nombreUbicacionGoogle': nombreUbicacionGoogle,
      'longitud': longitud,
      'latitud': latitud,
      'orden': orden,
    };
  }
}
