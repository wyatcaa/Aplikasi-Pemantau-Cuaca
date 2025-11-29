class WeatherModel {
  final CurrentWeather current;
  final HourlyWeather hourly;
  final DailyWeather daily;
  final AirQuality? airQuality; 
  WeatherModel({
    required this.current,
    required this.hourly,
    required this.daily,
    this.airQuality,
  });

  factory WeatherModel.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? aqiJson,
  }) {
    return WeatherModel(
      current: CurrentWeather.fromJson(json['current'] ?? {}),
      hourly: HourlyWeather.fromJson(json['hourly'] ?? {}),
      daily: DailyWeather.fromJson(json['daily'] ?? {}),
      airQuality: aqiJson != null ? AirQuality.fromJson(aqiJson) : null,
    );
  }
}

class CurrentWeather {
  final double temp;
  final double feelsLike;
  final double windSpeed;
  final int windDirection;
  final int humidity;
  final double pressure;
  final double? uvIndex;
  final double rain;

  CurrentWeather({
    required this.temp,
    required this.feelsLike,
    required this.windSpeed,
    required this.windDirection,
    required this.humidity,
    required this.pressure,
    this.uvIndex,
    required this.rain,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      temp: (json['temperature_2m'] ?? 0).toDouble(),
      feelsLike: (json['apparent_temperature'] ?? 0).toDouble(),
      windSpeed: (json['wind_speed_10m'] ?? 0).toDouble(),
      windDirection: json['wind_direction_10m'] ?? 0,
      humidity: json['relative_humidity_2m'] ?? 0,
      pressure: (json['surface_pressure'] ?? 0).toDouble(),
      rain: (json['precipitation'] ?? 0).toDouble(),
    );
  }
}

class HourlyWeather {
  final List<String> time;
  final List<double> temperature;
  final List<double> precipitation;

  HourlyWeather({
    required this.time,
    required this.temperature,
    required this.precipitation,
  });

  factory HourlyWeather.fromJson(Map<String, dynamic> json) {
    return HourlyWeather(
      time: List<String>.from(json['time'] ?? []),
      temperature: List<double>.from(
        json['temperature_2m']?.map((x) => x?.toDouble() ?? 0.0) ?? [],
      ),
      precipitation: List<double>.from(
        json['precipitation_probability']?.map((x) => x?.toDouble() ?? 0.0) ??
            [],
      ),
    );
  }
}

class DailyWeather {
  final List<String> time;
  final List<String> sunrise;
  final List<String> sunset;
  final List<double> tempMax;
  final List<double> tempMin;

  DailyWeather({
    required this.time,
    required this.sunrise,
    required this.sunset,
    required this.tempMax,
    required this.tempMin,
  });

  factory DailyWeather.fromJson(Map<String, dynamic> json) {
    return DailyWeather(
      time: List<String>.from(json['time'] ?? []),
      sunrise: List<String>.from(json['sunrise'] ?? []),
      sunset: List<String>.from(json['sunset'] ?? []),
      tempMax: List<double>.from(
        json['temperature_2m_max']?.map((x) => x?.toDouble() ?? 0.0) ?? [],
      ),
      tempMin: List<double>.from(
        json['temperature_2m_min']?.map((x) => x?.toDouble() ?? 0.0) ?? [],
      ),
    );
  }
}

class AirQuality {
  final double usAqi;

  AirQuality({required this.usAqi});

  factory AirQuality.fromJson(Map<String, dynamic> json) {
    final current = json['current'] ?? {};
    return AirQuality(usAqi: (current['us_aqi'] ?? 0).toDouble());
  }
}
