import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../components/navigation_bar.dart';
import 'price_suggestion.dart';
import 'profile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late GoogleMapController mapController;

  int _navIndex = 1;
  final List<int> _navHistory = [1];

  static const CameraPosition _kMannheim = CameraPosition(
    target: LatLng(49.4875, 8.4660), // Mannheim, Deutschland
    zoom: 13.0,  // Der Startzoom-Level
  );

  void _setTab(int index) {
    if (index == _navIndex) return;
    setState(() {
      _navIndex = index;
      if (_navHistory.isEmpty || _navHistory.last != index) {
        _navHistory.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _navHistory.length <= 1,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_navHistory.length <= 1) return;

        setState(() {
          _navHistory.removeLast();
          _navIndex = _navHistory.last;
        });
      },
      child: Scaffold(
        bottomNavigationBar: AppNavigationBar(
          currentIndex: _navIndex,
          onTap: _setTab,
        ),
        body: IndexedStack(
          index: _navIndex,
          children: [
            const PriceSuggestionPage(),
            _MapTab(
              cameraPosition: _kMannheim,
              onMapCreated: (controller) => mapController = controller,
            ),
            const ProfilePage(),
          ],
        ),
      ),
    );
  }
}

class _MapTab extends StatelessWidget {
  const _MapTab({
    required this.cameraPosition,
    required this.onMapCreated,
  });

  final CameraPosition cameraPosition;
  final ValueChanged<GoogleMapController> onMapCreated;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: cameraPosition,
          onMapCreated: onMapCreated,
          myLocationEnabled: true,
          zoomControlsEnabled: false,
        ),
        Positioned(
          top: 40,
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
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Suche...',
                        border: InputBorder.none,
                        suffixIcon: GestureDetector(
                          onTap: () {
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
      ],
    );
  }
}
