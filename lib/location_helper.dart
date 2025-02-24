import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationHelper {
  /// Request location permission and return user location with city and country
  Future<Map<String, dynamic>?> getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    /// Check if location service is enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      /// Location service is not enabled
      return null;
    }

    /// Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      /// Request permission
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        /// Location permission denied
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    /// Get user location
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      /// Convert coordinates to city and country
      List<Placemark> placemark = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemark.isNotEmpty) {
        Placemark place = placemark[0];

        /// For Testing
        debugPrint(placemark[0].toString());

        return {
          'city': place.locality ?? 'Unknown',
          'country': place.country ?? 'Unknown',
          'latitude': position.latitude,
          'longitude': position.longitude,
          'address': '${place.street}, ${place.locality}, ${place.country}',
        };
      }
      return null;
    } catch (e) {}
    return null;
  }
}
