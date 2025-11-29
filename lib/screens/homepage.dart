// import 'package:flutter/material.dart';
// import 'package:meteo/helpers/temp_converter.dart';
// import 'package:meteo/models/weather_model.dart';
// import 'package:meteo/services/apiservices.dart';
// import 'package:meteo/helpers/weather_helper.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:meteo/services/dbservices.dart';
// import 'package:meteo/models/user_model.dart';
// import 'package:meteo/services/notification_service.dart';

// // --- PALET WARNA ---
// const Color kBgTop = Color(0xFF6BAAFC);
// const Color kBgBottom = Color(0xFF3F82E8);
// const Color kCardBg = Color(0x25FFFFFF);
// const Color kTextWhite = Colors.white;
// const Color kTextGrey = Color(0xFFD4E4FF);
// const Color kAccentBlue = Color(0xFFB3D4FF);
// const Color kAccentYellow = Color(0xFFFFD56F);

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   WeatherModel? _weather;
//   bool _isLoading = true;
//   String _errorMessage = '';
//   String _locationName = "Detecting Location...";
  
//   UserModel? user;
//   String _selectedUnit = "c"; 

//   final WeatherService _weatherService = WeatherService();
//   final NotificationService _notifService = NotificationService();

//   @override
//   void initState() {
//     super.initState();
//     _initNotification(); // Init Notifikasi
//     _loadUserUnit();     // Load Unit Suhu User
//     _loadWeatherData();  // Load Data Cuaca
//   }

//   // --- 1. Init Notifikasi ---
//   Future<void> _initNotification() async {
//     await _notifService.init();
//   }

//   // --- 2. Load Unit Suhu User (C/F) ---
//   Future<void> _loadUserUnit() async {
//     try {
//       user = await DBService().getUser();
//       if (user != null) {
//         setState(() {
//           _selectedUnit = user!.tempUnit;
//         });
//       }
//     } catch (e) {
//       print("Gagal load user unit: $e");
//     }
//   }

//   // --- 3. Ambil Lokasi GPS ---
//   Future<Position> _determinePosition() async {
//     bool serviceEnabled;
//     LocationPermission permission;

//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       return Future.error('Location services are disabled.');
//     }

//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         return Future.error('Location permissions are denied');
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       return Future.error('Location permissions are permanently denied.');
//     }

//     return await Geolocator.getCurrentPosition();
//   }

//   // --- 4. Load Data Cuaca & Trigger Notif ---
//   Future<void> _loadWeatherData() async {
//     try {
//       // A. Ambil Posisi
//       Position position = await _determinePosition();

//       // B. Reverse Geocoding (LatLon -> Nama Kota)
//       try {
//         List<Placemark> placemarks = await placemarkFromCoordinates(
//           position.latitude,
//           position.longitude,
//         );

//         if (placemarks.isNotEmpty) {
//           Placemark place = placemarks[0];
//           String city = place.locality ?? place.subAdministrativeArea ?? "Unknown";
//           String country = place.isoCountryCode ?? "";
//           setState(() {
//             _locationName = "$city, $country";
//           });
//         }
//       } catch (e) {
//         setState(() {
//           _locationName = "My Location";
//         });
//       }

//       // C. Ambil Data API
//       final data = await _weatherService.getWeatherFull(
//         position.latitude,
//         position.longitude,
//       );

//       setState(() {
//         _weather = data;
//         _isLoading = false;
//       });

//       // D. Cek Kondisi untuk Notifikasi
//       _analyzeWeatherAndNotify(data);

//     } catch (e) {
//       setState(() {
//         _errorMessage = e.toString();
//         _isLoading = false;
//       });
//     }
//   }

//   // --- LOGIKA NOTIFIKASI PINTAR ---
//   void _analyzeWeatherAndNotify(WeatherModel data) {
//     bool isRaining = false;

//     // 1. Cek Hujan (Prioritas Utama)
//     if (data.current.rain > 0.0) {
//       isRaining = true;
//     } else {
//       // Cek prediksi 1 jam ke depan
//       int currentHour = DateTime.now().hour;
//       if (currentHour + 1 < data.hourly.time.length) {
//          if (data.hourly.precipitation[currentHour + 1] > 50.0) {
//            isRaining = true;
//          }
//       }
//     }

//     if (isRaining) {
//       _notifService.showNotification(
//         id: 1,
//         title: "🌧️ Sedia Payung!",
//         body: "Terdeteksi hujan atau potensi hujan tinggi. Siapkan payung ya!",
//       );
//       return; 
//     }

//     // 2. Cek Sunscreen (Jika Siang & Panas)
//     double currentTemp = data.current.temp;
//     int jamSekarang = DateTime.now().hour;
//     bool isSiang = jamSekarang >= 6 && jamSekarang < 18;

//     if (isSiang && currentTemp > 21.0) {
//       _notifService.showNotification(
//         id: 2,
//         title: "☀️ Cuaca Cerah!",
//         body: "Suhu ${currentTemp.round()}°C. Jangan lupa pakai Sunscreen!",
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Tampilan Loading
//     if (_isLoading) {
//       return Scaffold(
//         backgroundColor: kBgBottom,
//         body: const Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               CircularProgressIndicator(color: kAccentYellow),
//               SizedBox(height: 16),
//               Text("Getting location & weather...", style: TextStyle(color: Colors.white)),
//             ],
//           ),
//         ),
//       );
//     }

//     // Tampilan Error
//     if (_errorMessage.isNotEmpty) {
//       return Scaffold(
//         backgroundColor: kBgBottom,
//         body: Center(
//           child: Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Icon(Icons.error_outline, color: Colors.white, size: 50),
//                 const SizedBox(height: 16),
//                 Text(
//                   _errorMessage,
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(color: Colors.white),
//                 ),
//                 const SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: () {
//                     setState(() {
//                       _isLoading = true;
//                       _errorMessage = '';
//                     });
//                     _loadWeatherData();
//                   },
//                   child: const Text("Try Again"),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }

//     // --- TAMPILAN UTAMA ---
//     return Container(
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [kBgTop, kBgBottom],
//         ),
//       ),
//       child: Scaffold(
//         backgroundColor: Colors.transparent,
//         appBar: AppBar(
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           leading: const Icon(Icons.location_on_outlined, color: kTextWhite),
//           title: Text(
//             _locationName,
//             style: const TextStyle(
//               color: kTextWhite,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ),
//         body: SingleChildScrollView(
//           physics: const BouncingScrollPhysics(),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildHeaderSection(),
//               _buildHourlyForecastCard(),
//               _buildWeeklyForecastCard(),
//               _buildSectionTitle("Current conditions"),
//               _buildCurrentConditionsGrid(),
//               _buildSunriseSunsetCard(),
//               _buildSectionTitle("Hourly details"),
//               _buildHourlyDetailsCard(),
//               const SizedBox(height: 30),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ================= WIDGET SECTIONS =================

//   Widget _buildHeaderSection() {
//     final current = _weather!.current;
    
//     // Konversi Suhu
//     final displayTemp = TempConverter.convert(value: current.temp, from: "c", to: _selectedUnit).round();
//     final feelsTemp = TempConverter.convert(value: current.feelsLike, from: "c", to: _selectedUnit).round();
//     final maxTemp = TempConverter.convert(value: _weather!.daily.tempMax[0], from: "c", to: _selectedUnit).round();
//     final minTemp = TempConverter.convert(value: _weather!.daily.tempMin[0], from: "c", to: _selectedUnit).round();

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text("Now", style: TextStyle(color: kTextGrey, fontSize: 16)),
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "$displayTemp",
//                 style: const TextStyle(color: kTextWhite, fontSize: 80, fontWeight: FontWeight.w300, height: 1),
//               ),
//               const Text(
//                 "°",
//                 style: TextStyle(color: kTextWhite, fontSize: 40, height: 1),
//               ),
//               const Spacer(),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   const Icon(Icons.cloud, color: kAccentYellow, size: 40),
//                   const SizedBox(height: 8),
//                   Text(
//                     "Feels like $feelsTemp°",
//                     textAlign: TextAlign.end,
//                     style: const TextStyle(color: kTextGrey, fontSize: 14),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           Text(
//             "High: $maxTemp° • Low: $minTemp°",
//             style: const TextStyle(color: kTextGrey, fontSize: 16),
//           ),
//           const SizedBox(height: 20),
//         ],
//       ),
//     );
//   }

//   Widget _buildHourlyForecastCard() {
//     final hourly = _weather!.hourly;
//     int currentHour = DateTime.now().hour;
//     int count = 24;
//     if (currentHour + count > hourly.time.length) {
//       count = hourly.time.length - currentHour;
//     }

//     return _buildCardContainer(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text("Hourly forecast", style: TextStyle(color: kTextWhite, fontSize: 16)),
//           const SizedBox(height: 16),
//           SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: Row(
//               children: List.generate(count, (i) {
//                 int index = currentHour + i;
//                 bool isNow = i == 0;
                
//                 // Konversi Suhu per Jam
//                 int temp = TempConverter.convert(
//                   value: hourly.temperature[index], 
//                   from: "c", 
//                   to: _selectedUnit
//                 ).round();

//                 return _buildHourlyItem(
//                   time: isNow ? "Now" : WeatherUtils.formatTime(hourly.time[index]),
//                   temp: temp,
//                   precip: hourly.precipitation[index].round(), // Ini Persen (%)
//                   icon: hourly.precipitation[index] > 50 ? Icons.umbrella : Icons.cloud_queue,
//                   isActive: isNow,
//                 );
//               }),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildWeeklyForecastCard() {
//     final daily = _weather!.daily;

//     return _buildCardContainer(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text("7-day forecast", style: TextStyle(color: kTextWhite, fontSize: 16)),
//           const SizedBox(height: 16),
//           ListView.separated(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: daily.time.length,
//             separatorBuilder: (_, __) => const Divider(color: Colors.white12),
//             itemBuilder: (context, index) {
//               // Konversi Suhu Harian
//               int max = TempConverter.convert(value: daily.tempMax[index], from: "c", to: _selectedUnit).round();
//               int min = TempConverter.convert(value: daily.tempMin[index], from: "c", to: _selectedUnit).round();

//               return _buildDailyItem(
//                 day: index == 0 ? "Today" : WeatherUtils.formatDate(daily.time[index]),
//                 icon: daily.tempMax[index] > 30 ? Icons.sunny : Icons.cloud,
//                 max: max,
//                 min: min,
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCurrentConditionsGrid() {
//     final current = _weather!.current;
//     final aqi = _weather!.airQuality?.usAqi ?? 0;
//     double iconSize = 50.0;

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0),
//       child: GridView.count(
//         physics: const NeverScrollableScrollPhysics(),
//         shrinkWrap: true,
//         crossAxisCount: 2,
//         crossAxisSpacing: 12,
//         mainAxisSpacing: 12,
//         childAspectRatio: 1.2,
//         children: [
//           _buildConditionCard(
//             title: "Wind",
//             value: current.windSpeed.toString(),
//             unit: "km/h",
//             subtitle: "Direction: ${current.windDirection}°",
//             visualContent: Transform.rotate(
//               angle: current.windDirection * (3.14 / 180),
//               child: Icon(Icons.navigation, color: kTextWhite, size: iconSize),
//             ),
//           ),
//           _buildConditionCard(
//             title: "Humidity",
//             value: current.humidity.toString(),
//             unit: "%",
//             subtitle: "Dew point -",
//             visualContent: Icon(Icons.water_drop, color: kAccentBlue, size: iconSize),
//           ),
//           _buildConditionCard(
//             title: "AQI (US)",
//             value: aqi.round().toString(),
//             unit: "",
//             subtitle: aqi < 50 ? "Good" : "Moderate",
//             visualContent: Icon(Icons.grain, color: aqi < 50 ? Colors.green : Colors.orange, size: iconSize),
//           ),
//           _buildConditionCard(
//             title: "Pressure",
//             value: current.pressure.round().toString(),
//             unit: "hPa",
//             subtitle: "Surface",
//             visualContent: Icon(Icons.speed, color: kAccentBlue, size: iconSize),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSunriseSunsetCard() {
//     if (_weather == null || _weather!.daily.sunrise.isEmpty || _weather!.daily.sunset.isEmpty) {
//       return const SizedBox();
//     }

//     final DateTime sunriseTime = DateTime.parse(_weather!.daily.sunrise[0]);
//     final DateTime sunsetTime = DateTime.parse(_weather!.daily.sunset[0]);
//     final DateTime now = DateTime.now();

//     double alignX = -1.0;
//     if (now.isAfter(sunriseTime) && now.isBefore(sunsetTime)) {
//       int totalDayMinutes = sunsetTime.difference(sunriseTime).inMinutes;
//       int passedMinutes = now.difference(sunriseTime).inMinutes;
//       double progress = passedMinutes / totalDayMinutes;
//       alignX = (progress * 2) - 1;
//     } else if (now.isAfter(sunsetTime)) {
//       alignX = 1.0;
//     }

//     return _buildCardContainer(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text("Sunrise & sunset", style: TextStyle(color: kTextWhite, fontSize: 16)),
//           const SizedBox(height: 24),
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text("Sunrise", style: TextStyle(color: kTextGrey, fontSize: 12)),
//                   const SizedBox(height: 4),
//                   Text(WeatherUtils.formatTime(_weather!.daily.sunrise[0]), style: const TextStyle(color: kTextWhite, fontSize: 20, fontWeight: FontWeight.w600)),
//                 ],
//               ),
//               Expanded(
//                 child: Container(
//                   height: 60,
//                   margin: const EdgeInsets.symmetric(horizontal: 12),
//                   child: Stack(
//                     alignment: Alignment.bottomCenter,
//                     children: [
//                       Container(height: 1, color: Colors.white24),
//                       Align(
//                         alignment: Alignment(alignX, 1.0),
//                         child: Padding(
//                           padding: const EdgeInsets.only(bottom: 4.0),
//                           child: Icon(Icons.wb_sunny_outlined, color: kAccentYellow, size: 32, shadows: [BoxShadow(color: kAccentYellow.withOpacity(0.6), blurRadius: 10, spreadRadius: 2)]),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   const Text("Sunset", style: TextStyle(color: kTextGrey, fontSize: 12)),
//                   const SizedBox(height: 4),
//                   Text(WeatherUtils.formatTime(_weather!.daily.sunset[0]), style: const TextStyle(color: kTextWhite, fontSize: 20, fontWeight: FontWeight.w600)),
//                 ],
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildHourlyDetailsCard() {
//     return _buildCardContainer(
//       child: const Text("Grafik Detail (Implementasi Chart)", style: TextStyle(color: Colors.white)),
//     );
//   }

//   // --- HELPER WIDGETS ---
//   Widget _buildCardContainer({required Widget child}) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//       padding: const EdgeInsets.all(20.0),
//       decoration: BoxDecoration(
//         color: kCardBg,
//         borderRadius: BorderRadius.circular(24),
//       ),
//       child: child,
//     );
//   }

//   Widget _buildSectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
//       child: Text(title, style: const TextStyle(color: kTextWhite, fontSize: 18, fontWeight: FontWeight.w500)),
//     );
//   }

//   Widget _buildHourlyItem({required String time, required int temp, required int precip, required IconData icon, bool isActive = false}) {
//     return Padding(
//       padding: const EdgeInsets.only(right: 24.0),
//       child: Column(
//         children: [
//           Text(time, style: TextStyle(color: isActive ? kTextWhite : kTextGrey, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
//           const SizedBox(height: 8),
//           Text("$precip%", style: const TextStyle(color: kAccentBlue, fontSize: 12)),
//           const SizedBox(height: 8),
//           Icon(icon, color: isActive ? kTextWhite : kTextGrey, size: 28),
//           const SizedBox(height: 8),
//           Text("$temp°", style: const TextStyle(color: kTextWhite, fontSize: 16, fontWeight: FontWeight.w500)),
//         ],
//       ),
//     );
//   }

//   Widget _buildDailyItem({required String day, required int max, required int min, required IconData icon}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 12.0),
//       child: Row(
//         children: [
//           Expanded(flex: 2, child: Text(day, style: const TextStyle(color: kTextWhite, fontSize: 16))),
//           Icon(icon, color: kTextGrey, size: 24),
//           Expanded(flex: 1, child: Text("$max°/$min°", textAlign: TextAlign.end, style: const TextStyle(color: kTextWhite, fontSize: 16))),
//         ],
//       ),
//     );
//   }

//   Widget _buildConditionCard({required String title, required String value, required String unit, required String subtitle, required Widget visualContent}) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(24)),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(title, style: const TextStyle(color: kTextWhite, fontSize: 14)),
//           Expanded(child: Center(child: visualContent)),
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.baseline,
//             textBaseline: TextBaseline.alphabetic,
//             children: [
//               Text(value, style: const TextStyle(color: kTextWhite, fontSize: 24, fontWeight: FontWeight.w600)),
//               const SizedBox(width: 4),
//               Text(unit, style: const TextStyle(color: kTextGrey, fontSize: 12)),
//             ],
//           ),
//           Text(subtitle, style: const TextStyle(color: kTextGrey, fontSize: 10)),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:meteo/helpers/temp_converter.dart';
import 'package:meteo/models/weather_model.dart';
import 'package:meteo/services/apiservices.dart';
import 'package:meteo/helpers/weather_helper.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:meteo/services/dbservices.dart';
import 'package:meteo/models/user_model.dart';
import 'package:meteo/services/notification_service.dart';

const Color kBgTop = Color(0xFF6BAAFC);
const Color kBgBottom = Color(0xFF3F82E8);
const Color kCardBg = Color(0x25FFFFFF);
const Color kTextWhite = Colors.white;
const Color kTextGrey = Color(0xFFD4E4FF);
const Color kAccentBlue = Color(0xFFB3D4FF);
const Color kAccentYellow = Color(0xFFFFD56F);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  WeatherModel? _weather;
  bool _isLoading = true;
  String _errorMessage = '';
  String _locationName = "Detecting Location...";
  
  UserModel? user;
  String _selectedUnit = "c";

  final WeatherService _weatherService = WeatherService();
  final NotificationService _notifService = NotificationService();

  @override
  void initState() {
    super.initState();
    _initNotification();
    _loadUserUnit();
    _loadWeatherData();
  }

  Future<void> _initNotification() async {
    await _notifService.init();
  }

  Future<void> _loadUserUnit() async {
    try {
      user = await DBService().getUser();
      if (user != null && mounted) {
        setState(() {
          _selectedUnit = user!.tempUnit;
        });
      }
    } catch (e) {
      print("Gagal load user unit: $e");
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

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

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _loadWeatherData() async {
    try {
      Position position = await _determinePosition();

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String city = place.locality ?? place.subAdministrativeArea ?? "Unknown";
          String country = place.isoCountryCode ?? "";
          if (mounted) {
            setState(() {
              _locationName = "$city, $country";
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _locationName = "My Location";
          });
        }
      }

      final data = await _weatherService.getWeatherFull(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _weather = data;
          _isLoading = false;
        });

        _analyzeWeatherAndNotify(data);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _analyzeWeatherAndNotify(WeatherModel data) {
    bool isRaining = false;

    if (data.current.rain > 0.0) {
      isRaining = true;
    } else {
      int currentHour = DateTime.now().hour;
      if (currentHour + 1 < data.hourly.time.length) {
        if (data.hourly.precipitation[currentHour + 1] > 50.0) {
          isRaining = true;
        }
      }
    }

    if (isRaining) {
      _notifService.showNotification(
        id: 1,
        title: "🌧️ Sedia Payung!",
        body: "Terdeteksi hujan atau potensi hujan tinggi. Siapkan payung ya!",
      );
      return;
    }

    double currentTemp = data.current.temp;
    int jamSekarang = DateTime.now().hour;
    bool isSiang = jamSekarang >= 6 && jamSekarang < 18;

    if (isSiang && currentTemp > 21.0) {
      _notifService.showNotification(
        id: 2,
        title: "☀️ Cuaca Cerah!",
        body: "Suhu ${currentTemp.round()}°C. Jangan lupa pakai Sunscreen!",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: kBgBottom,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: kAccentYellow),
              SizedBox(height: 16),
              Text("Getting location & weather...", style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

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
                    if (mounted) {
                      setState(() {
                        _isLoading = true;
                        _errorMessage = '';
                      });
                      _loadWeatherData();
                    }
                  },
                  child: const Text("Try Again"),
                ),
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
          leading: const Icon(Icons.location_on_outlined, color: kTextWhite),
          title: Text(
            _locationName,
            style: const TextStyle(color: kTextWhite, fontWeight: FontWeight.w500),
          ),
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
              const Text("°", style: TextStyle(color: kTextWhite, fontSize: 40, height: 1)),
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
          Text("High: $maxTemp° • Low: $minTemp°", style: const TextStyle(color: kTextGrey, fontSize: 16)),
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
                max: max,
                min: min,
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
            visualContent: Icon(Icons.water_drop, color: kAccentBlue, size: iconSize),
          ),
          _buildConditionCard(
            title: "AQI (US)",
            value: aqi.round().toString(),
            unit: "",
            subtitle: aqi < 51 ? "Good" : (aqi < 101 ? "Moderate" : "Unhealthy"),
            visualContent: Icon(
              aqi < 51 ? Icons.mood_outlined : Icons.sick_outlined, 
              color: aqi < 51 ? Colors.greenAccent : (aqi < 101 ? kAccentYellow : Colors.redAccent), 
              size: iconSize
            ),
          ),
          _buildConditionCard(
            title: "Pressure",
            value: current.pressure.round().toString(),
            unit: "hPa",
            subtitle: "Surface",
            visualContent: Icon(Icons.speed, color: kAccentBlue, size: iconSize),
          ),
        ],
      ),
    );
  }

  Widget _buildSunriseSunsetCard() {
    if (_weather == null || _weather!.daily.sunrise.isEmpty || _weather!.daily.sunset.isEmpty) {
      return const SizedBox();
    }

    final DateTime sunriseTime = DateTime.parse(_weather!.daily.sunrise[0]);
    final DateTime sunsetTime = DateTime.parse(_weather!.daily.sunset[0]);
    final DateTime now = DateTime.now();

    double alignX = -1.0;
    if (now.isAfter(sunriseTime) && now.isBefore(sunsetTime)) {
      int totalDayMinutes = sunsetTime.difference(sunriseTime).inMinutes;
      int passedMinutes = now.difference(sunriseTime).inMinutes;
      double progress = passedMinutes / totalDayMinutes;
      alignX = (progress * 2) - 1;
    } else if (now.isAfter(sunsetTime)) {
      alignX = 1.0;
    }

    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Sunrise & sunset", style: TextStyle(color: kTextWhite, fontSize: 16)),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Sunrise", style: TextStyle(color: kTextGrey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(WeatherUtils.formatTime(_weather!.daily.sunrise[0]), style: const TextStyle(color: kTextWhite, fontSize: 20, fontWeight: FontWeight.w600)),
                ],
              ),
              Expanded(
                child: Container(
                  height: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(height: 1, color: Colors.white24),
                      Align(
                        alignment: Alignment(alignX, 1.0),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Icon(Icons.wb_sunny_outlined, color: kAccentYellow, size: 32, shadows: [BoxShadow(color: kAccentYellow.withOpacity(0.6), blurRadius: 10, spreadRadius: 2)]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Sunset", style: TextStyle(color: kTextGrey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(WeatherUtils.formatTime(_weather!.daily.sunset[0]), style: const TextStyle(color: kTextWhite, fontSize: 20, fontWeight: FontWeight.w600)),
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
      child: const Text("Grafik Detail (Implementasi Chart)", style: TextStyle(color: Colors.white)),
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
