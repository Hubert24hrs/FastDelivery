import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapView extends StatelessWidget {
  final Function(dynamic)? onMapCreated;

  const MapView({super.key, this.onMapCreated});

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      key: const ValueKey("mapWidget"),
      onMapCreated: (map) => onMapCreated?.call(map),
      styleUri: MapboxStyles.DARK,
      cameraOptions: CameraOptions(
        center: Point(coordinates: Position(3.3792, 6.5244)),
        zoom: 12.0,
        pitch: 45.0,
      ),
    );
  }
}
