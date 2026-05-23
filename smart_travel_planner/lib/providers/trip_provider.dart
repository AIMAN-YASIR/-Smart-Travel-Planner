// lib/providers/trip_provider.dart
import 'package:flutter/foundation.dart';
import '../models/trip_model.dart';
import '../models/itinerary_model.dart';
import '../services/trip_service.dart';

class TripProvider extends ChangeNotifier {
  final TripService _tripService = TripService();

  List<TripModel> _trips = [];
  bool _isLoading = false;
  String? _error;

  List<TripModel> get trips => _trips;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<TripModel> get upcomingTrips =>
      _trips.where((t) => t.isUpcoming || t.isOngoing).toList();
  List<TripModel> get pastTrips =>
      _trips.where((t) => t.isPast).toList();

  void loadTrips(String userId) {
    _tripService.getUserTrips(userId).listen(
          (trips) {
        _trips = trips;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Failed to load trips: $e';
        notifyListeners();
      },
    );
  }

  Future<TripModel?> createTrip({
    required String userId,
    required String destination,
    String? country,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
  }) async {
    _setLoading(true);
    try {
      final trip = await _tripService.createTrip(
        userId: userId,
        destination: destination,
        country: country,
        startDate: startDate,
        endDate: endDate,
        notes: notes,
      );
      _setLoading(false);
      return trip;
    } catch (e) {
      _error = 'Failed to create trip: $e';
      _setLoading(false);
      return null;
    }
  }

  Future<bool> updateTrip(TripModel trip) async {
    try {
      await _tripService.updateTrip(trip);
      return true;
    } catch (e) {
      _error = 'Failed to update trip.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTrip(String tripId) async {
    try {
      await _tripService.deleteTrip(tripId);
      return true;
    } catch (e) {
      _error = 'Failed to delete trip.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> addMember(String tripId, String userId) async {
    try {
      await _tripService.addMemberToTrip(tripId, userId);
      return true;
    } catch (e) {
      _error = 'Failed to add member.';
      notifyListeners();
      return false;
    }
  }

  Stream<List<ItineraryItem>> getTripItinerary(String tripId) {
    return _tripService.getTripItinerary(tripId);
  }

  Future<ItineraryItem?> addItineraryItem({
    required String tripId,
    required DateTime date,
    required String title,
    String? description,
    String? location,
    String? notes,
    ActivityType type = ActivityType.activity,
    String? startTime,
    String? endTime,
  }) async {
    try {
      return await _tripService.addItineraryItem(
        tripId: tripId,
        date: date,
        title: title,
        description: description,
        location: location,
        notes: notes,
        type: type,
        startTime: startTime,
        endTime: endTime,
      );
    } catch (e) {
      _error = 'Failed to add item.';
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateItineraryItem(ItineraryItem item) async {
    try {
      await _tripService.updateItineraryItem(item);
      return true;
    } catch (e) {
      _error = 'Failed to update item.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteItineraryItem(String itemId) async {
    try {
      await _tripService.deleteItineraryItem(itemId);
      return true;
    } catch (e) {
      _error = 'Failed to delete item.';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}