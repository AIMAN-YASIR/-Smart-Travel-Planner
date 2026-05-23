// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message_model.dart';
import '../utils/constants.dart';

class WeatherService {
  static const _baseUrl = '';

  Future<WeatherModel?> getCurrentWeather(String city) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/weather?q=${Uri.encodeComponent(city)}&appid=${ApiKeys.openWeatherMap}&units=metric',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return WeatherModel.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<WeatherModel>> getForecast(String city) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/forecast?q=${Uri.encodeComponent(city)}&appid=${ApiKeys.openWeatherMap}&units=metric&cnt=40',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = (data['list'] as List)
            .map((item) => WeatherModel.fromJson(item as Map<String, dynamic>))
            .toList();

        // Get one forecast per day (at noon)
        final Map<String, WeatherModel> dailyForecast = {};
        for (final w in list) {
          final key = '${w.date.year}-${w.date.month}-${w.date.day}';
          if (!dailyForecast.containsKey(key) || w.date.hour == 12) {
            dailyForecast[key] = w;
          }
        }

        return dailyForecast.values.toList()
          ..sort((a, b) => a.date.compareTo(b.date));
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

class PlacesService {
  // Using GeoDB Cities API via RapidAPI
  static const _geoDbBaseUrl = '';

  Future<List<CityModel>> searchCities(String query) async {
    try {
      if (query.trim().length < 2) return [];

      final uri = Uri.parse(
        '$_geoDbBaseUrl/cities?namePrefix=${Uri.encodeComponent(query)}&limit=10&sort=-population',
      );

      final response = await http.get(uri, headers: {
        'X-RapidAPI-Key': ApiKeys.geoDb,
        'X-RapidAPI-Host': 'wft-geo-db.p.rapidapi.com',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final cities = (data['data'] as List)
            .map((item) => CityModel.fromJson(item as Map<String, dynamic>))
            .toList();
        return cities;
      }
      return [];
    } catch (e) {
      return _getFallbackCities(query);
    }
  }

  // Fallback with popular cities if API key is not set
  List<CityModel> _getFallbackCities(String query) {
    final popularCities = [
      {
        'id': 1,
        'city': 'Dubai',
        'country': 'United Arab Emirates',
        'countryCode': 'AE',
        'population': 3331000
      },
      {
        'id': 2,
        'city': 'London',
        'country': 'United Kingdom',
        'countryCode': 'GB',
        'population': 8982000
      },
      {
        'id': 3,
        'city': 'Paris',
        'country': 'France',
        'countryCode': 'FR',
        'population': 2161000
      },
      {
        'id': 4,
        'city': 'New York City',
        'country': 'United States',
        'countryCode': 'US',
        'population': 8336000
      },
      {
        'id': 5,
        'city': 'Tokyo',
        'country': 'Japan',
        'countryCode': 'JP',
        'population': 13960000
      },
      {
        'id': 6,
        'city': 'Singapore',
        'country': 'Singapore',
        'countryCode': 'SG',
        'population': 5686000
      },
      {
        'id': 7,
        'city': 'Istanbul',
        'country': 'Turkey',
        'countryCode': 'TR',
        'population': 15462000
      },
      {
        'id': 8,
        'city': 'Bangkok',
        'country': 'Thailand',
        'countryCode': 'TH',
        'population': 10156000
      },
      {
        'id': 9,
        'city': 'Rome',
        'country': 'Italy',
        'countryCode': 'IT',
        'population': 2873000
      },
      {
        'id': 10,
        'city': 'Barcelona',
        'country': 'Spain',
        'countryCode': 'ES',
        'population': 1621000
      },
      {
        'id': 11,
        'city': 'Karachi',
        'country': 'Pakistan',
        'countryCode': 'PK',
        'population': 16093786
      },
      {
        'id': 12,
        'city': 'Lahore',
        'country': 'Pakistan',
        'countryCode': 'PK',
        'population': 13095000
      },
      {
        'id': 13,
        'city': 'Islamabad',
        'country': 'Pakistan',
        'countryCode': 'PK',
        'population': 1014000
      },
      {
        'id': 14,
        'city': 'Bali',
        'country': 'Indonesia',
        'countryCode': 'ID',
        'population': 4225000
      },
      {
        'id': 15,
        'city': 'Amsterdam',
        'country': 'Netherlands',
        'countryCode': 'NL',
        'population': 872680
      },
    ];

    final lower = query.toLowerCase();
    return popularCities
        .where((c) =>
            c['city'].toString().toLowerCase().contains(lower) ||
            c['country'].toString().toLowerCase().contains(lower))
        .map((c) => CityModel.fromJson(c))
        .toList();
  }
}
