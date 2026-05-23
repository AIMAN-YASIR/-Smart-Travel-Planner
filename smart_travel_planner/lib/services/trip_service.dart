// lib/services/trip_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_model.dart';
import '../models/itinerary_model.dart';

class TripService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _trips => _firestore.collection('trips');
  CollectionReference get _itinerary => _firestore.collection('itinerary');

  // ─── TRIPS ────────────────────────────────────────────────────────────────

  Stream<List<TripModel>> getUserTrips(String userId) {
    return _trips
        .where('memberIds', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => TripModel.fromFirestore(doc)).toList());
  }

  Stream<List<TripModel>> getPastTrips(String userId) {
    return _trips
        .where('memberIds', arrayContains: userId)
        .where('endDate', isLessThan: Timestamp.fromDate(DateTime.now()))
        .orderBy('endDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => TripModel.fromFirestore(doc)).toList());
  }

  Future<TripModel> createTrip({
    required String userId,
    required String destination,
    String? country,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
  }) async {
    final docRef = await _trips.add({
      'userId': userId,
      'destination': destination,
      'country': country,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'notes': notes,
      'memberIds': [userId],
      'isCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final doc = await docRef.get();
    return TripModel.fromFirestore(doc);
  }

  Future<void> updateTrip(TripModel trip) async {
    await _trips.doc(trip.id).update(trip.toFirestore());
  }

  Future<void> deleteTrip(String tripId) async {
    // Delete trip and all its itinerary
    final batch = _firestore.batch();
    batch.delete(_trips.doc(tripId));

    final itinerarySnap = await _itinerary.where('tripId', isEqualTo: tripId).get();
    for (final doc in itinerarySnap.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  Future<void> addMemberToTrip(String tripId, String userId) async {
    await _trips.doc(tripId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> removeMemberFromTrip(String tripId, String userId) async {
    await _trips.doc(tripId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
    });
  }

  Future<TripModel?> getTripById(String tripId) async {
    final doc = await _trips.doc(tripId).get();
    if (!doc.exists) return null;
    return TripModel.fromFirestore(doc);
  }

  // ─── ITINERARY ────────────────────────────────────────────────────────────

  Stream<List<ItineraryItem>> getTripItinerary(String tripId) {
    return _itinerary
        .where('tripId', isEqualTo: tripId)
        .orderBy('date')
        .snapshots()
        .map((snap) =>
        snap.docs.map((doc) => ItineraryItem.fromFirestore(doc)).toList());
  }

  Future<ItineraryItem> addItineraryItem({
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
    final item = ItineraryItem(
      id: '',
      tripId: tripId,
      date: DateTime(date.year, date.month, date.day),
      title: title,
      description: description,
      location: location,
      notes: notes,
      type: type,
      startTime: startTime,
      endTime: endTime,
      createdAt: DateTime.now(),
    );

    final docRef = await _itinerary.add(item.toFirestore());
    final doc = await docRef.get();
    return ItineraryItem.fromFirestore(doc);
  }

  Future<void> updateItineraryItem(ItineraryItem item) async {
    await _itinerary.doc(item.id).update(item.toFirestore());
  }

  Future<void> deleteItineraryItem(String itemId) async {
    await _itinerary.doc(itemId).delete();
  }
}