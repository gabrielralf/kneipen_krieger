import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late GoogleMapController mapController;
  static const CameraPosition _kMannheim = CameraPosition(
    target: LatLng(49.4875, 8.4660), // Mannheim, Deutschland
    zoom: 13.0,  // Der Startzoom-Level
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Maps Karte
          GoogleMap(
            initialCameraPosition: _kMannheim,
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
            myLocationEnabled: true,
            zoomControlsEnabled: false,  // Deaktiviert die Zoom-Steuerung
          ),

          // Die Suchleiste oben
          Positioned(
            top: 40, // Abstand von der oberen Kante
            left: 20,
            right: 20,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade400,
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: Offset(0, 2), // Schatten nach unten
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Die Suchleiste
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Suche...',
                          border: InputBorder.none,
                          suffixIcon: GestureDetector(
                            onTap: () {
                              // Hier wird der Filter Button später die Funktion ausführen
                              debugPrint('Filter Button gedrückt');
                            },
                            child: SvgPicture.asset(
                              'assets/filter_icon.svg',
                              width: 24,
                              height: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Die untere Leiste
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 60,
              color: Colors.grey[300], // Du kannst später die Buttons einfügen
            ),
          ),
        ],
      ),
    );
  }
}
