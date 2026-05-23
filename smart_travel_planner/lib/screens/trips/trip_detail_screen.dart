// lib/screens/trips/trip_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/trip_model.dart';
import '../../models/itinerary_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/common_widgets.dart';
import 'create_trip_screen.dart';
import '../chat/chat_screen.dart';
import '../itinerary/itinerary_form_screen.dart';
import '../weather/weather_screen.dart';

class TripDetailScreen extends StatefulWidget {
  final TripModel trip;
  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TripModel _trip;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Color> get _gradientColors {
    if (_trip.isPast) {
      return [const Color(0xFF636366), const Color(0xFF3A3A3C)];
    } else if (_trip.isOngoing) {
      return [const Color(0xFF34A853), const Color(0xFF1B6B35)];
    } else {
      return [const Color(0xFF1A73E8), const Color(0xFF0D47A1)];
    }
  }

  Future<void> _deleteTrip() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Trip'),
        content: Text('Delete "${_trip.destination}" trip? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<TripProvider>().deleteTrip(_trip.id);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _addMember() async {
    final emailCtrl = TextEditingController();
    final authService = AuthService();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the email of the person you want to add:'),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (emailCtrl.text.trim().isEmpty) return;
              final users =
              await authService.searchUsersByEmail(emailCtrl.text);
              if (users.isEmpty) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('No user found with that email')),
                  );
                }
                return;
              }
              final userId = users.first['id'] as String;
              if (mounted) {
                await context.read<TripProvider>().addMember(_trip.id, userId);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${users.first['name']} added to trip!'),
                      backgroundColor: AppColors.secondary,
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final isOwner = _trip.userId == auth.userId;
    final colors = _gradientColors;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            elevation: 0,
            backgroundColor: colors[0],
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (isOwner) ...[
                IconButton(
                  icon: const Icon(Icons.person_add_outlined, color: Colors.white),
                  tooltip: 'Invite Member',
                  onPressed: _addMember,
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  tooltip: 'Edit Trip',
                  onPressed: () async {
                    final updated = await Navigator.push<TripModel>(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              CreateTripScreen(existingTrip: _trip)),
                    );
                    if (updated != null) setState(() => _trip = updated);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  tooltip: 'Delete Trip',
                  onPressed: _deleteTrip,
                ),
              ],
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      right: -40,
                      top: -40,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.07),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      bottom: 60,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    // Trip info - positioned at bottom of expanded area
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 56, // above tab bar
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _trip.isOngoing
                                  ? '🟢 Ongoing'
                                  : _trip.isPast
                                  ? '✅ Completed'
                                  : '🔵 Upcoming',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Destination name — capitalized properly
                          Text(
                            _trip.destination,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (_trip.country != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              _trip.country!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 14,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 13,
                                  color: Colors.white.withOpacity(0.85)),
                              const SizedBox(width: 5),
                              Text(
                                '${DateFormat('MMM d').format(_trip.startDate)} – ${DateFormat('MMM d, yyyy').format(_trip.endDate)}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_trip.durationDays} days',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: colors[1],
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(fontSize: 13),
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.list_alt_rounded, size: 17),
                          SizedBox(width: 6),
                          Text('Itinerary'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 17),
                          SizedBox(width: 6),
                          Text('Chat'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wb_sunny_outlined, size: 17),
                          SizedBox(width: 6),
                          Text('Weather'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _ItineraryTab(trip: _trip),
            ChatScreen(trip: _trip),
            WeatherScreen(destinationOverride: _trip.destination),
          ],
        ),
      ),
    );
  }
}

// ─── Itinerary Tab ─────────────────────────────────────────────────────────

class _ItineraryTab extends StatelessWidget {
  final TripModel trip;
  const _ItineraryTab({required this.trip});

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.read<TripProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ItineraryFormScreen(trip: trip)),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Activity'),
        backgroundColor: AppColors.primary,
      ),
      body: StreamBuilder<List<ItineraryItem>>(
        stream: tripProvider.getTripItinerary(trip.id),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Loading itinerary...');
          }
          if (snapshot.hasError) {
            return ErrorWidget2(
                message: 'Failed to load itinerary', onRetry: () {});
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return EmptyStateWidget(
              emoji: '📋',
              title: 'No activities yet',
              subtitle:
              'Add places to visit, restaurants, transport and more.',
              action: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ItineraryFormScreen(trip: trip)),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add Activity'),
              ),
            );
          }

          // Group by date
          final Map<String, List<ItineraryItem>> grouped = {};
          for (final item in items) {
            final key = DateFormat('yyyy-MM-dd').format(item.date);
            grouped.putIfAbsent(key, () => []).add(item);
          }
          final sortedKeys = grouped.keys.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: sortedKeys.length,
            itemBuilder: (ctx, i) {
              final key = sortedKeys[i];
              final date = DateTime.parse(key);
              final dayItems = grouped[key]!;
              final dayNumber =
                  date.difference(trip.startDate).inDays + 1;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day Header
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'D$dayNumber',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE').format(date),
                              style: AppTextStyles.headline3
                                  .copyWith(fontSize: 16),
                            ),
                            Text(
                              DateFormat('MMMM d, yyyy').format(date),
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Items
                  ...dayItems.map((item) =>
                      _ItineraryItemCard(item: item, trip: trip)),
                  const SizedBox(height: 8),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Itinerary Item Card ──────────────────────────────────────────────────

class _ItineraryItemCard extends StatelessWidget {
  final ItineraryItem item;
  final TripModel trip;
  const _ItineraryItemCard({required this.item, required this.trip});

  IconData _typeIconData(ActivityType type) {
    switch (type) {
      case ActivityType.sightseeing:
        return Icons.account_balance_rounded;
      case ActivityType.food:
        return Icons.restaurant_rounded;
      case ActivityType.transport:
        return Icons.directions_car_rounded;
      case ActivityType.accommodation:
        return Icons.hotel_rounded;
      case ActivityType.activity:
        return Icons.local_activity_rounded;
      case ActivityType.other:
        return Icons.place_rounded;
    }
  }

  Color _typeColor(ActivityType type) {
    switch (type) {
      case ActivityType.sightseeing:
        return const Color(0xFF9334E6);
      case ActivityType.food:
        return const Color(0xFFE8710A);
      case ActivityType.transport:
        return const Color(0xFF1A73E8);
      case ActivityType.accommodation:
        return const Color(0xFF00796B);
      case ActivityType.activity:
        return const Color(0xFF34A853);
      case ActivityType.other:
        return const Color(0xFF5F6368);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(item.type);
    final icon = _typeIconData(item.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10, left: 56),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (item.startTime != null || item.endTime != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 13, color: color),
                        const SizedBox(width: 4),
                        Text(
                          [
                            if (item.startTime != null) item.startTime!,
                            if (item.endTime != null) item.endTime!,
                          ].join(' – '),
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (item.location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            item.location!,
                            style: AppTextStyles.caption,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (item.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description!,
                      style: AppTextStyles.bodySecondary
                          .copyWith(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (item.notes != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.sticky_note_2_outlined,
                              size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.notes!,
                              style: AppTextStyles.caption,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Menu
            PopupMenuButton(
              icon: const Icon(Icons.more_vert,
                  size: 18, color: AppColors.textSecondary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline,
                        size: 16, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete',
                        style: TextStyle(color: AppColors.error)),
                  ]),
                ),
              ],
              onSelected: (value) async {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ItineraryFormScreen(
                          trip: trip, existingItem: item),
                    ),
                  );
                } else if (value == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Activity'),
                      content: Text('Delete "${item.title}"?'),
                      actions: [
                        TextButton(
                            onPressed: () =>
                                Navigator.pop(ctx, false),
                            child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () =>
                              Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    context
                        .read<TripProvider>()
                        .deleteItineraryItem(item.id);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}