import 'package:flutter/material.dart';

class WeatherUtils {
  // Menerjemahkan WMO Code ke Deskripsi String
  static String getWeatherDescription(int code) {
    switch (code) {
      case 0:
        return "Cerah";
      case 1:
      case 2:
      case 3:
        return "Berawan sebagian";
      case 45:
      case 48:
        return "Berkabut";
      case 51:
      case 53:
      case 55:
        return "Gerimis";
      case 61:
      case 63:
      case 65:
        return "Hujan";
      case 71:
      case 73:
      case 75:
        return "Salju";
      case 80:
      case 81:
      case 82:
        return "Hujan Lebat";
      case 95:
      case 96:
      case 99:
        return "Badai Petir";
      default:
        return "Tidak diketahui";
    }
  }

  // Menerjemahkan WMO Code ke Icon Flutter
  static IconData getWeatherIcon(int code) {
    switch (code) {
      case 0:
        return Icons.wb_sunny_outlined;
      case 1:
      case 2:
        return Icons.wb_cloudy_outlined;
      case 3:
        return Icons.cloud;
      case 45:
      case 48:
        return Icons.foggy; // Butuh icon khusus jika ada
      case 51:
      case 53:
      case 55:
        return Icons.grain;
      case 61:
      case 63:
      case 65:
        return Icons.water_drop;
      case 80:
      case 81:
      case 82:
        return Icons.beach_access; // Hujan deras
      case 95:
      case 96:
      case 99:
        return Icons.thunderstorm;
      default:
        return Icons.question_mark;
    }
  }

  // Format tanggal ISO (2023-11-21T14:00) jadi Jam (14:00)
  static String formatTime(String isoString) {
    try {
      DateTime dt = DateTime.parse(isoString);
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "-";
    }
  }

  // Format tanggal jadi Nama Hari (Senin, 21 Nov)
  static String formatDate(String isoString) {
    try {
      DateTime dt = DateTime.parse(isoString);
      // Manual mapping karena intl butuh locale setup yang ribet untuk demo singkat
      List<String> days = [
        "Senin",
        "Selasa",
        "Rabu",
        "Kamis",
        "Jumat",
        "Sabtu",
        "Minggu",
      ];
      List<String> months = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "Mei",
        "Jun",
        "Jul",
        "Agu",
        "Sep",
        "Okt",
        "Nov",
        "Des",
      ];
      return "${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]}";
    } catch (e) {
      return "-";
    }
  }
}
