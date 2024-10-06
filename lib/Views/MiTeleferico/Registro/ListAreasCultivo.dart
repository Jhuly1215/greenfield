import 'package:flutter/material.dart';
import 'package:flutter_gmaps/Controllers/MiTeleferico/AreaCultivoController.dart';
import 'package:flutter_gmaps/Views/MiTeleferico/Registro/EditAreaCultivo.dart';
import 'package:flutter_gmaps/Views/MiTeleferico/Registro/RegistroAreaCultivo.dart';
import 'package:flutter_gmaps/models/AreaCultivo/AreaCultivo.dart';

class ListLineasTelefericoScreen extends StatefulWidget {
  @override
  _ListLineasTelefericoScreenState createState() => _ListLineasTelefericoScreenState();
}

class _ListLineasTelefericoScreenState extends State<ListLineasTelefericoScreen> {
  final AreaCultivoController _firebaseController = AreaCultivoController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Áreas de Cultivo'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RegistroLineaScreen()),
              );
            },
          ),
        ],
      ),
      // Usamos StreamBuilder para escuchar los cambios en Firestore
      body: StreamBuilder<List<AreaCultivo>>(
        stream: _firebaseController.getLineasTelefericos(),
        builder: (context, snapshot) {
          // Verifica si los datos están cargando
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Si hay un error al obtener los datos
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar las áreas de cultivo'));
          }

          // Si no hay datos
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No hay áreas de cultivo registradas.'));
          }

          // Si los datos son correctos, los mostramos
          final List<AreaCultivo> areasCultivo = snapshot.data!;

          return ListView.builder(
            itemCount: areasCultivo.length,
            itemBuilder: (context, index) {
              final linea = areasCultivo[index];
              return ListTile(
                title: Text(linea.nombre),
                subtitle: Text('Cultivo: ${linea.cultivo}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => _editLinea(linea),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _deleteLinea(linea.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _editLinea(AreaCultivo linea) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditarLineaScreen(linea: linea)),
    );
  }

  void _deleteLinea(String id) async {
    await _firebaseController.deleteLineaTeleferico(id);
  }
}
