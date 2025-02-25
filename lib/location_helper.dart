import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final String city;
  final String country;
  final String address;
  final String postalCode;
  final String administrative;
  final String? street;
  final double? accuracy;
  final double? altitude;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.country,
    required this.address,
    required this.postalCode,
    required this.administrative,
    this.street,
    this.accuracy,
    this.altitude,
  });
}

enum LocationError {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  networkError,
  unknown
}

class LocationResult {
  final LocationData? data;
  final LocationError? error;

  LocationResult({this.data, this.error});

  bool get isSuccess => data != null;
  bool get isError => error != null;
}

class LocationHelper {
  /// Verifica a conectividade com a internet
  Future<bool> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Solicita permissão de localização e retorna dados detalhados da localização do usuário
  Future<LocationResult> getUserLocation() async {
    try {
      // Verifica conexão com a internet
      bool hasConnection = await _checkConnectivity();
      if (!hasConnection) {
        return LocationResult(error: LocationError.networkError);
      }

      // Verifica se o serviço de localização está ativado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult(error: LocationError.serviceDisabled);
      }

      // Verifica a permissão de localização
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Solicita permissão
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult(error: LocationError.permissionDenied);
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult(error: LocationError.permissionDeniedForever);
      }

      // Obtém a localização do usuário com timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Converte coordenadas para cidade e país
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
        // localeIdentifier: 'pt_BR', // Prioriza idioma português
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        // Formatação melhorada do endereço
        String formattedAddress = _formatAddress(place);

        return LocationResult(
          data: LocationData(
            latitude: position.latitude,
            longitude: position.longitude,
            city:
                place.locality ?? place.subAdministrativeArea ?? 'Desconhecido',
            country: place.country ?? 'Desconhecido',
            address: formattedAddress,
            postalCode: place.postalCode ?? 'Desconhecido',
            administrative: place.administrativeArea ?? 'Desconhecido',
            street: place.thoroughfare,
            accuracy: position.accuracy,
            altitude: position.altitude,
          ),
        );
      }

      return LocationResult(error: LocationError.unknown);
    } catch (e) {
      debugPrint('Erro ao obter localização: $e');
      return LocationResult(error: LocationError.unknown);
    }
  }

  /// Formata o endereço de maneira legível
  String _formatAddress(Placemark place) {
    List<String> addressParts = [];

    if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
      String streetNumber =
          place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty
              ? '${place.thoroughfare}, ${place.subThoroughfare}'
              : place.thoroughfare!;
      addressParts.add(streetNumber);
    }

    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      addressParts.add(place.subLocality!);
    }

    if (place.locality != null && place.locality!.isNotEmpty) {
      addressParts.add(place.locality!);
    }

    if (place.administrativeArea != null &&
        place.administrativeArea!.isNotEmpty) {
      addressParts.add(place.administrativeArea!);
    }

    if (place.country != null && place.country!.isNotEmpty) {
      addressParts.add(place.country!);
    }

    return addressParts.join(', ');
  }

  /// Calcula a distância entre duas coordenadas
  double calculateDistance(double startLatitude, double startLongitude,
      double endLatitude, double endLongitude) {
    return Geolocator.distanceBetween(
        startLatitude, startLongitude, endLatitude, endLongitude);
  }

  /// Abre configurações de localização
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Abre configurações do aplicativo
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}
