import 'package:flutter/material.dart';
import 'package:flutter_gmaps/Controllers/MiTeleferico/AreaCultivoController.dart';
import 'package:flutter_gmaps/Views/MiTeleferico/Registro/EditAreaCultivo.dart';
import 'package:flutter_gmaps/Views/MiTeleferico/Registro/RegistroAreaCultivo.dart';
import 'package:flutter_gmaps/models/MiTeleferico/AreaCultivo.dart';

class ListLineasTelefericoScreen extends StatefulWidget {
  @override
  _ListLineasTelefericoScreenState createState() => _ListLineasTelefericoScreenState();
}

class _ListLineasTelefericoScreenState extends State<ListLineasTelefericoScreen> {
  final AreaCultivoController _firebaseController = AreaCultivoController();
  List<AreaCultivo> _areasCultivo = [];

  @override
  void initState() {
    super.initState();
    _loadLineasTeleferico();
  }

  Future<void> _loadLineasTeleferico() async {
    _firebaseController.getLineasTelefericos().listen((lineas) {
      setState(() {
        _areasCultivo = lineas;
      });
    });
  }

  void _editLinea(AreaCultivo linea) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditarLineaScreen(linea: linea)),
    );
  }

  void _deleteLinea(String id) async {
    await _firebaseController.deleteLineaTeleferico(id);
    _loadLineasTeleferico();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Líneas de Teleférico'),
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
      body: ListView.builder(
        itemCount: _areasCultivo.length,
        itemBuilder: (context, index) {
          final linea = _areasCultivo[index];
          return ListTile(
            title: Text(linea.nombre),
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
      ),
    );
  }
}
