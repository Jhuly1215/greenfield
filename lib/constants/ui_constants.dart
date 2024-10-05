import 'package:flutter/material.dart';
import 'package:flutter_gmaps/constants/assets_constants.dart';

class UIConstants {
  static AppBar appBar() {
    return AppBar(
      title: Image.asset(
        AssetsConstants.alertoLogoPng,
        height: 70,
      ),
      centerTitle: true,
    );
  }
}
