import 'package:flutter/material.dart';
import 'package:meteo/helpers/temp_converter.dart'; 
import 'package:meteo/models/location_model.dart';
import 'package:meteo/models/user_model.dart';
import 'package:meteo/models/weather_model.dart';
import 'package:meteo/services/apiservices.dart';
import 'package:meteo/helpers/weather_helper.dart';
import 'package:geocoding/geocoding.dart';
import 'package:meteo/services/dbservices.dart';
import 'dart:math' as math; 

const Color kBgTop = Color(0xFF6BAAFC);
const Color kBgBottom = Color(0xFF3F82E8);
const Color kCardBg = Color(0x25FFFFFF); 
const Color kTextWhite = Colors.white;
const Color kTextGrey = Color(0xFFD4E4FF);
const Color kAccentBlue = Color(0xFFB3D4FF);
const Color kAccentYellow = Color(0xFFFFD56F);

class DetailPage extends StatefulWidget {
  final dynamic loc;

  const DetailPage({super.key, required this.loc});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  WeatherModel? _weather;
  bool _isLoading = true;
  String _errorMessage = '';
  String _locationName = "Loading...";
  
  final DBService _dbService = DBService();
  bool _isBookmarked = false;

  final WeatherService _weatherService = WeatherService();
  UserModel? user;
  String _selectedUnit = "c";

  String _selectedDetailType = 'Wind';

  @override
  void initState() {
    super.initState();
    _loadUserUnit();
    _loadWeatherData();
    _checkBookmarkStatus();
  }

  Future<void> _checkBookmarkStatus() async {
    try {
      double lat = double.parse(widget.loc['lat'].toString());
      double lon = double.parse(widget.loc['lon'].toString());
      bool exists = await _dbService.isBookmarked(lat, lon);
      if (mounted) {
        setState(() {
          _isBookmarked = exists;
        });
      }
    } catch (e) {
      print("Error checking bookmark: $e");
    }
  }

  Future<void> _loadUserUnit() async {
    try {
      user = await DBService().getUser();
      if (user != null && mounted) {
        setState(() {
          _selectedUnit = user!.tempUnit.toLowerCase();
        });
      }
    } catch (e) {
      print("Gagal load user unit: $e");
    }
  }

  void _toggleBookmark() async {
    if (_locationName == "Loading..." || _locationName == "Unknown Location") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tunggu sebentar, sedang memuat lokasi...")),
      );
      return;
    }

    try {
      double lat = double.parse(widget.loc['lat'].toString());
      double lon = double.parse(widget.loc['lon'].toString());
      String name = _locationName;
      String country = "";

      if (_locationName.contains(',')) {
        List<String> parts = _locationName.split(',');
        name = parts[0].trim();
        country = parts.length > 1 ? parts[1].trim() : "";
      } else if (_locationName == "Unknown Location") {
        name = "Koordinat ($lat, $lon)";
      }

      LocationModel locationData = LocationModel(
        name: name,
        country: country,
        latitude: lat,
        longitude: lon,
        timezone: '',
      );

      if (_isBookmarked) {
        await _dbService.removeBookmark(lat, lon);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Dihapus dari simpanan"),
              backgroundColor: Colors.redAccent,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        await _dbService.addBookmark(locationData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Lokasi berhasil disimpan!"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }

      setState(() {
        _isBookmarked = !_isBookmarked;
      });
    } catch (e) {
      print("Gagal toggle bookmark: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan: $e")),
      );
    }
  }

  Future<void> _loadWeatherData() async {
    try {
      double lat = double.parse(widget.loc['lat'].toString());
      double lon = double.parse(widget.loc['lon'].toString());

      if (widget.loc['name'] != null && widget.loc['name'].toString().isNotEmpty) {
        setState(() {
          _locationName = widget.loc['name'];
        });
      } else {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            String city = place.locality ?? place.subAdministrativeArea ?? "Unknown";
            String country = place.isoCountryCode ?? "";
            setState(() {
              _locationName = "$city, $country";
            });
          }
        } catch (_) {
          setState(() {
            _locationName = "Unknown Location";
          });
        }
      }

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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: kBgBottom,
        body: const Center(
          child: CircularProgressIndicator(color: kAccentYellow),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: kBgBottom,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: kTextWhite),
            onPressed: () => Navigator.pop(context),
          ),
        ),
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
                  child: const Text("Coba Lagi"),
                )
              ],
            ),
          ),
        ),
      );
    }

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
          title: Text(
            _locationName,
            style: const TextStyle(color: kTextWhite, fontWeight: FontWeight.w500),
          ),
          actions: [
            IconButton(
              onPressed: _toggleBookmark,
              icon: Icon(
                _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: kAccentYellow,
                size: 28,
              ),
            ),
            const SizedBox(width: 8),
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


  Widget _buildHeaderSection() {
    final current = _weather!.current;
    
    final displayTemp = TempConverter.convert(value: current.temp, from: "c", to: _selectedUnit).round();
    final feelsTemp = TempConverter.convert(value: current.feelsLike, from: "c", to: _selectedUnit).round();
    final maxTemp = TempConverter.convert(value: _weather!.daily.tempMax[0], from: "c", to: _selectedUnit).round();
    final minTemp = TempConverter.convert(value: _weather!.daily.tempMin[0], from: "c", to: _selectedUnit).round();

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
                "$displayTemp",
                style: const TextStyle(color: kTextWhite, fontSize: 80, fontWeight: FontWeight.w300, height: 1),
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
                    "Feels like $feelsTemp°",
                    textAlign: TextAlign.end,
                    style: const TextStyle(color: kTextGrey, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          Text(
            "High: $maxTemp° • Low: $minTemp°",
            style: const TextStyle(color: kTextGrey, fontSize: 16),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHourlyForecastCard() {
    final hourly = _weather!.hourly;
    int currentHour = DateTime.now().hour;
    int count = 24;
    if (currentHour + count > hourly.time.length) count = hourly.time.length - currentHour;

    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Hourly forecast", style: TextStyle(color: kTextWhite, fontSize: 16)),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(count, (i) {
                int index = currentHour + i;
                bool isNow = i == 0;
                int temp = TempConverter.convert(value: hourly.temperature[index], from: "c", to: _selectedUnit).round();
                return _buildHourlyItem(
                  time: isNow ? "Now" : WeatherUtils.formatTime(hourly.time[index]),
                  temp: temp,
                  precip: hourly.precipitation[index].round(),
                  icon: hourly.precipitation[index] > 50 ? Icons.umbrella : Icons.cloud_queue,
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
          const Text("7-day forecast", style: TextStyle(color: kTextWhite, fontSize: 16)),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: daily.time.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.white12),
            itemBuilder: (context, index) {
              int max = TempConverter.convert(value: daily.tempMax[index], from: "c", to: _selectedUnit).round();
              int min = TempConverter.convert(value: daily.tempMin[index], from: "c", to: _selectedUnit).round();
              return _buildDailyItem(
                day: index == 0 ? "Today" : WeatherUtils.formatDate(daily.time[index]),
                icon: daily.tempMax[index] > 30 ? Icons.sunny : Icons.cloud,
                max: max, min: min,
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
    double iconSize = 50.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
        children: [
          _buildConditionCard(title: "Wind", value: current.windSpeed.toString(), unit: "km/h", subtitle: "Direction: ${current.windDirection}°", visualContent: Transform.rotate(angle: current.windDirection * (3.14 / 180), child: Icon(Icons.navigation, color: kTextWhite, size: iconSize))),
          _buildConditionCard(title: "Humidity", value: current.humidity.toString(), unit: "%", subtitle: "Dew point -", visualContent: Icon(Icons.water_drop, color: kAccentBlue, size: iconSize)),
          _buildConditionCard(title: "AQI (US)", value: aqi.round().toString(), unit: "", subtitle: aqi < 51 ? "Good" : (aqi < 101 ? "Moderate" : "Unhealthy"), visualContent: Icon(Icons.grain, color: aqi < 51 ? Colors.green : (aqi < 101 ? kAccentYellow : Colors.redAccent), size: iconSize)),
          _buildConditionCard(title: "Pressure", value: current.pressure.round().toString(), unit: "hPa", subtitle: "Surface", visualContent: Icon(Icons.speed, color: kAccentBlue, size: iconSize)),
        ],
      ),
    );
  }

  Widget _buildSunriseSunsetCard() {
    if (_weather == null || _weather!.daily.sunrise.isEmpty || _weather!.daily.sunset.isEmpty) return const SizedBox();
    final DateTime sunriseTime = DateTime.parse(_weather!.daily.sunrise[0]);
    final DateTime sunsetTime = DateTime.parse(_weather!.daily.sunset[0]);
    final DateTime now = DateTime.now();
    double alignX = -1.0;
    if (now.isAfter(sunriseTime) && now.isBefore(sunsetTime)) {
      int totalDayMinutes = sunsetTime.difference(sunriseTime).inMinutes;
      int passedMinutes = now.difference(sunriseTime).inMinutes;
      double progress = passedMinutes / totalDayMinutes;
      alignX = (progress * 2) - 1;
    } else if (now.isAfter(sunsetTime)) alignX = 1.0;

    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Sunrise & sunset", style: TextStyle(color: kTextWhite, fontSize: 16)),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Sunrise", style: TextStyle(color: kTextGrey, fontSize: 12)), const SizedBox(height: 4), Text(WeatherUtils.formatTime(_weather!.daily.sunrise[0]), style: const TextStyle(color: kTextWhite, fontSize: 20, fontWeight: FontWeight.w600))]),
              Expanded(child: Container(height: 60, margin: const EdgeInsets.symmetric(horizontal: 12), child: Stack(alignment: Alignment.bottomCenter, children: [Container(height: 1, color: Colors.white24), Align(alignment: Alignment(alignX, 1.0), child: Padding(padding: const EdgeInsets.only(bottom: 4.0), child: Icon(Icons.wb_sunny_outlined, color: kAccentYellow, size: 32, shadows: [BoxShadow(color: kAccentYellow.withOpacity(0.6), blurRadius: 10, spreadRadius: 2)])))]))),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [const Text("Sunset", style: TextStyle(color: kTextGrey, fontSize: 12)), const SizedBox(height: 4), Text(WeatherUtils.formatTime(_weather!.daily.sunset[0]), style: const TextStyle(color: kTextWhite, fontSize: 20, fontWeight: FontWeight.w600))]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyDetailsCard() {
    final hourly = _weather!.hourly;
    int currentHour = DateTime.now().hour;
    
    List<double> dataToShow;
    String unit;
    String highLabel;
    IconData visualIcon;

    switch (_selectedDetailType) {
      case 'Humidity':
        dataToShow = hourly.humidity;
        unit = "%";
        highLabel = "Avg Humidity";
        visualIcon = Icons.water_drop;
        break;
      case 'Precipitation':
        dataToShow = hourly.precipitation;
        unit = "%";
        highLabel = "Chance of rain";
        visualIcon = Icons.umbrella;
        break;
      case 'Wind':
      default:
        dataToShow = hourly.windSpeed;
        unit = "km/h";
        highLabel = "Max Wind";
        visualIcon = Icons.navigation;
        break;
    }

    int count = 24;
    double maxVal = 0;
    if (currentHour + count <= hourly.time.length) {
        for(int i=0; i<count; i++) {
            if(dataToShow[currentHour+i] > maxVal) maxVal = dataToShow[currentHour+i];
        }
    }

    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Hourly details", style: TextStyle(color: kTextWhite, fontSize: 16)),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDetailTab("Precipitation", Icons.umbrella_outlined),
                const SizedBox(width: 8),
                _buildDetailTab("Wind", Icons.air),
                const SizedBox(width: 8),
                _buildDetailTab("Humidity", Icons.water_drop_outlined),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text("Today's $_selectedDetailType", style: const TextStyle(color: kTextGrey, fontSize: 14)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text("${maxVal.round()}", style: const TextStyle(color: kTextWhite, fontSize: 42, fontWeight: FontWeight.w300)),
              const SizedBox(width: 8),
              Text(unit, style: const TextStyle(color: kTextGrey, fontSize: 16)),
              const SizedBox(width: 8),
              Text("• $highLabel", style: const TextStyle(color: kTextGrey, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: count,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, i) {
                int index = currentHour + i;
                bool isNow = i == 0;
                double val = dataToShow.length > index ? dataToShow[index] : 0.0;

                return Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _selectedDetailType == 'Wind' 
                        ? Transform.rotate(
                            angle: (i * 45) * (math.pi / 180), 
                            child: Icon(visualIcon, color: kTextWhite, size: 28)
                          )
                        : Icon(visualIcon, color: kAccentBlue, size: 28),
                      const SizedBox(height: 12),
                      Text("${val.round()}", style: const TextStyle(color: kTextWhite, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        isNow ? "Now" : WeatherUtils.formatTime(hourly.time[index]),
                        style: TextStyle(color: isNow ? kTextWhite : kTextGrey, fontSize: 12, fontWeight: isNow ? FontWeight.bold : FontWeight.normal),
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDetailTab(String type, IconData icon) {
    bool isSelected = _selectedDetailType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedDetailType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A5E78) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Icon(icon, color: kTextWhite, size: 18),
            const SizedBox(width: 8),
            Text(type, style: const TextStyle(color: kTextWhite, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(24)),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(title, style: const TextStyle(color: kTextWhite, fontSize: 18, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildHourlyItem({required String time, required int temp, required int precip, required IconData icon, bool isActive = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 24.0),
      child: Column(
        children: [
          Text(time, style: TextStyle(color: isActive ? kTextWhite : kTextGrey, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
          const SizedBox(height: 8),
          Text("$precip%", style: const TextStyle(color: kAccentBlue, fontSize: 12)),
          const SizedBox(height: 8),
          Icon(icon, color: isActive ? kTextWhite : kTextGrey, size: 28),
          const SizedBox(height: 8),
          Text("$temp°", style: const TextStyle(color: kTextWhite, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildDailyItem({required String day, required int max, required int min, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(day, style: const TextStyle(color: kTextWhite, fontSize: 16))),
          Icon(icon, color: kTextGrey, size: 24),
          Expanded(flex: 1, child: Text("$max°/$min°", textAlign: TextAlign.end, style: const TextStyle(color: kTextWhite, fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildConditionCard({required String title, required String value, required String unit, required String subtitle, required Widget visualContent}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: kTextWhite, fontSize: 14)),
          Expanded(child: Center(child: visualContent)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(color: kTextWhite, fontSize: 24, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              Text(unit, style: const TextStyle(color: kTextGrey, fontSize: 12)),
            ],
          ),
          Text(subtitle, style: const TextStyle(color: kTextGrey, fontSize: 10)),
        ],
      ),
    );
  }
}