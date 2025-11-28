import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';
import '../models/location_model.dart';

class WeatherService {
  // Base URLs
  static const String _weatherBaseUrl = "https://api.open-meteo.com/v1/forecast";
  static const String _geoBaseUrl = "https://geocoding-api.open-meteo.com/v1/search";
  static const String _aqiBaseUrl = "https://air-quality-api.open-meteo.com/v1/air-quality";

  /// 1. Mencari Lokasi (Geocoding)
  /// Digunakan di fitur Search
  Future<List<LocationModel>> searchCity(String query) async {
    final url = Uri.parse("$_geoBaseUrl?name=$query&count=5&language=id&format=json");
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'] != null) {
          return (data['results'] as List)
              .map((e) => LocationModel.fromJson(e))
              .toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception("Gagal mencari kota: $e");
    }
  }

  /// 2. Mengambil Data Cuaca Lengkap + AQI
  /// Digunakan di fitur Beranda & Detail
  Future<WeatherModel> getWeatherFull(double lat, double lon) async {
    try {
      // Request 1: Data Cuaca (Weather Forecast)
      // Parameter disesuaikan dengan kebutuhan fitur (hourly, daily, current)
      final weatherUrl = Uri.parse(
        "$_weatherBaseUrl?latitude=$lat&longitude=$lon"
        "&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,rain,pressure_msl,surface_pressure,wind_speed_10m,wind_direction_10m"
        "&hourly=temperature_2m,relative_humidity_2m,precipitation_probability,wind_speed_10m"
        "&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset,precipitation_sum"
        "&timezone=auto" 
      );

      // Request 2: Data Kualitas Udara (AQI US)
      // Open-Meteo memisahkan endpoint AQI
      final aqiUrl = Uri.parse(
        "$_aqiBaseUrl?latitude=$lat&longitude=$lon&current=us_aqi"
      );

      // Jalankan request secara parallel agar cepat
      final results = await Future.wait([
        http.get(weatherUrl),
        http.get(aqiUrl),
      ]);

      final weatherRes = results[0];
      final aqiRes = results[1];

      if (weatherRes.statusCode == 200 && aqiRes.statusCode == 200) {
        final weatherData = jsonDecode(weatherRes.body);
        final aqiData = jsonDecode(aqiRes.body);

        // Gabungkan kedua data ke dalam satu Model
        return WeatherModel.fromJson(weatherData, aqiJson: aqiData);
      } else {
        throw Exception("Gagal mengambil data cuaca");
      }
    } catch (e) {
      throw Exception("Error koneksi: $e");
    }
  }
}