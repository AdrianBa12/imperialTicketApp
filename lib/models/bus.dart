import 'seat.dart';

class Bus {
  final String id;
  final String name;
  final String busNumber;
  final String busType;
  final int totalSeats;
  final List<Seat> seats;
  final double fare;
  final String departureTime;
  final String arrivalTime;
  final int duration;
  final int distance;
  final List<String> amenities;
  final double rating;
  final int reviewCount;
  final String operator;
  final DateTime? travelDate;

  Bus({
    required this.id,
    required this.name,
    required this.busNumber,
    required this.busType,
    required this.totalSeats,
    required this.seats,
    required this.fare,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.operator,
    this.distance = 0,
    this.amenities = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    this.travelDate,
  });

  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      busNumber: json['busNumber'] ?? '',
      busType: json['busType'] ?? 'Standard',
      totalSeats: (json['totalSeats'] ?? 0) as int,
      seats: (json['seats'] is List)
          ? List<Seat>.from(json['seats'].map((seat) => Seat.fromJson(seat)))
          : [],
      fare: (json['fare'] is num) ? (json['fare'] as num).toDouble() : 0.0,
      departureTime: json['departureTime'] ?? '',
      arrivalTime: json['arrivalTime'] ?? '',
      duration: (json['duration'] is num) ? (json['duration'] as num).toInt() : 0,
      distance: (json['distance'] is num) ? (json['distance'] as num).toInt() : 0,
      amenities: (json['amenities'] is List)
          ? List<String>.from(json['amenities'].whereType<String>())
          : [],
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 0.0,
      reviewCount: (json['reviewCount'] is num) ? (json['reviewCount'] as num).toInt() : 0,
      operator: json['operator'] ?? 'Desconocido',
      travelDate: (json['travelDate'] is String)
          ? DateTime.tryParse(json['travelDate'])
          : null,
    );
  }
}
