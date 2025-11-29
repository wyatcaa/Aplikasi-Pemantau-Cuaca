import 'package:flutter/material.dart';
import 'package:meteo/models/user_model.dart';
import 'package:meteo/screens/detailpage.dart';
import '../models/location_model.dart';
import '../widgets/search_widget.dart';
import '../services/dbservices.dart';
import '../services/apiservices.dart';
import '../helpers/temp_converter.dart';

const Color kBgTop = Color(0xFF6BAAFC);
const Color kBgBottom = Color(0xFF3F82E8);
const Color kCardBg = Color(0x33FFFFFF);
const Color kTextWhite = Colors.white;
const Color kTextGrey = Color(0xFFE0E6FF);
const Color kAccentYellow = Color(0xFFFFD56F);

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
  String _selectedUnit = "c";
  UserModel? user;

  final Map<String, double> _tempCache = {};
  final Map<String, bool> _loadingTemp = {};

  @override
  void initState() {
    super.initState();
    _loadUserUnit();
    _loadHistory();
  }

  // Load unit suhu dari profil user
  Future<void> _loadUserUnit() async {
    try {
      final user = await _dbService.getUser();
      if (user != null && user.tempUnit.isNotEmpty) {
        setState(() => _selectedUnit = user.tempUnit.toLowerCase());
      }
    } catch (e) {
      print("Gagal load user unit: $e");
    }
  }

  // Load riwayat lokasi
  void _loadHistory() async {
    final history = await _dbService.getLocations();
    if (!mounted) return;
    setState(() => _history = history);

    for (var loc in history) {
      _fetchTemperatureForHistory(loc);
    }
  }

  // Ambil suhu untuk masing-masing lokasi di riwayat
  Future<void> _fetchTemperatureForHistory(LocationModel loc) async {
    final key = "${loc.latitude}_${loc.longitude}";
    if (_tempCache.containsKey(key)) return;

    if (mounted) setState(() => _loadingTemp[key] = true);

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
      if (mounted) setState(() => _loadingTemp[key] = false);
    }
  }

  // Saat user memilih lokasi
  void _onSelect(LocationModel loc) async {
    await _dbService.saveLocation(loc);
    _loadHistory();
    setState(() => _selected = loc);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailPage(
          loc: {'lat': loc.latitude, 'lon': loc.longitude, 'name': loc.name},
        ),
      ),
    );

    if (mounted) setState(() => _selected = null);
  }

  // Hapus semua riwayat
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
      child: Container(
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
            title: const Text(
              'Pencarian',
              style: TextStyle(color: kTextWhite, fontWeight: FontWeight.w600),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: kTextWhite,
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

                  // --- Riwayat Pencarian ---
                  if (_history.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Riwayat Pencarian',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: kTextWhite),
                        ),
                        TextButton(
                          onPressed: _clearHistory,
                          child: const Text('Hapus Semua', style: TextStyle(color: kAccentYellow)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: _history.map((loc) {
                        final key = "${loc.latitude}_${loc.longitude}";
                        final isLoading = _loadingTemp[key] == true;
                        final temp = _tempCache[key];
                        final displayTemp = temp != null
                            ? TempConverter.convert(value: temp, from: "c", to: _selectedUnit).round()
                            : null;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: kCardBg,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.history, color: kTextWhite),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${loc.name}, ${loc.country}',
                                  style: const TextStyle(
                                    color: kTextWhite,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (isLoading)
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: kAccentYellow),
                                )
                              else if (displayTemp != null)
                                Text(
                                  '$displayTemp°${_selectedUnit.toUpperCase()}',
                                  style: const TextStyle(
                                    color: kAccentYellow,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    // --- Teks jika riwayat kosong ---
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 200),
                        child: Text(
                          'Riwayat Pencarian Kosong',
                          style: TextStyle(
                            color: kTextWhite.withOpacity(0.7),
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
