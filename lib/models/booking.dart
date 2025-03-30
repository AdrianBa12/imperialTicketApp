class Booking {
  final String id;
  final String userId;
  final String busId;
  final String routeId;
  final String busName;
  final String busNumber;
  final String fromCity;
  final String toCity;
  final String departureTime;
  final String arrivalTime;
  final DateTime journeyDate;
  final List<String> seats;
  final double seatFare;
  final double serviceFee;
  final double gst;
  final double discount;
  final double totalFare;
  final String passengerName;
  final String passengerEmail;
  final String passengerPhone;
  final DateTime bookingTime;
  final String? paymentId;
  final String bookingStatus;

  Booking({
    this.id = '',
    required this.userId,
    required this.busId,
    required this.routeId,
    required this.busName,
    required this.busNumber,
    required this.fromCity,
    required this.toCity,
    required this.departureTime,
    required this.arrivalTime,
    required this.journeyDate,
    required this.seats,
    required this.seatFare,
    required this.serviceFee,
    required this.gst,
    this.discount = 0.0,
    required this.totalFare,
    required this.passengerName,
    required this.passengerEmail,
    required this.passengerPhone,
    DateTime? bookingTime,
    this.paymentId,
    this.bookingStatus = 'pending',
  }) : bookingTime = bookingTime ?? DateTime.now();

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      busId: json['busId'] ?? '',
      routeId: json['routeId'] ?? '',
      busName: json['busName'] ?? '',
      busNumber: json['busNumber'] ?? '',
      fromCity: json['fromCity'] ?? '',
      toCity: json['toCity'] ?? '',
      departureTime: json['departureTime'] ?? '',
      arrivalTime: json['arrivalTime'] ?? '',
      journeyDate: json['journeyDate'] != null
          ? DateTime.parse(json['journeyDate'])
          : DateTime.now(),
      seats: List<String>.from(json['seats'] ?? []),
      seatFare: (json['seatFare'] ?? 0).toDouble(),
      serviceFee: (json['serviceFee'] ?? 0).toDouble(),
      gst: (json['gst'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      totalFare: (json['totalFare'] ?? 0).toDouble(),
      passengerName: json['passengerName'] ?? '',
      passengerEmail: json['passengerEmail'] ?? '',
      passengerPhone: json['passengerPhone'] ?? '',
      bookingTime: json['bookingTime'] != null
          ? DateTime.parse(json['bookingTime'])
          : DateTime.now(),
      paymentId: json['paymentId'],
      bookingStatus: json['bookingStatus'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'busId': busId,
      'routeId': routeId,
      'busName': busName,
      'busNumber': busNumber,
      'fromCity': fromCity,
      'toCity': toCity,
      'departureTime': departureTime,
      'arrivalTime': arrivalTime,
      'journeyDate': journeyDate.toIso8601String(),
      'seats': seats,
      'seatFare': seatFare,
      'serviceFee': serviceFee,
      'gst': gst,
      'discount': discount,
      'totalFare': totalFare,
      'passengerName': passengerName,
      'passengerEmail': passengerEmail,
      'passengerPhone': passengerPhone,
      'bookingTime': bookingTime.toIso8601String(),
      'paymentId': paymentId,
      'bookingStatus': bookingStatus,
    };
  }
}