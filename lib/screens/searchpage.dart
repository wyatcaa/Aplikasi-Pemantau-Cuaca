import 'package:flutter/material.dart';
import 'package:meteo/screens/detailpage.dart';
import '../models/location_model.dart';
import '../widgets/search_widget.dart';
import '../services/dbservices.dart';
import '../services/apiservices.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final DBService _dbService = DBService(); 
  final WeatherService _weatherService = WeatherService();

  LocationModel? _selected;
  List<LocationModel> _history = [];

  // to store temperatures fetched for each history item
  final Map<String, double> _tempCache = {};
  final Map<String, bool> _loadingTemp = {};

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() async {
  final history = await _dbService.getLocations();

  if (!mounted) return; // pastikan widget masih aktif sebelum setState
  setState(() {
    _history = history;
  });

  // After loading history, fetch temperature for each location
  for (var loc in history) {
    // panggil async tapi tidak menunggu secara blocking
    _fetchTemperatureForHistory(loc);
  }
}

  Future<void> _fetchTemperatureForHistory(LocationModel loc) async {
    final key = "${loc.latitude}_${loc.longitude}";

    if (_tempCache.containsKey(key)) return;

    if (mounted) {
      setState(() {
        _loadingTemp[key] = true;
      });
    }

    try {
      final weather = await _weatherService.getWeatherFull(loc.latitude, loc.longitude);
      double temp = weather.current.temp;

      if (mounted) {
        setState(() {
          _tempCache[key] = temp;
          _loadingTemp[key] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingTemp[key] = false;
        });
      }
    }
  }


  void _onSelect(LocationModel loc) async {
    await _dbService.saveLocation(loc);
    _loadHistory();
    setState(() => _selected = loc);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailPage(
            loc: {
              'lat': loc.latitude,  // Ambil latitude dari object
              'lon': loc.longitude, // Ambil longitude dari object
              'name': loc.name,     // Ambil nama dari object
          },
          ),
      ),
    );

    if (mounted) {
      setState(() {
        _selected = null;
      });
    }
  }

  void _clearHistory() async {
    await _dbService.clearAllHistory();
    setState(() {
      _history.clear();
      _tempCache.clear();
      _loadingTemp.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Pencarian',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          backgroundColor: Color(0xFF6BAAFC),
          foregroundColor: Colors.white,
        ),

        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                SearchLocationWidget(onSelect: _onSelect),

                const SizedBox(height: 24),

                // HISTORY SECTION
                if (_history.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Riwayat Pencarian',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: _clearHistory,
                        child: const Text('Hapus Semua'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Column(
                    children: _history.map((loc) {
                      final key = "${loc.latitude}_${loc.longitude}";
                      final isLoading = _loadingTemp[key] == true;
                      final temp = _tempCache[key];

                      return Card(
                        color: Color(0xFF58A0C8).withOpacity(0.9),
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 1,
                        child: ListTile(
                          leading: const Icon(Icons.history, color: Colors.white),

                          // LOCATION NAME
                          title: Text(
                            '${loc.name}, ${loc.country}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          // TEMPERATURE OR LOADING
                          trailing: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  temp != null ? "${temp.toStringAsFixed(1)}°C" : "-",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                          onTap: () {
                            FocusScope.of(context).unfocus();
                            _onSelect(loc);
                          },
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
