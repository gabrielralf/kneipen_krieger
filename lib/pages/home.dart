import 'package:flutter/material.dart';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

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
  int _suggestionsRefreshSignal = 0;

  // Later you can set this from a filter UI.
  String? _drinkTypeFilter;

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
            PriceSuggestionPage(
              onPosted: () => setState(() => _suggestionsRefreshSignal++),
            ),
            _MapTab(
              cameraPosition: _kMannheim,
              onMapCreated: (controller) => mapController = controller,
              refreshSignal: _suggestionsRefreshSignal,
              drinkTypeFilter: _drinkTypeFilter,
            ),
            ProfilePage(refreshSignal: _suggestionsRefreshSignal),
          ],
        ),
      ),
    );
  }
}

class _MapTab extends StatefulWidget {
  const _MapTab({
    required this.cameraPosition,
    required this.onMapCreated,
    required this.refreshSignal,
    required this.drinkTypeFilter,
  });

  final CameraPosition cameraPosition;
  final ValueChanged<GoogleMapController> onMapCreated;
  final int refreshSignal;
  final String? drinkTypeFilter;

  @override
  State<_MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<_MapTab> {
  Set<Marker> _markers = const {};
  static const double _radiusKm = 5.0;

  GoogleMapController? _controller;
  LatLng _cameraCenter = const LatLng(49.4875, 8.4660);
  bool _locationAllowed = false;

  @override
  void initState() {
    super.initState();
    _cameraCenter = widget.cameraPosition.target;
    _initLocationAndCenter();
    _loadMarkers(center: _cameraCenter);
  }

  @override
  void didUpdateWidget(covariant _MapTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal ||
        oldWidget.drinkTypeFilter != widget.drinkTypeFilter) {
      _loadMarkers(center: _cameraCenter);
    }
  }

  double _toRad(double degrees) => degrees * (pi / 180.0);

  double _distanceKm(LatLng a, LatLng b) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRad(b.latitude - a.latitude);
    final dLon = _toRad(b.longitude - a.longitude);
    final lat1 = _toRad(a.latitude);
    final lat2 = _toRad(b.latitude);

    final h = pow(sin(dLat / 2), 2) +
        cos(lat1) * cos(lat2) * pow(sin(dLon / 2), 2);
    final c = 2 * asin(min(1.0, sqrt(h.toDouble())));
    return earthRadiusKm * c;
  }

  Future<void> _initLocationAndCenter() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final userCenter = LatLng(position.latitude, position.longitude);
      if (!mounted) return;

      setState(() {
        _locationAllowed = true;
        _cameraCenter = userCenter;
      });

      await _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(userCenter, widget.cameraPosition.zoom),
      );

      await _loadMarkers(center: userCenter);
    } catch (_) {
      // If location fails, keep default camera/markers.
    }
  }

  double _markerHueForDrink(String? drinkType) {
    switch (drinkType) {
      case 'beer':
        return BitmapDescriptor.hueYellow;
      case 'whine':
        return BitmapDescriptor.hueMagenta;
      case 'cocktail':
        return BitmapDescriptor.hueAzure;
      case 'whiskey':
        return BitmapDescriptor.hueOrange;
      case 'other':
        return BitmapDescriptor.hueViolet;
      default:
        return BitmapDescriptor.hueRed;
    }
  }

  Future<void> _loadMarkers({required LatLng center}) async {
    try {
      final client = Supabase.instance.client;
      final drinkFilter = widget.drinkTypeFilter;

      // Bounding box first (cheap server-side filter), then exact haversine.
      final latDelta = _radiusKm / 111.0;
      final lngDelta = _radiusKm / (111.0 * cos(_toRad(center.latitude)).abs().clamp(0.01, 1.0));
      final minLat = center.latitude - latDelta;
      final maxLat = center.latitude + latDelta;
      final minLng = center.longitude - lngDelta;
      final maxLng = center.longitude + lngDelta;

      final rows = await client
          .from('price_suggestions')
          .select('bar_name, street_name, street_number, lat, lng, drink_type')
          .gte('lat', minLat)
          .lte('lat', maxLat)
          .gte('lng', minLng)
          .lte('lng', maxLng);

      final list = (rows as List).cast<Map<String, dynamic>>();

      // Group rows into one marker per bar.
      final byBar = <String, List<Map<String, dynamic>>>{};
      for (final row in list) {
        final barName = (row['bar_name'] as String?)?.trim() ?? '';
        final streetName = (row['street_name'] as String?)?.trim() ?? '';
        final streetNumber = (row['street_number'] as String?)?.trim() ?? '';
        if (barName.isEmpty || streetName.isEmpty || streetNumber.isEmpty) {
          continue;
        }
        final key = '${barName.toLowerCase()}|${streetName.toLowerCase()}|$streetNumber';
        (byBar[key] ??= []).add(row);
      }

      final markers = <Marker>{};
      for (final entry in byBar.entries) {
        final rowsForBar = entry.value;

        if (drinkFilter != null) {
          final hasType = rowsForBar.any((r) => r['drink_type'] == drinkFilter);
          if (!hasType) continue;
        }

        // Pick the first row that has coordinates.
        final withCoords = rowsForBar.firstWhere(
          (r) => r['lat'] != null && r['lng'] != null,
          orElse: () => const {},
        );
        if (withCoords.isEmpty) continue;

        final lat = (withCoords['lat'] as num).toDouble();
        final lng = (withCoords['lng'] as num).toDouble();

        final barPos = LatLng(lat, lng);
        if (_distanceKm(center, barPos) > _radiusKm) continue;

        final barName = (rowsForBar.first['bar_name'] as String).trim();
        final streetName = (rowsForBar.first['street_name'] as String).trim();
        final streetNumber = (rowsForBar.first['street_number'] as String).trim();

        markers.add(
          Marker(
            markerId: MarkerId(entry.key),
            position: barPos,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _markerHueForDrink(drinkFilter),
            ),
            infoWindow: InfoWindow(
              title: barName,
              snippet: '$streetName $streetNumber',
            ),
          ),
        );
      }

      if (!mounted) return;
      setState(() => _markers = markers);
    } catch (_) {
      if (!mounted) return;
      setState(() => _markers = const {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: widget.cameraPosition,
          onMapCreated: (controller) {
            _controller = controller;
            widget.onMapCreated(controller);
          },
          myLocationEnabled: _locationAllowed,
          zoomControlsEnabled: false,
          markers: _markers,
          onCameraMove: (pos) {
            _cameraCenter = pos.target;
          },
          onCameraIdle: () {
            _loadMarkers(center: _cameraCenter);
          },
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
