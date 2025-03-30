class BusRoute {
  final String id;
  final String fromCity;
  final String toCity;
  final int distance;
  final int duration; // in minutes
  final double baseFare;
  final bool isPopular;
  final List<String> busIds;
  final DateTime travelDate;// References to buses that serve this route

  BusRoute({
    required this.id,
    required this.fromCity,
    required this.toCity,
    required this.distance,
    required this.duration,
    required this.baseFare,
    this.isPopular = false,
    this.busIds = const [],
    required this.travelDate,

  });

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    return BusRoute(
      id: json['_id'] ?? json['id'] ?? '',
      fromCity: json['fromCity'] ?? '',
      toCity: json['toCity'] ?? '',
      distance: json['distance'] ?? 0,
      duration: json['duration'] ?? 0,
      baseFare: (json['baseFare'] ?? 0).toDouble(),
      isPopular: json['isPopular'] ?? false,
      busIds: json['busIds'] != null
          ? List<String>.from(json['busIds'])
          : [],
      travelDate: json['travelDate'] != null
          ? DateTime.parse(json['travelDate'])
          : DateTime.now(), // Parse the travelDate field if it exists, or set it to current date
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromCity': fromCity,
      'toCity': toCity,
      'distance': distance,
      'duration': duration,
      'baseFare': baseFare,
      'isPopular': isPopular,
      'busIds': busIds,
      'travelDate': travelDate.toIso8601String(), // Convert DateTime to ISO 8601 string
    };
  }
}