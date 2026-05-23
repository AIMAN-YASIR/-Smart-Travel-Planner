// lib/screens/weather/weather_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/message_model.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../widgets/common_widgets.dart';

class WeatherScreen extends StatefulWidget {
  final String? destinationOverride;
  const WeatherScreen({super.key, this.destinationOverride});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final _searchCtrl = TextEditingController();
  final _weatherService = WeatherService();

  WeatherModel? _current;
  List<WeatherModel> _forecast = [];
  bool _isLoading = false;
  String? _error;
  String _searchedCity = '';

  @override
  void initState() {
    super.initState();
    if (widget.destinationOverride != null) {
      _searchCtrl.text = widget.destinationOverride!;
      _fetchWeather(widget.destinationOverride!);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchWeather(String city) async {
    if (city.trim().isEmpty) return;
    setState(() { _isLoading = true; _error = null; _searchedCity = city.trim(); });

    try {
      final results = await Future.wait([
        _weatherService.getCurrentWeather(city.trim()),
        _weatherService.getForecast(city.trim()),
      ]);

      final current = results[0] as WeatherModel?;
      final forecast = results[1] as List<WeatherModel>;

      if (current == null) {
        setState(() {
          _error = 'City not found. Check API key or city name.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _current = current;
        _forecast = forecast;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch weather. Check your connection.';
        _isLoading = false;
      });
    }
  }

  String _getWeatherEmoji(String description) {
    final d = description.toLowerCase();
    if (d.contains('clear') || d.contains('sunny')) return '☀️';
    if (d.contains('cloud')) return '☁️';
    if (d.contains('rain') || d.contains('drizzle')) return '🌧️';
    if (d.contains('thunder') || d.contains('storm')) return '⛈️';
    if (d.contains('snow')) return '❄️';
    if (d.contains('mist') || d.contains('fog') || d.contains('haze')) return '🌫️';
    if (d.contains('wind')) return '💨';
    return '🌤️';
  }

  Color _getTempColor(double temp) {
    if (temp >= 35) return const Color(0xFFD32F2F);
    if (temp >= 25) return const Color(0xFFFF6D00);
    if (temp >= 15) return const Color(0xFF1A73E8);
    if (temp >= 5) return const Color(0xFF0288D1);
    return const Color(0xFF7B1FA2);
  }

  @override
  Widget build(BuildContext context) {
    final isEmbedded = widget.destinationOverride != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isEmbedded
          ? null
          : AppBar(
        title: const Text('Weather'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _buildSearchBar(),
          ),
        ),
      ),
      body: Column(
        children: [
          if (isEmbedded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: _buildSearchBar(),
            ),
          Expanded(
            child: _isLoading
                ? const LoadingWidget(message: 'Fetching weather...')
                : _error != null
                ? ErrorWidget2(
              message: _error!,
              onRetry: () => _fetchWeather(_searchCtrl.text),
            )
                : _current == null
                ? _buildEmptyState()
                : _buildWeatherContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchCtrl,
      onSubmitted: _fetchWeather,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search city for weather...',
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        suffixIcon: IconButton(
          icon: const Icon(Icons.wb_sunny_outlined, color: AppColors.primary),
          onPressed: () => _fetchWeather(_searchCtrl.text),
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      emoji: '🌤️',
      title: 'Check Weather',
      subtitle: 'Search for any city to see current weather and 5-day forecast',
      action: ElevatedButton.icon(
        onPressed: () => _fetchWeather('Dubai'),
        icon: const Icon(Icons.location_city, size: 16),
        label: const Text('Try Dubai'),
      ),
    );
  }

  Widget _buildWeatherContent() {
    final w = _current!;
    final tempColor = _getTempColor(w.temperature);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Current weather card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [tempColor, tempColor.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: tempColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _searchedCity,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormat('EEEE, MMM d').format(DateTime.now()),
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                      ),
                    ],
                  ),
                  Text(_getWeatherEmoji(w.description), style: const TextStyle(fontSize: 50)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${w.temperature.round()}°C',
                        style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w200),
                      ),
                      Text(
                        w.description.toUpperCase(),
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, letterSpacing: 1),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _WeatherStat(icon: Icons.thermostat, label: 'Feels like', value: '${w.feelsLike.round()}°C'),
                      const SizedBox(height: 8),
                      _WeatherStat(icon: Icons.water_drop_outlined, label: 'Humidity', value: '${w.humidity}%'),
                      const SizedBox(height: 8),
                      _WeatherStat(icon: Icons.air, label: 'Wind', value: '${w.windSpeed.round()} m/s'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Low: ${w.tempMin.round()}°C', style: const TextStyle(color: Colors.white, fontSize: 13)),
                    Container(width: 1, height: 14, color: Colors.white.withOpacity(0.4)),
                    Text('High: ${w.tempMax.round()}°C', style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 5-day forecast
        if (_forecast.isNotEmpty) ...[
          const Text('📅 5-Day Forecast', style: AppTextStyles.headline3),
          const SizedBox(height: 12),
          ..._forecast.take(5).map((fw) => _ForecastTile(
            weather: fw,
            emoji: _getWeatherEmoji(fw.description),
            tempColor: _getTempColor(fw.temperature),
          )),
        ],

        const SizedBox(height: 80),
      ],
    );
  }
}

class _WeatherStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WeatherStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ForecastTile extends StatelessWidget {
  final WeatherModel weather;
  final String emoji;
  final Color tempColor;

  const _ForecastTile({required this.weather, required this.emoji, required this.tempColor});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(
                DateFormat('EEE, MMM d').format(weather.date),
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                weather.description,
                style: AppTextStyles.bodySecondary,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: tempColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${weather.temperature.round()}°C',
                style: TextStyle(color: tempColor, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}