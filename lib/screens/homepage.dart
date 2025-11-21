import 'package:flutter/material.dart';
import '../../models/weather_model.dart';
import 'package:meteo/services/apiservices.dart';
import 'package:meteo/helpers/weather_helper.dart';


const Color kDarkBg = Color(0xFF1A1C2A);
const Color kCardBg = Color(0xFF2B3045);
const Color kTextWhite = Colors.white;
const Color kTextGrey = Color(0xFFB0B5C8);
const Color kAccentBlue = Color(0xFF8AB4F8);
const Color kAccentYellow = Color(0xFFFDD663);

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
  String _locationName = "Yogyakarta, ID"; // Default location name

  // Instance Service
  final WeatherService _weatherService = WeatherService();

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  // --- Fungsi Fetch Data ---
  Future<void> _loadWeatherData() async {
    try {
      // TODO: Ambil Lat/Lon dari DatabaseHelper (Fitur Saved Location)
      // Untuk demo ini, kita hardcode Lat/Lon Yogyakarta dulu
      double lat = -7.7956;
      double lon = 110.3695;

      final data = await _weatherService.getWeatherFull(lat, lon);

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

  @override
  Widget build(BuildContext context) {
    // Tampilan Loading
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kDarkBg,
        body: Center(child: CircularProgressIndicator(color: kAccentYellow)),
      );
    }

    // Tampilan Error
    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: kDarkBg,
        body: Center(
          child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    // Tampilan Utama (Jika Data Ada)
    return Scaffold(
      backgroundColor: kDarkBg,
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
              backgroundColor: const Color(0xFF6C4F40),
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
    );
  }

  // ================= WIDGET SECTIONS (DINAMIS) =================

  Widget _buildHeaderSection() {
    // Ambil data current
    final current = _weather!.current;
    // Icon cuaca berdasarkan WMO code (misal 95 = Petir) (Kode ada di current tidak ya? Cek model)
    // Catatan: Di model weather_model.dart sebelumnya, kita belum mapping 'weather_code'.
    // Asumsikan kamu menambahkan field `weatherCode` di Model CurrentWeather.
    // Jika belum, pakai dummy icon dulu atau update modelnya.
    // Anggap saja kita ambil description cuaca secara general.

    return Stack(
      children: [
        // Background Placeholder
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [kDarkBg.withOpacity(0), kCardBg],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Now",
                style: TextStyle(color: kTextGrey, fontSize: 16),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Suhu (Dinamis)
                  Text(
                    current.temp.round().toString(),
                    style: const TextStyle(
                      color: kTextWhite,
                      fontSize: 80,
                      fontWeight: FontWeight.w300,
                      height: 1,
                    ),
                  ),
                  const Text(
                    "°",
                    style: TextStyle(
                      color: kTextWhite,
                      fontSize: 40,
                      height: 1,
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Icon(
                        Icons.cloud,
                        color: kAccentYellow,
                        size: 40,
                      ), // Ikon default
                      const SizedBox(height: 8),
                      // Feels Like (Dinamis)
                      Text(
                        "Feels like ${current.feelsLike.round()}°",
                        textAlign: TextAlign.end,
                        style: const TextStyle(color: kTextGrey, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
              // High / Low (Ambil dari data harian index ke-0 yaitu hari ini)
              Text(
                "High: ${_weather!.daily.tempMax[0].round()}° • Low: ${_weather!.daily.tempMin[0].round()}°",
                style: const TextStyle(color: kTextGrey, fontSize: 16),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyForecastCard() {
    final hourly = _weather!.hourly;

    // Ambil hanya 24 jam ke depan agar list tidak kepanjangan
    int itemCount = hourly.time.length > 24 ? 24 : hourly.time.length;

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
              children: List.generate(itemCount, (index) {
                // Logic sederhana ambil jam sekarang vs jam data
                bool isNow = index == 0;
                return _buildHourlyItem(
                  time: isNow
                      ? "Now"
                      : WeatherUtils.formatTime(hourly.time[index]),
                  temp: hourly.temperature[index].round(),
                  precip: hourly.precipitation[index].round(),
                  // Di real app, map weather_code hourly ke Icon
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
          // Generate List Harian
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
                // Logic dummy: jika max temp < 25 mungkin hujan
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
        children: [
          _buildConditionCard(
            title: "Wind",
            value: current.windSpeed.toString(),
            unit: "km/h",
            subtitle: "Direction: ${current.windDirection}°",
            visualContent: Transform.rotate(
              angle:
                  current.windDirection *
                  (3.14 / 180), // Konversi derajat ke radian
              child: const Icon(Icons.navigation, color: kTextWhite, size: 40),
            ),
          ),
          _buildConditionCard(
            title: "Humidity",
            value: current.humidity.toString(),
            unit: "%",
            subtitle: "Dew point -", // Perlu hitungan rumus jika mau akurat
            visualContent: const Icon(
              Icons.water_drop,
              color: kAccentBlue,
              size: 40,
            ),
          ),
          _buildConditionCard(
            title: "AQI (US)",
            value: aqi.round().toString(),
            unit: "",
            subtitle: aqi < 50 ? "Good" : "Moderate",
            visualContent: Icon(
              Icons.masks,
              color: aqi < 50 ? Colors.green : Colors.orange,
              size: 40,
            ),
          ),
          _buildConditionCard(
            title: "Pressure",
            value: current.pressure.round().toString(),
            unit: "hPa",
            subtitle: "Surface",
            visualContent: const Icon(
              Icons.speed,
              color: kAccentBlue,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSunriseSunsetCard() {
    // Ambil data hari ini (index 0)
    String sunrise = WeatherUtils.formatTime(_weather!.daily.sunrise[0]);
    String sunset = WeatherUtils.formatTime(_weather!.daily.sunset[0]);

    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Sunrise & sunset",
            style: TextStyle(color: kTextWhite, fontSize: 16),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Sunrise", style: TextStyle(color: kTextGrey)),
                  Text(
                    sunrise,
                    style: const TextStyle(color: kTextWhite, fontSize: 24),
                  ),
                  const SizedBox(height: 20),
                  const Text("Sunset", style: TextStyle(color: kTextGrey)),
                  Text(
                    sunset,
                    style: const TextStyle(color: kTextWhite, fontSize: 24),
                  ),
                ],
              ),
              Expanded(
                child: SizedBox(
                  height: 100,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(height: 1, color: Colors.white24),
                      const Icon(
                        Icons.sunny_snowing,
                        color: kAccentYellow,
                        size: 40,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ... (Widget _buildHourlyDetailsCard dan Helper UI lainnya sama persis seperti kode sebelumnya)
  // Paste _buildHourlyDetailsCard, _buildCardContainer, _buildSectionTitle,
  // _buildHourlyItem, _buildDailyItem, _buildConditionCard di sini.

  // --- COPY PASTE BAGIAN VISUAL DARI KODE SEBELUMNYA DI SINI ---
  // Saya singkat agar tidak terlalu panjang, gunakan helper visual yang saya buat di respon sebelumnya

  Widget _buildHourlyDetailsCard() {
    // Placeholder, logika sama dengan Hourly Forecast tapi tampilan grafik
    return _buildCardContainer(
      child: const Text(
        "Grafik Detail (Implementasi Chart)",
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: kCardBg,
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
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: kTextWhite,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
