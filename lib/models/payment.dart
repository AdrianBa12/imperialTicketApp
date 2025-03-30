class Payment {
  final String id;
  final String userId;
  final String bookingId;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String paymentIntentId;
  final String status;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.userId,
    required this.bookingId,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.paymentIntentId,
    required this.status,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      bookingId: json['bookingId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'INR',
      paymentMethod: json['paymentMethod'] ?? '',
      paymentIntentId: json['paymentIntentId'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'bookingId': bookingId,
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'paymentIntentId': paymentIntentId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}