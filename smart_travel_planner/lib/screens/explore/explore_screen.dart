// lib/screens/explore/explore_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/message_model.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../widgets/common_widgets.dart';
import '../trips/create_trip_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchCtrl = TextEditingController();
  final _placesService = PlacesService();

  List<CityModel> _cities = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _error;

  final List<Map<String, dynamic>> _popularDestinations = [
    {'name': 'Dubai', 'country': 'UAE', 'emoji': '🏙️', 'tag': 'Luxury', 'desc': 'Burj Khalifa, Shopping, Desert'},
    {'name': 'Paris', 'country': 'France', 'emoji': '🗼', 'tag': 'Romance', 'desc': 'Eiffel Tower, Louvre, Cafes'},
    {'name': 'Tokyo', 'country': 'Japan', 'emoji': '🎌', 'tag': 'Culture', 'desc': 'Shibuya, Sushi, Temples'},
    {'name': 'Bali', 'country': 'Indonesia', 'emoji': '🌴', 'tag': 'Beach', 'desc': 'Beaches, Temples, Rice Fields'},
    {'name': 'Istanbul', 'country': 'Turkey', 'emoji': '🕌', 'tag': 'History', 'desc': 'Hagia Sophia, Bazaars'},
    {'name': 'Singapore', 'country': 'Singapore', 'emoji': '🦁', 'tag': 'Modern', 'desc': 'Gardens, Marina Bay'},
    {'name': 'Rome', 'country': 'Italy', 'emoji': '🏛️', 'tag': 'Heritage', 'desc': 'Colosseum, Vatican, Pasta'},
    {'name': 'New York', 'country': 'USA', 'emoji': '🗽', 'tag': 'Urban', 'desc': 'Times Square, Central Park'},
    {'name': 'Bangkok', 'country': 'Thailand', 'emoji': '🛕', 'tag': 'Budget', 'desc': 'Temples, Street Food'},
    {'name': 'London', 'country': 'UK', 'emoji': '🎡', 'tag': 'Classic', 'desc': 'Big Ben, Museums, Tea'},
    {'name': 'Maldives', 'country': 'Maldives', 'emoji': '🏝️', 'tag': 'Luxury', 'desc': 'Overwater Bungalows'},
    {'name': 'Lahore', 'country': 'Pakistan', 'emoji': '🕌', 'tag': 'Heritage', 'desc': 'Badshahi Mosque, Food'},
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) return;
    setState(() { _isLoading = true; _error = null; _hasSearched = true; });
    try {
      final cities = await _placesService.searchCities(query.trim());
      setState(() { _cities = cities; _isLoading = false; });
    } catch (e) {
      setState(() { _error = 'Search failed.'; _isLoading = false; });
    }
  }

  Future<void> _openMaps(String city, String country) async {
    final q = Uri.encodeComponent('$city $country tourist attractions');
    final uri = Uri.parse('https://www.google.com/maps/search/$q');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openCityMap(CityModel city) async {
    final url = city.latitude != null
        ? 'https://www.google.com/maps/@${city.latitude},${city.longitude},12z'
        : 'https://www.google.com/maps/search/${Uri.encodeComponent('${city.city} ${city.country}')}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _selectCity(String cityName, String country) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // City info
            Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: Text('🏙️', style: TextStyle(fontSize: 28))),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cityName, style: AppTextStyles.headline2),
                    Text(country, style: AppTextStyles.bodySecondary),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Plan Trip button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateTripScreen(
                        templateCity: cityName,
                        templateCountry: country,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.flight_takeoff, size: 18),
                label: const Text(
                  'Plan a Trip Here',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // View Map button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _openMaps(cityName, country);
                },
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text(
                  'View on Google Maps',
                  style: TextStyle(fontSize: 15),
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: const BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Explore Places'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) {
                if (v.length >= 2) _search(v);
                if (v.isEmpty) setState(() { _hasSearched = false; _cities = []; });
              },
              onSubmitted: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search cities...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() { _hasSearched = false; _cities = []; });
                  },
                )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Searching...')
          : _error != null
          ? ErrorWidget2(message: _error!, onRetry: () => _search(_searchCtrl.text))
          : _hasSearched
          ? _buildResults()
          : _buildDiscover(),
    );
  }

  Widget _buildDiscover() {
    return CustomScrollView(
      slivers: [
        // Map banner
        SliverToBoxAdapter(
          child: GestureDetector(
            onTap: () async {
              final uri = Uri.parse('https://www.google.com/maps');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: Container(
              margin: const EdgeInsets.all(16),
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A73E8), Color(0xFF34A853)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🗺️ Open Google Maps',
                              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Explore attractions worldwide',
                              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Open →',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Tip
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.touch_app, size: 15, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Card tap karo → Trip plan karo ya Map dekho',
                  style: TextStyle(color: AppColors.primary.withOpacity(0.8), fontSize: 12),
                ),
              ],
            ),
          ),
        ),

        // Heading
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text('🌍 Popular Destinations', style: AppTextStyles.headline3),
          ),
        ),

        // Grid
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                final d = _popularDestinations[i];
                return _DestCard(
                  name: d['name'],
                  country: d['country'],
                  emoji: d['emoji'],
                  tag: d['tag'],
                  desc: d['desc'],
                  onTap: () => _selectCity(d['name'], d['country']),
                );
              },
              childCount: _popularDestinations.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildResults() {
    if (_cities.isEmpty) {
      return EmptyStateWidget(
        emoji: '🔍',
        title: 'No cities found',
        subtitle: 'Try a different search term',
        action: TextButton(
          onPressed: () {
            _searchCtrl.clear();
            setState(() { _hasSearched = false; });
          },
          child: const Text('Clear Search'),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cities.length,
      itemBuilder: (ctx, i) {
        final city = _cities[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Text('🏙️', style: TextStyle(fontSize: 24))),
            ),
            title: Text(city.city,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Text('${city.country} • ${city.countryCode}',
                style: AppTextStyles.caption),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Map
                GestureDetector(
                  onTap: () => _openCityMap(city),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.map, color: AppColors.secondary, size: 18),
                  ),
                ),
                const SizedBox(width: 8),
                // Plan trip
                GestureDetector(
                  onTap: () => _selectCity(city.city, city.country),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.flight_takeoff, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
            onTap: () => _selectCity(city.city, city.country),
          ),
        );
      },
    );
  }
}

class _DestCard extends StatelessWidget {
  final String name, country, emoji, tag, desc;
  final VoidCallback onTap;

  const _DestCard({
    required this.name,
    required this.country,
    required this.emoji,
    required this.tag,
    required this.desc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(tag,
                      style: const TextStyle(
                          fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                overflow: TextOverflow.ellipsis),
            Text(country, style: AppTextStyles.caption),
            const SizedBox(height: 4),
            Text(desc,
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text('Plan Trip',
                      style: TextStyle(
                          color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}