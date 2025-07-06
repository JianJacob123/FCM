import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'dart:async';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Stack(
          children: [
            //Map Screen
            Positioned.fill(child: MapScreen()),

            // Search Field
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [SearchField(), LocationSwitch()],
              ),
            ),

            // Bottom Navigation Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: const CustomBottomBar(),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 1000,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          padding: EdgeInsets.all(2.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey,
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Where are you going to?',
              prefixIcon: Icon(Icons.search),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 17),
            ),
          ),
        ),
      ),
    );
  }
}

class LocationSwitch extends StatelessWidget {
  const LocationSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: 150, // fixed width
      decoration: BoxDecoration(
        color: const Color.fromRGBO(62, 71, 149, 1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          bottomLeft: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, -3),
          ),
        ],
      ),
      margin: EdgeInsets.symmetric(vertical: 20),
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Switch(
            value: true,
            onChanged: (value) {},
            activeColor: Colors.white,
            activeTrackColor: Color.fromRGBO(130, 135, 188, 1),
            inactiveTrackColor: Color.fromRGBO(206, 206, 214, 1),
            inactiveThumbColor: Colors.white,
          ),
          Text(
            'Location',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class CustomBottomBar extends StatelessWidget {
  const CustomBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, -3), // changes position of shadow
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Image.asset('assets/icons/notifications.png', width: 24, height: 24),
          Image.asset('assets/icons/Heart.png', width: 24, height: 24),
          Image.asset('assets/icons/location.png', width: 50, height: 50),
          Image.asset('assets/icons/Clock.png', width: 24, height: 24),
          Image.asset('assets/icons/person.png', width: 24, height: 24),
        ],
      ),
    );
  }
}

/*class MapScreen extends StatelessWidget {
  const MapScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(13.955785338622102, 121.16551093159686),
        initialZoom: 13.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
          subdomains: ['a', 'b', 'c', 'd'],
        ),

        CurrentLocationLayer(
          style: LocationMarkerStyle(
            marker: DefaultLocationMarker(
              child: Icon(
                Icons.location_pin,
                color: const Color.fromRGBO(62, 71, 149, 1),
                size: 40,
              ),
            ),
          ),
          positionStream: Geolocator.getPositionStream().map(
            (pos) => LocationMarkerPosition(
              latitude: pos.latitude,
              longitude: pos.longitude,
              accuracy: pos.accuracy,
            ),
          ),
        ),

        MarkerLayer(
          markers: [
            Marker(
              width: 40.0,
              height: 40.0,
              point: LatLng(13.955785338622102, 121.16551093159686),
              child: Icon(
                Icons.location_pin,
                color: const Color.fromRGBO(62, 71, 149, 1),
                size: 40,
              ),
            ),
          ],
        ),
      ],
    );
  }
}*/

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng _center = LatLng(13.955785338622102, 121.16551093159686);
  bool _isLocationEnabled = false;
  bool _showVehicleInfo = false;

  //Dummy
  LatLng vehicleLocation = LatLng(14.080033127659531, 121.15072812698516);

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initLocation();
    // Simulate vehicle movement every 3 seconds
    _timer = Timer.periodic(Duration(seconds: 60), (timer) {
      setState(() {
        vehicleLocation = LatLng(
          vehicleLocation.latitude,
          vehicleLocation.longitude + 0.0005, // Move slightly east
        );
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: Duration(seconds: 3)),
    );
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showMessage('Location services are disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showMessage('Location permission denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showMessage(
        'Location permission permanently denied. Please enable it in settings.',
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    setState(() {
      _center = LatLng(position.latitude, position.longitude);
      _isLocationEnabled = true;
    });
    _mapController.move(_center, 15.0);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocationEnabled) {
      return const Center(child: CircularProgressIndicator());
    }
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _center,
        initialZoom: 15.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
          subdomains: ['a', 'b', 'c', 'd'],
        ),
        CurrentLocationLayer(
          style: LocationMarkerStyle(marker: DefaultLocationMarker()),

          positionStream: Geolocator.getPositionStream().map(
            (pos) => LocationMarkerPosition(
              latitude: pos.latitude,
              longitude: pos.longitude,
              accuracy: pos.accuracy,
            ),
          ),
        ),
        MarkerLayer(
          markers: [
            Marker(
              width: 40.0,
              height: 40.0,
              point: vehicleLocation,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showVehicleInfo = !_showVehicleInfo;
                  });
                },
                child: Icon(Icons.directions_car, color: Colors.red, size: 40),
              ),
            ),
          ],
        ),

        if (_showVehicleInfo)
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Card(
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vehicle Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Location: ${vehicleLocation.latitude}, ${vehicleLocation.longitude}',
                    ),
                    Text('Speed: 60 km/h'),
                    Text('Status: Active'),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
