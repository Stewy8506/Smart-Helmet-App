import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherService {
  static Future<String> getCurrentWeather() async {
    try {
      final pos = await Geolocator.getLastKnownPosition();
      if (pos == null) {
        return "I couldn't determine your location for the weather.";
      }

      final url = Uri.parse("https://api.open-meteo.com/v1/forecast?latitude=${pos.latitude}&longitude=${pos.longitude}&current_weather=true");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current_weather'];
        final temp = current['temperature'];
        final weatherCode = current['weathercode'];

        final condition = _getWeatherCondition(weatherCode);

        return "It is currently $temp degrees and $condition.";
      } else {
        return "I am having trouble reaching the weather service.";
      }
    } catch (e) {
      return "I couldn't fetch the weather.";
    }
  }

  static String _getWeatherCondition(int code) {
    if (code == 0) return "clear skies";
    if (code >= 1 && code <= 3) return "partly cloudy";
    if (code == 45 || code == 48) return "foggy";
    if (code >= 51 && code <= 55) return "drizzling";
    if (code >= 61 && code <= 65) return "raining";
    if (code >= 71 && code <= 77) return "snowing";
    if (code >= 80 && code <= 82) return "pouring rain";
    if (code >= 95 && code <= 99) return "thunderstorms";
    return "cloudy";
  }
}
