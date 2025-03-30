class Ticket {
  final String id;
  final String busName;
  final String busNumber;
  final String busType;
  final String fromCity;
  final String toCity;
  final String departureTime;
  final String arrivalTime;
  final DateTime journeyDate;
  final List<String> seats;
  final double baseFare;
  final double serviceFee;
  final double tax;
  final double? discount;
  final String passengerName;
  final String passengerEmail;
  final String passengerPhone;
  final DateTime bookingTime;
  final String bookingStatus;

  double get totalWithTax => (baseFare + serviceFee) * 1.18 - (discount ?? 0);

  Ticket({
    required this.id,
    required this.busName,
    required this.busNumber,
    required this.busType,
    required this.fromCity,
    required this.toCity,
    required this.departureTime,
    required this.arrivalTime,
    required this.journeyDate,
    required this.seats,
    required this.baseFare,
    required this.serviceFee,
    required this.tax,
    this.discount,
    required this.passengerName,
    required this.passengerEmail,
    required this.passengerPhone,
    required this.bookingTime,
    this.bookingStatus = 'confirmed',
  });

  /// Convertir desde JSON
  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['_id'] ?? json['id'] ?? '',
      busName: json['busName'] ?? 'Unknown Bus',
      busNumber: json['busNumber'] ?? 'Unknown',
      busType: json['busType'] ?? 'Standard',
      fromCity: json['fromCity'] ?? 'Unknown City',
      toCity: json['toCity'] ?? 'Unknown City',
      departureTime: json['departureTime'] ?? '',
      arrivalTime: json['arrivalTime'] ?? '',
      journeyDate: _parseDate(json['journeyDate']),
      seats: (json['seats'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      baseFare: (json['baseFare'] ?? 0).toDouble(),
      serviceFee: (json['serviceFee'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      discount: json['discount']?.toDouble(),
      passengerName: json['passengerName'] ?? 'Unknown',
      passengerEmail: json['passengerEmail'] ?? '',
      passengerPhone: json['passengerPhone'] ?? '',
      bookingTime: _parseDate(json['bookingTime']),
      bookingStatus: json['bookingStatus'] ?? 'confirmed',
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'busName': busName,
      'busNumber': busNumber,
      'busType': busType,
      'fromCity': fromCity,
      'toCity': toCity,
      'departureTime': departureTime,
      'arrivalTime': arrivalTime,
      'journeyDate': journeyDate.toIso8601String(),
      'seats': seats,
      'baseFare': baseFare,
      'serviceFee': serviceFee,
      'tax': tax,
      'discount': discount,
      'passengerName': passengerName,
      'passengerEmail': passengerEmail,
      'passengerPhone': passengerPhone,
      'bookingTime': bookingTime.toIso8601String(),
      'bookingStatus': bookingStatus,
    };
  }

  /// Crear una copia con valores opcionales
  Ticket copyWith({
    String? id,
    String? busName,
    String? busNumber,
    String? busType,
    String? fromCity,
    String? toCity,
    String? departureTime,
    String? arrivalTime,
    DateTime? journeyDate,
    List<String>? seats,
    double? baseFare,
    double? serviceFee,
    double? tax,
    double? discount,
    String? passengerName,
    String? passengerEmail,
    String? passengerPhone,
    DateTime? bookingTime,
    String? bookingStatus,
  }) {
    return Ticket(
      id: id ?? this.id,
      busName: busName ?? this.busName,
      busNumber: busNumber ?? this.busNumber,
      busType: busType ?? this.busType,
      fromCity: fromCity ?? this.fromCity,
      toCity: toCity ?? this.toCity,
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      journeyDate: journeyDate ?? this.journeyDate,
      seats: seats ?? this.seats,
      baseFare: baseFare ?? this.baseFare,
      serviceFee: serviceFee ?? this.serviceFee,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      passengerName: passengerName ?? this.passengerName,
      passengerEmail: passengerEmail ?? this.passengerEmail,
      passengerPhone: passengerPhone ?? this.passengerPhone,
      bookingTime: bookingTime ?? this.bookingTime,
      bookingStatus: bookingStatus ?? this.bookingStatus,
    );
  }

  static DateTime _parseDate(dynamic date) {
    if (date is String && date.isNotEmpty) {
      try {
        return DateTime.parse(date);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}
