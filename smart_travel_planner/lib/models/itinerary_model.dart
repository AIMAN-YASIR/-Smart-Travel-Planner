// lib/models/itinerary_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType { sightseeing, food, transport, accommodation, activity, other }

class ItineraryItem {
  final String id;
  final String tripId;
  final DateTime date;
  final String title;
  final String? description;
  final String? location;
  final String? notes;
  final ActivityType type;
  final String? startTime;
  final String? endTime;
  final DateTime createdAt;

  ItineraryItem({
    required this.id,
    required this.tripId,
    required this.date,
    required this.title,
    this.description,
    this.location,
    this.notes,
    this.type = ActivityType.activity,
    this.startTime,
    this.endTime,
    required this.createdAt,
  });

  factory ItineraryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ItineraryItem(
      id: doc.id,
      tripId: data['tripId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      title: data['title'] ?? '',
      description: data['description'],
      location: data['location'],
      notes: data['notes'],
      type: ActivityType.values.firstWhere(
            (e) => e.name == (data['type'] ?? 'activity'),
        orElse: () => ActivityType.activity,
      ),
      startTime: data['startTime'],
      endTime: data['endTime'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tripId': tripId,
      'date': Timestamp.fromDate(date),
      'title': title,
      'description': description,
      'location': location,
      'notes': notes,
      'type': type.name,
      'startTime': startTime,
      'endTime': endTime,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ItineraryItem copyWith({
    DateTime? date,
    String? title,
    String? description,
    String? location,
    String? notes,
    ActivityType? type,
    String? startTime,
    String? endTime,
  }) {
    return ItineraryItem(
      id: id,
      tripId: tripId,
      date: date ?? this.date,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt,
    );
  }

  String get typeIcon {
    switch (type) {
      case ActivityType.sightseeing: return '🏛️';
      case ActivityType.food: return '🍽️';
      case ActivityType.transport: return '🚗';
      case ActivityType.accommodation: return '🏨';
      case ActivityType.activity: return '🎯';
      case ActivityType.other: return '📌';
    }
  }
}