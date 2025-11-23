import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  Future<List<Map<String, dynamic>>> search(String name, {int count = 5}) async {
    final encoded = Uri.encodeQueryComponent(name);
    final url = Uri.parse('https://geocoding-api.open-meteo.com/v1/search?name=$encoded&count=$count');
    final resp = await http.get(url);
    if (resp.statusCode != 200) return [];
    final json = jsonDecode(resp.body);
    if (json['results'] == null) return [];
    return List<Map<String, dynamic>>.from(json['results']);
  }
}
