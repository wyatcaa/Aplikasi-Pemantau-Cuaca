import 'package:flutter/material.dart';
import 'package:meteo/models/location_model.dart';
import 'package:meteo/models/user_model.dart';
import 'package:meteo/models/weather_model.dart';
import 'package:meteo/services/dbservices.dart';
import 'package:meteo/services/apiservices.dart';
import 'package:meteo/screens/detailpage.dart';
import '../helpers/temp_converter.dart';

const Color kBgTop = Color(0xFF6BAAFC);
const Color kBgBottom = Color(0xFF3F82E8);
const Color kCardBg = Color(0x33FFFFFF);
const Color kTextWhite = Colors.white;
const Color kTextGrey = Color(0xFFE0E6FF);
const Color kAccentYellow = Color(0xFFFFD56F);

class SavedPage extends StatefulWidget {
  const SavedPage({super.key});

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  final DBService _dbService = DBService();
  final WeatherService _weatherService = WeatherService();

  List<Map<String, dynamic>> _savedData = [];
  bool _isLoading = true;
  String _selectedUnit = "c";
  UserModel? user;

  @override
  void initState() {
    super.initState();
    _loadUserUnit();
    _loadSavedLocations();
  }

  Future<void> _loadUserUnit() async {
    try {
      user = await _dbService.getUser();
      if (user != null && user!.tempUnit.isNotEmpty && mounted) {
        setState(() => _selectedUnit = user!.tempUnit.toLowerCase());
      }
    } catch (e) {
      print("Gagal load unit user: $e");
    }
  }

  Future<void> _loadSavedLocations() async {
    setState(() => _isLoading = true);
    await _loadUserUnit();

    final bookmarks = await _dbService.getBookmarks();
    List<Map<String, dynamic>> tempData = [];

    for (var loc in bookmarks) {
      WeatherModel? weather;
      try {
        weather = await _weatherService.getWeatherFull(loc.latitude, loc.longitude);
      } catch (e) {
        print("Gagal ambil cuaca untuk ${loc.name}: $e");
      }
      tempData.add({'loc': loc, 'weather': weather});
    }

    if (mounted) {
      setState(() {
        _savedData = tempData;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteLocation(double lat, double lon) async {
    await _dbService.removeBookmark(lat, lon);
    _loadSavedLocations();
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
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: const Text(
            "Saved Locations",
            style: TextStyle(
              color: kTextWhite,
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: 1.0,
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: kAccentYellow))
            : _savedData.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
    String tempUnitSymbol = _selectedUnit.toUpperCase();
    if (tempUnitSymbol == 'C') tempUnitSymbol = '°C';
    else if (tempUnitSymbol == 'F') tempUnitSymbol = '°F';
    else if (tempUnitSymbol == 'K') tempUnitSymbol = ' K';

    if (weather != null) {
      double convertedTemp = TempConverter.convert(
        value: weather.current.temp,
        from: "c",
        to: _selectedUnit,
      );
      tempStr = "${convertedTemp.round()}";
      double precip = weather.current.rain;

      if (precip > 0.0) weatherIcon = Icons.umbrella;
      else if (weather.current.temp > 28) weatherIcon = Icons.wb_sunny_rounded;
      else weatherIcon = Icons.cloud;
    }

    return Dismissible(
      key: Key(loc.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.8),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      onDismissed: (_) => _deleteLocation(loc.latitude, loc.longitude),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailPage(
                loc: {'lat': loc.latitude, 'lon': loc.longitude, 'name': loc.name},
              ),
            ),
          ).then((_) => _loadSavedLocations());
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
            ],
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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black12)],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: kTextGrey, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            loc.country.isNotEmpty ? loc.country : "Lat: ${loc.latitude.toStringAsFixed(2)}",
                            style: const TextStyle(color: kTextGrey, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (weather != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(weatherIcon, color: kAccentYellow, size: 36),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tempStr,
                            style: const TextStyle(
                              color: kTextWhite,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            tempUnitSymbol,
                            style: const TextStyle(
                              color: kTextWhite,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: kTextGrey),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
