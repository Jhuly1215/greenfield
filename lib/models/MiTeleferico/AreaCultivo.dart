class AreaCultivo {
  String id;
  String nombre;
  String color;

  List<PuntoArea> puntoarea;

  AreaCultivo({
    required this.id,
    required this.nombre,
    required this.color,
    required this.puntoarea,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'color': color,
    
      'puntoarea': puntoarea.map((e) => e.toMap()).toList(),
    };
  }
}

class PuntoArea {
  String id;
  double longitud;
  double latitud;
  int orden;
  PuntoArea({
    required this.id,
    required this.longitud,
    required this.latitud,
    required this.orden,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'longitud': longitud,
      'latitud': latitud,
      'orden': orden,
    };
  }
}
