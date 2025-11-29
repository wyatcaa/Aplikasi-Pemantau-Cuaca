import 'package:flutter/material.dart';
import 'package:meteo/helpers/temp_converter.dart';
import 'package:meteo/models/weather_model.dart';
import 'package:meteo/screens/detailpage.dart';
import 'package:meteo/services/apiservices.dart';
import 'package:meteo/helpers/weather_helper.dart';
// Package tambahan untuk Lokasi
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/dbservices.dart';
import '../models/user_model.dart';

UserModel? user;
String _selectedUnit = "c";


// --- PALET WARNA (SOFT SKY BLUE GRADIENT) ---
const Color kBgTop = Color(0xFF6BAAFC); // Biru Langit Cerah
const Color kBgBottom = Color(0xFF3F82E8); // Biru Laut
const Color kCardBg = Color(0x25FFFFFF); // Putih Transparan (Glass Effect)
const Color kTextWhite = Colors.white;
const Color kTextGrey = Color(0xFFD4E4FF); // Putih kebiruan
const Color kAccentBlue = Color(0xFFB3D4FF);
const Color kAccentYellow = Color(0xFFFFD56F);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // --- State Variables ---
  WeatherModel? _weather;
  bool _isLoading = true;
  String _errorMessage = '';
  String _locationName = "Detecting Location...";

  // Instance Service
  final WeatherService _weatherService = WeatherService();

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
    _loadUserUnit(); 
  }

  // --- 1. Fungsi Cek Izin & Ambil Koordinat GPS ---
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Cek GPS Hidup/Mati
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // Cek Izin Aplikasi
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    // Ambil lokasi saat ini
    return await Geolocator.getCurrentPosition();
  }

  // --- 2. Fungsi Utama Load Data ---
  Future<void> _loadWeatherData() async {
    try {
      // A. Ambil Posisi
      Position position = await _determinePosition();

      // B. Ambil Nama Kota (Geocoding)
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String city =
              place.locality ?? place.subAdministrativeArea ?? "Unknown";
          String country = place.isoCountryCode ?? "";
          setState(() {
            _locationName = "$city, $country";
          });
        }
      } catch (e) {
        setState(() {
          _locationName = "My Location"; // Fallback jika gagal ambil nama kota
        });
      }

      // C. Ambil Data Cuaca API
      final data = await _weatherService.getWeatherFull(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _weather = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserUnit() async {
  try {
    user = await DBService().getUser();
    if (user != null) {
      setState(() {
        _selectedUnit = user!.tempUnit; // atau _selectedUnit = user!.tempUnit;
      });
    }
  } catch (e) {
    // optional: handle error
  }
}



  @override
  Widget build(BuildContext context) {
    // Tampilan Loading
    if (_isLoading) {
      return Scaffold(
        backgroundColor: kBgBottom,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: kAccentYellow),
              SizedBox(height: 16),
              Text(
                "Getting location & weather...",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    // Tampilan Error
    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: kBgBottom,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 50),
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = '';
                    });
                    _loadWeatherData();
                  },
                  child: const Text("Try Again"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // --- TAMPILAN UTAMA ---
    return Container(
      decoration: const BoxDecoration(
        // Background Gradiasi
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kBgTop, kBgBottom],
        ),
      ),
      child: Scaffold(
        backgroundColor:
            Colors.transparent, // Transparan biar kena gradasi container
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const Icon(Icons.location_on_outlined, color: kTextWhite),
          title: Text(
            _locationName,
            style: const TextStyle(
              color: kTextWhite,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                backgroundColor: Colors.white24,
                child: const Text("F", style: TextStyle(color: kAccentYellow)),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(),
              _buildHourlyForecastCard(),
              _buildWeeklyForecastCard(),
              _buildSectionTitle("Current conditions"),
              _buildCurrentConditionsGrid(),
              _buildSunriseSunsetCard(),
              _buildSectionTitle("Hourly details"),
              _buildHourlyDetailsCard(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ================= WIDGET SECTIONS =================

  Widget _buildHeaderSection() {
    final current = _weather!.current;
    final unit = _selectedUnit; // C/F atau unit dari settings

  final displayTemp = TempConverter.convert(
  value: current.temp,
  from: "c",
  to: unit,
).round();

final feelsTemp = TempConverter.convert(
  value: current.feelsLike,
  from: "c",
  to: unit,
).round();

final maxTemp = TempConverter.convert(
  value: _weather!.daily.tempMax[0],
  from: "c",
  to: unit,
).round();

final minTemp = TempConverter.convert(
  value: _weather!.daily.tempMin[0],
  from: "c",
  to: unit,
).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Now", style: TextStyle(color: kTextGrey, fontSize: 16)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
              "$displayTemp°",
                style: const TextStyle(
                  color: kTextWhite,
                  fontSize: 80,
                  fontWeight: FontWeight.w300,
                  height: 1,
                ),
              ),
              const Text(
                "°",
                style: TextStyle(color: kTextWhite, fontSize: 40, height: 1),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.cloud, color: kAccentYellow, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    "$displayTemp°",
                    textAlign: TextAlign.end,
                    style: const TextStyle(color: kTextGrey, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          Text(
            "High: ${_weather!.daily.tempMax[0].round()}° • Low: ${_weather!.daily.tempMin[0].round()}°",
            style: const TextStyle(color: kTextGrey, fontSize: 16),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHourlyForecastCard() {
    final hourly = _weather!.hourly;

    // Logic: Mulai dari jam sekarang
    int currentHour = DateTime.now().hour;
    int count = 24;
    // Cek sisa data agar tidak error array index
    if (currentHour + count > hourly.time.length) {
      count = hourly.time.length - currentHour;
    }

    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Hourly forecast",
            style: TextStyle(color: kTextWhite, fontSize: 16),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(count, (i) {
                // Geser index berdasarkan jam sekarang
                int index = currentHour + i;
                bool isNow = i == 0;

                return _buildHourlyItem(
                  time: isNow
                      ? "Now"
                      : WeatherUtils.formatTime(hourly.time[index]),
                  temp: hourly.temperature[index].round(),
                  precip: hourly.precipitation[index].round(),
                  icon: hourly.precipitation[index] > 50
                      ? Icons.umbrella
                      : Icons.cloud_queue,
                  isActive: isNow,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyForecastCard() {
    final daily = _weather!.daily;

    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "7-day forecast",
            style: TextStyle(color: kTextWhite, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: daily.time.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.white12),
            itemBuilder: (context, index) {
              return _buildDailyItem(
                day: index == 0
                    ? "Today"
                    : WeatherUtils.formatDate(daily.time[index]),
                icon: daily.tempMax[index] > 30 ? Icons.sunny : Icons.cloud,
                max: daily.tempMax[index].round(),
                min: daily.tempMin[index].round(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentConditionsGrid() {
    final current = _weather!.current;
    final aqi = _weather!.airQuality?.usAqi ?? 0;

    // Ukuran Icon lebih besar
    double iconSize = 50.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2, // Kotak agak tinggi biar ikon muat
        children: [
          _buildConditionCard(
            title: "Wind",
            value: current.windSpeed.toString(),
            unit: "km/h",
            subtitle: "Direction: ${current.windDirection}°",
            visualContent: Transform.rotate(
              angle: current.windDirection * (3.14 / 180),
              child: Icon(Icons.navigation, color: kTextWhite, size: iconSize),
            ),
          ),
          _buildConditionCard(
            title: "Humidity",
            value: current.humidity.toString(),
            unit: "%",
            subtitle: "Dew point -",
            visualContent: Icon(
              Icons.water_drop,
              color: kAccentBlue,
              size: iconSize,
            ),
          ),
          _buildConditionCard(
            title: "AQI (US)",
            value: aqi.round().toString(),
            unit: "",
            subtitle: aqi < 50 ? "Good" : "Moderate",
            visualContent: Icon(
              Icons.blur_on,
              color: Colors.white38,
              size: iconSize,
            ),
          ),
          _buildConditionCard(
            title: "Pressure",
            value: current.pressure.round().toString(),
            unit: "hPa",
            subtitle: "Surface",
            visualContent: Icon(
              Icons.speed,
              color: kAccentBlue,
              size: iconSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSunriseSunsetCard() {
    // Pastikan data _weather dan daily tidak null sebelum diakses
    if (_weather == null ||
        _weather!.daily.sunrise.isEmpty ||
        _weather!.daily.sunset.isEmpty) {
      return const SizedBox(); // Atau widget placeholder lain jika data belum siap
    }

    // Ambil data hari ini (index 0) dan format waktunya
    String sunrise = WeatherUtils.formatTime(_weather!.daily.sunrise[0]);
    String sunset = WeatherUtils.formatTime(_weather!.daily.sunset[0]);

    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul Card
          const Text(
            "Sunrise & sunset",
            style: TextStyle(color: kTextWhite, fontSize: 16),
          ),
          const SizedBox(height: 24), // Jarak sedikit diperbesar biar lega
          // Row Utama: Kiri (Sunrise) - Tengah (Visual) - Kanan (Sunset)
          Row(
            // Align items ke bawah agar teks jam sejajar dengan garis horizon
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // --- BAGIAN KIRI: SUNRISE ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Sunrise",
                    style: TextStyle(color: kTextGrey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sunrise,
                    style: const TextStyle(
                      color: kTextWhite,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              // --- BAGIAN TENGAH: VISUAL HORIZON ---
              // Gunakan Expanded agar mengisi ruang kosong di antara kiri dan kanan
              Expanded(
                child: Container(
                  height: 60, // Tinggi area visual disesuaikan
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                  ), // Jarak kiri kanan
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Garis Horizon
                      Container(height: 1, color: Colors.white24),
                      // Ikon Matahari
                      // Dibungkus Padding biar agak naik sedikit di atas garis
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        // Saya ganti iconnya jadi wb_sunny biar lebih pas,
                        // tapi kalau mau tetap sunny_snowing silakan diubah balik.
                        child: Icon(
                          Icons
                              .wb_sunny_outlined, // Atau gunakan icon pilihanmu sebelumnya
                          color: kAccentYellow,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- BAGIAN KANAN: SUNSET ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.end, // Teks rata kanan
                children: [
                  const Text(
                    "Sunset",
                    style: TextStyle(color: kTextGrey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sunset,
                    style: const TextStyle(
                      color: kTextWhite,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyDetailsCard() {
    return _buildCardContainer(
      child: const Text(
        "Grafik Detail (Implementasi Chart)",
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: kCardBg, // Warna Glass
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: kTextWhite,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildHourlyItem({
    required String time,
    required int temp,
    required int precip,
    required IconData icon,
    bool isActive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 24.0),
      child: Column(
        children: [
          Text(
            time,
            style: TextStyle(
              color: isActive ? kTextWhite : kTextGrey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "$precip%",
            style: const TextStyle(color: kAccentBlue, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Icon(icon, color: isActive ? kTextWhite : kTextGrey, size: 28),
          const SizedBox(height: 8),
          Text(
            "$temp°",
            style: const TextStyle(
              color: kTextWhite,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyItem({
    required String day,
    required int max,
    required int min,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              day,
              style: const TextStyle(color: kTextWhite, fontSize: 16),
            ),
          ),
          Icon(icon, color: kTextGrey, size: 24),
          Expanded(
            flex: 1,
            child: Text(
              "$max°/$min°",
              textAlign: TextAlign.end,
              style: const TextStyle(color: kTextWhite, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  // Desain Card Grid (Icon Center)
  Widget _buildConditionCard({
    required String title,
    required String value,
    required String unit,
    required String subtitle,
    required Widget visualContent,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: kTextWhite, fontSize: 14)),
          // Ikon di Tengah
          Expanded(child: Center(child: visualContent)),
          // Nilai di Bawah
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: kTextWhite,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(color: kTextGrey, fontSize: 12),
              ),
            ],
          ),
          Text(
            subtitle,
            style: const TextStyle(color: kTextGrey, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
