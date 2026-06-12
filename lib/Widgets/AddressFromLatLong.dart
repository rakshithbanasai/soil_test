import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String> getAddressFromLatLng(double lat, double lng) async {
  // 1. Guard against invalid/empty coordinates
  if (lat == 0.0 || lng == 0.0) {
    return "Location not available";
  }

  try {
    // 2. Attempt using the native geocoding package
    List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

    if (placemarks.isNotEmpty) {
      Placemark place = placemarks[0];

      List<String> addressParts = [
        place.name ?? '',
        // place.subLocality ?? '',
        place.locality ?? '',
        // place.administrativeArea ?? '',
        // place.postalCode ?? '',
      ];

      String filteredAddress = addressParts
          .where((part) => part.isNotEmpty && part != place.postalCode) // Avoid duplicating postal code if it's in the name
          .join(", ");

      if (place.postalCode != null) {
        filteredAddress += " - ${place.postalCode}";
      }

      return filteredAddress.isNotEmpty ? filteredAddress : "Address details unavailable";
    }
  } catch (e) {
    print("Native geocoding failed, trying fallback: $e");
    // 3. Fallback to OpenStreetMap (Nominatim) if the native plugin fails
    return await _getFallbackAddress(lat, lng);
  }
  return "Address not found";
}

/// Fallback method using OpenStreetMap API (Free, no API key required)
Future<String> _getFallbackAddress(double lat, double lng) async {
  try {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1');

    final response = await http.get(url, headers: {
      'User-Agent': 'SoilTestApp' // Nominatim requires a User-Agent header
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['display_name'] ?? "Address unavailable";
    }
  } catch (e) {
    print("Fallback geocoding failed: $e");
  }
  return "Location service busy";
}