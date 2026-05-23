// lib/screens/history/history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/trip_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/common_widgets.dart';
import '../screens/trips/trip_detail_screen.dart';
import '../screens/trips/create_trip_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final pastTrips = tripProvider.pastTrips;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Travel History'),
      ),
      body: pastTrips.isEmpty
          ? const EmptyStateWidget(
        emoji: '📚',
        title: 'No travel history yet',
        subtitle: 'Your completed and past trips will appear here.',
      )
          : ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // Stats summary
          _StatsSummary(trips: pastTrips),
          const SizedBox(height: 20),

          SectionHeader(title: '🗺️ Past Trips (${pastTrips.length})'),
          const SizedBox(height: 12),

          ...pastTrips.map((trip) => _HistoryTripCard(trip: trip)),
        ],
      ),
    );
  }
}

// ─── Stats Summary ─────────────────────────────────────────────────────────

class _StatsSummary extends StatelessWidget {
  final List<TripModel> trips;
  const _StatsSummary({required this.trips});

  @override
  Widget build(BuildContext context) {
    final totalDays = trips.fold<int>(0, (sum, t) => sum + t.durationDays);
    final countries = trips.map((t) => t.country ?? t.destination).toSet().length;
    final destinations = trips.map((t) => t.destination).toSet().length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '✈️ Your Travel Stats',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatItem(value: trips.length.toString(), label: 'Trips'),
              const SizedBox(width: 8),
              _StatItem(value: destinations.toString(), label: 'Destinations'),
              const SizedBox(width: 8),
              _StatItem(value: countries.toString(), label: 'Countries'),
              const SizedBox(width: 8),
              _StatItem(value: totalDays.toString(), label: 'Days'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── History Trip Card ──────────────────────────────────────────────────────

class _HistoryTripCard extends StatelessWidget {
  final TripModel trip;
  const _HistoryTripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Left: colored indicator + emoji
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('🗺️', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 14),

              // Middle: info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.destination,
                      style: AppTextStyles.headline3.copyWith(fontSize: 16),
                    ),
                    if (trip.country != null) ...[
                      const SizedBox(height: 2),
                      Text(trip.country!, style: AppTextStyles.caption),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${dateFormat.format(trip.startDate)} – ${dateFormat.format(trip.endDate)}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Right: duration badge + action
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${trip.durationDays}d',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Re-use as template button
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateTripScreen(templateTrip: trip),
                        ),
                      );
                    },
                    child: const Text(
                      'Use again',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}