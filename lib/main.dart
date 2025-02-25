import 'package:flutter/material.dart';
import 'package:localizations/location_helper.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final LocationHelper _locationHelper = LocationHelper();

  String _location = 'No data';
  bool _isLoading = true;

  Future<void> getUserLocation() async {
    setState(() {
      _isLoading = true;
    });
    final locationData = await _locationHelper.getUserLocation();

    if (locationData != null) {
      setState(() {
        _location =
            'Latitude ${locationData['latitude']}, Longitude: ${locationData['longitude']}';
        _isLoading = false;
      });
    } else {
      setState(() {
        _location = 'Location not found';
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    getUserLocation();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: _isLoading
              ? CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_location),
                    ElevatedButton(
                      onPressed: () {
                        getUserLocation();
                      },
                      child: Text('Refresh Location'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
