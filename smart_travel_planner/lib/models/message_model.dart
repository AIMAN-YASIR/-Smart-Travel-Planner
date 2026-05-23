// lib/models/message_model.dart

class MessageModel {
  final String id;
  final String tripId;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String text;
  final DateTime timestamp;
  final MessageType type;

  MessageModel({
    required this.id,
    required this.tripId,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    required this.text,
    required this.timestamp,
    this.type = MessageType.text,
  });

  factory MessageModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return MessageModel(
      id: id,
      tripId: map['tripId']?.toString() ?? '',
      senderId: map['senderId']?.toString() ?? '',
      senderName: map['senderName']?.toString() ?? 'Unknown',
      senderEmail: map['senderEmail']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestamp'] as int?) ?? 0,
      ),
      type: MessageType.values.firstWhere(
            (e) => e.name == (map['type']?.toString() ?? 'text'),
        orElse: () => MessageType.text,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'senderId': senderId,
      'senderName': senderName,
      'senderEmail': senderEmail,
      'text': text,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': type.name,
    };
  }
}

enum MessageType { text, system }

// lib/models/weather_model.dart
class WeatherModel {
  final double temperature;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final String description;
  final String icon;
  final int humidity;
  final double windSpeed;
  final DateTime date;

  WeatherModel({
    required this.temperature,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    required this.date,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>;
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    final wind = json['wind'] as Map<String, dynamic>;

    return WeatherModel(
      temperature: (main['temp'] as num).toDouble(),
      feelsLike: (main['feels_like'] as num).toDouble(),
      tempMin: (main['temp_min'] as num).toDouble(),
      tempMax: (main['temp_max'] as num).toDouble(),
      description: weather['description'] ?? '',
      icon: weather['icon'] ?? '',
      humidity: (main['humidity'] as int?) ?? 0,
      windSpeed: (wind['speed'] as num).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(
        ((json['dt'] as int?) ?? 0) * 1000,
      ),
    );
  }

  String get iconUrl => 'https://openweathermap.org/img/wn/$icon@2x.png';

  String get tempDisplay => '${temperature.round()}°C';
}

// lib/models/city_model.dart
class CityModel {
  final int id;
  final String city;
  final String country;
  final String countryCode;
  final double? latitude;
  final double? longitude;
  final int? population;

  CityModel({
    required this.id,
    required this.city,
    required this.country,
    required this.countryCode,
    this.latitude,
    this.longitude,
    this.population,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'] as int,
      city: json['city']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      countryCode: json['countryCode']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      population: json['population'] as int?,
    );
  }

  String get displayName => '$city, $country';
}