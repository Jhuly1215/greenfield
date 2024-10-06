import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gmaps/models/AreaCultivo/AreaCultivo.dart';

class AreaCultivoController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Guardar una nueva línea en Firestore
  Future<void> saveLineaTeleferico(AreaCultivo linea) async {
    try {
      await _firestore.collection('LineasTelefericos').add(linea.toMap());
    } catch (e) {
      print(e);
    }
  }

  // Actualizar una línea existente en Firestore
  Future<void> updateLineaTeleferico(String id, AreaCultivo linea) async {
    try {
      await _firestore.collection('LineasTelefericos').doc(id).update(linea.toMap());
    } catch (e) {
      print(e);
    }
  }

  // Eliminar una línea de Firestore
  Future<void> deleteLineaTeleferico(String id) async {
    try {
      await _firestore.collection('LineasTelefericos').doc(id).delete();
    } catch (e) {
      print(e);
    }
  }

  // Recuperar las líneas (áreas de cultivo) desde Firestore
  Stream<List<AreaCultivo>> getLineasTelefericos() {
    return _firestore.collection('LineasTelefericos').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        // Mapeo de los puntos de área (PuntoArea) incluyendo el 'id'
        final puntosarea = (data['puntoarea'] as List)
            .map((e) => PuntoArea(
                  id: e['id'],
                  longitud: e['longitud'],
                  latitud: e['latitud'],
                  orden: e['orden'],
                ))
            .toList();

        // Manejo del campo cultivo en caso de que no esté presente en los datos
        return AreaCultivo(
          id: doc.id,
          nombre: data['nombre'] ?? 'Sin nombre',  // Valor por defecto
          color: data['color'] ?? 'Desconocido',  // Valor por defecto
          cultivo: data['cultivo'] ?? 'Sin cultivo',  // Si no tiene 'cultivo'
          puntoarea: puntosarea,
        );
      }).toList();
    });
  }
}
