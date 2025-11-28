import 'package:flutter/material.dart';
import 'package:meteo/models/location_model.dart';
import 'package:meteo/models/weather_model.dart';
import 'package:meteo/screens/detailpage.dart';
import 'package:meteo/services/dbservices.dart';
import 'package:meteo/services/apiservices.dart'; 

// --- PALET WARNA (SAMA SEPERTI HOME) ---
const Color kBgTop = Color(0xFF6BAAFC);
const Color kBgBottom = Color(0xFF3F82E8);
const Color kCardBg = Color(0x25FFFFFF); // Glass Effect
const Color kTextWhite = Colors.white;
const Color kTextGrey = Color(0xFFD4E4FF);
const Color kAccentYellow = Color(0xFFFFD56F);

class SavedPage extends StatefulWidget {
  const SavedPage({super.key});

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  final DBService _dbService = DBService();
  final WeatherService _weatherService = WeatherService();

  // Kita butuh list yang menampung Lokasi DAN Data Cuacanya
  // Struktur: [{'loc': LocationModel, 'weather': WeatherModel?}]
  List<Map<String, dynamic>> _savedData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedLocations();
  }

  // 1. Ambil Bookmark DB + Fetch Cuaca Terkini API
  Future<void> _loadSavedLocations() async {
    setState(() => _isLoading = true);
    
    // Ambil data lokasi dari Database SQLite
    final bookmarks = await _dbService.getBookmarks();
    List<Map<String, dynamic>> tempData = [];

    // Loop setiap lokasi untuk ambil cuaca real-time
    for (var loc in bookmarks) {
      WeatherModel? weather;
      try {
        // Panggil API Weather untuk lat/lon lokasi ini
        weather = await _weatherService.getWeatherFull(loc.latitude, loc.longitude);
      } catch (e) {
        print("Gagal ambil cuaca untuk ${loc.name}: $e");
        weather = null; // Kalau gagal (offline), cuaca null
      }

      tempData.add({
        'loc': loc,
        'weather': weather,
      });
    }

    if (mounted) {
      setState(() {
        _savedData = tempData;
        _isLoading = false;
      });
    }
  }

  // 2. Hapus Lokasi
  Future<void> _deleteLocation(double lat, double lon) async {
    await _dbService.removeBookmark(lat, lon);
    _loadSavedLocations(); // Refresh list ulang
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kBgTop, kBgBottom],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: kTextWhite),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Saved Locations",
            style: TextStyle(
              color: kTextWhite,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: kAccentYellow))
            : _savedData.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: _savedData.length,
                    itemBuilder: (context, index) {
                      final item = _savedData[index];
                      return _buildLocationCard(
                        item['loc'] as LocationModel,
                        item['weather'] as WeatherModel?,
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border, size: 80, color: kTextWhite.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            "No locations saved yet.",
            style: TextStyle(color: kTextWhite.withOpacity(0.8), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(LocationModel loc, WeatherModel? weather) {
    
    String tempStr = "--";
    IconData weatherIcon = Icons.cloud_off; 

    if (weather != null) {
      tempStr = "${weather.current.temp.round()}°";
      
      double precip = weather.current.rain ?? 0.0; 
      if (precip > 0.0) {
        weatherIcon = Icons.umbrella; // Hujan
      } else if (weather.current.temp > 28) {
         weatherIcon = Icons.wb_sunny_rounded; // Panas -> Cerah
      } else {
         weatherIcon = Icons.cloud; // Sejuk -> Berawan
      }
    }

    return Dismissible(
      key: Key(loc.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.redAccent.withOpacity(0.8),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _deleteLocation(loc.latitude, loc.longitude);
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailPage(
                loc: {
                  'lat': loc.latitude,
                  'lon': loc.longitude,
                  'name': loc.name,
                },
              ),
            ),
          ).then((_) => _loadSavedLocations()); 
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.name,
                      style: const TextStyle(
                        color: kTextWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.country.isNotEmpty ? loc.country : "Lat: ${loc.latitude.toStringAsFixed(2)}",
                      style: const TextStyle(color: kTextGrey, fontSize: 14),
                    ),
                  ],
                ),
              ),

              if (weather != null) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(weatherIcon, color: kAccentYellow, size: 32),
                    const SizedBox(height: 4),
                    Text(
                      tempStr,
                      style: const TextStyle(
                        color: kTextWhite,
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                 const SizedBox(
                   width: 20, 
                   height: 20, 
                   child: CircularProgressIndicator(strokeWidth: 2, color: kTextGrey)
                 )
              ]
            ],
          ),
        ),
      ),
    );
  }
}