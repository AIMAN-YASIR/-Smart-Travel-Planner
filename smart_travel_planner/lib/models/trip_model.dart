// lib/models/trip_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TripModel {
  final String id;
  final String userId;
  final String destination;
  final String? country;
  final DateTime startDate;
  final DateTime endDate;
  final String? notes;
  final String? imageUrl;
  final List<String> memberIds;
  final bool isCompleted;
  final DateTime createdAt;

  TripModel({
    required this.id,
    required this.userId,
    required this.destination,
    this.country,
    required this.startDate,
    required this.endDate,
    this.notes,
    this.imageUrl,
    this.memberIds = const [],
    this.isCompleted = false,
    required this.createdAt,
  });

  bool get isPast => endDate.isBefore(DateTime.now());
  bool get isUpcoming => startDate.isAfter(DateTime.now());
  bool get isOngoing =>
      startDate.isBefore(DateTime.now()) && endDate.isAfter(DateTime.now());

  int get durationDays => endDate.difference(startDate).inDays + 1;

  factory TripModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TripModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      destination: data['destination'] ?? '',
      country: data['country'],
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      notes: data['notes'],
      imageUrl: data['imageUrl'],
      memberIds: List<String>.from(data['memberIds'] ?? []),
      isCompleted: data['isCompleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'destination': destination,
      'country': country,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'notes': notes,
      'imageUrl': imageUrl,
      'memberIds': memberIds,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  TripModel copyWith({
    String? destination,
    String? country,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    String? imageUrl,
    List<String>? memberIds,
    bool? isCompleted,
  }) {
    return TripModel(
      id: id,
      userId: userId,
      destination: destination ?? this.destination,
      country: country ?? this.country,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
      memberIds: memberIds ?? this.memberIds,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }
}