// lib/screens/trips/trips_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/trip_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/common_widgets.dart';
import 'create_trip_screen.dart';
import 'trip_detail_screen.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<TripProvider>().loadTrips(auth.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tripProvider = context.watch<TripProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My Trips'),
            Text(
              'Hello, ${auth.userName} 👋',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Sign Out',
            onPressed: () async {
              final confirm = await _showLogoutDialog(context);
              if (confirm == true && context.mounted) {
                context.read<AuthProvider>().signOut();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<TripProvider>().loadTrips(auth.userId);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: tripProvider.isLoading && tripProvider.trips.isEmpty
            ? const LoadingWidget(message: 'Loading your trips...')
            : tripProvider.trips.isEmpty
            ? EmptyStateWidget(
          emoji: '✈️',
          title: 'No trips yet',
          subtitle: 'Start planning your first adventure!',
          action: ElevatedButton.icon(
            onPressed: () => _openCreateTrip(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Trip'),
          ),
        )
            : CustomScrollView(
          slivers: [
            // Upcoming / Ongoing Trips
            if (tripProvider.upcomingTrips.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: SectionHeader(title: '🗺️ Upcoming Trips'),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _TripCard(trip: tripProvider.upcomingTrips[i]),
                  childCount: tripProvider.upcomingTrips.length,
                ),
              ),
            ],

            // Past Trips
            if (tripProvider.pastTrips.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: SectionHeader(title: '📚 Past Trips'),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _TripCard(trip: tripProvider.pastTrips[i]),
                  childCount: tripProvider.pastTrips.length,
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateTrip(context),
        icon: const Icon(Icons.add),
        label: const Text('New Trip'),
      ),
    );
  }

  void _openCreateTrip(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateTripScreen()),
    );
  }

  Future<bool?> _showLogoutDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// ─── Trip Card ────────────────────────────────────────────────────────────

class _TripCard extends StatelessWidget {
  final TripModel trip;
  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d');
    final gradient = trip.isPast
        ? [const Color(0xFF8E8E93), const Color(0xFF636366)]
        : trip.isOngoing
        ? [const Color(0xFF34A853), const Color(0xFF1E7E34)]
        : [const Color(0xFF1A73E8), const Color(0xFF0D47A1)];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background decorations
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              right: 30,
              bottom: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          trip.destination,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          trip.isOngoing ? 'Ongoing' : trip.isPast ? 'Past' : 'Upcoming',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  if (trip.country != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      trip.country!,
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.white.withOpacity(0.8)),
                      const SizedBox(width: 6),
                      Text(
                        '${dateFormat.format(trip.startDate)} – ${dateFormat.format(trip.endDate)}',
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time, size: 14, color: Colors.white.withOpacity(0.8)),
                      const SizedBox(width: 4),
                      Text(
                        '${trip.durationDays} days',
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                      ),
                    ],
                  ),
                  if (trip.memberIds.length > 1) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.group, size: 14, color: Colors.white.withOpacity(0.8)),
                        const SizedBox(width: 6),
                        Text(
                          '${trip.memberIds.length} members',
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}