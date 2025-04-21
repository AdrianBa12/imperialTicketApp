class Seat {
  final String id;
  final String number;
  final bool isBooked;
  final bool isSelected;
  final bool isTemporarilyHeld;
  final String? bookedBy;
  final String? heldByUserId;
  final String seatType; 
  final double price;

  bool get isAvailable => !isBooked && !isTemporarilyHeld;

  double get priceWithTax => price;


  Seat({
    required this.id,
    required this.number,
    this.isBooked = false,
    this.isSelected = false,
    this.isTemporarilyHeld = false,
    this.bookedBy,
    this.heldByUserId,
    this.seatType = 'normal',
    required this.price,
  });

  Seat copyWith({
    String? id,
    String? number,
    bool? isBooked,
    bool? isSelected,
    bool? isTemporarilyHeld,
    String? bookedBy,
    String? heldByUserId,
    String? seatType,
    double? price,
  }) {
    return Seat(
      id: id ?? this.id,
      number: number ?? this.number,
      isBooked: isBooked ?? this.isBooked,
      isSelected: isSelected ?? this.isSelected,
      isTemporarilyHeld: isTemporarilyHeld ?? this.isTemporarilyHeld,
      bookedBy: bookedBy ?? this.bookedBy,
      heldByUserId: heldByUserId ?? this.heldByUserId,
      seatType: seatType ?? this.seatType,
      price: price ?? this.price,
    );
  }


  factory Seat.fromJson(Map<String, dynamic> json) {
    return Seat(
      id: json['_id'] ?? json['id'] ?? '',
      number: json['number']?.toString() ?? '',
      isBooked: json['isBooked'] == true,

      isSelected: json['isSelected'] == true,
      isTemporarilyHeld: json['isTemporarilyHeld'] == true,
      bookedBy: json['bookedBy']?.toString(),
      heldByUserId: json['heldByUserId']?.toString(),
      seatType: json['seatType']?.toString() ?? 'normal',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );

  }
  factory Seat.fromMap(Map<String, dynamic> map) {
    return Seat(
      id: map['_id'] ?? map['id'] ?? '',
      number: map['number']?.toString() ?? '',
      isBooked: map['isBooked'] == true,
      isSelected: map['isSelected'] == true,
      isTemporarilyHeld: map['isTemporarilyHeld'] == true,
      bookedBy: map['bookedBy']?.toString(),
      heldByUserId: map['heldByUserId']?.toString(),
      seatType: map['seatType']?.toString() ?? 'normal',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'number': number,
      'isBooked': isBooked,
      'isTemporarilyHeld': isTemporarilyHeld,
      'bookedBy': bookedBy,
      'heldByUserId': heldByUserId,
      'seatType': seatType,
      'isSelected': isSelected,
      'price': price,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Seat &&
        other.id == id &&
        other.number == number &&
        other.isBooked == isBooked &&
        other.isSelected == isSelected &&
        other.isTemporarilyHeld == isTemporarilyHeld &&
        other.bookedBy == bookedBy &&
        other.heldByUserId == heldByUserId &&
        other.seatType == seatType &&
        other.price == price;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    number.hashCode ^
    isBooked.hashCode ^
    isSelected.hashCode ^
    isTemporarilyHeld.hashCode ^
    bookedBy.hashCode ^
    heldByUserId.hashCode ^
    seatType.hashCode ^
    price.hashCode;
  }
  @override
  String toString() {
    return 'Seat(id: $id, number: $number, isBooked: $isBooked, '
        'isSelected: $isSelected, isTemporarilyHeld: $isTemporarilyHeld, '
        'bookedBy: $bookedBy, heldByUserId: $heldByUserId, '
        'seatType: $seatType, isAvailable: $isAvailable)';
  }
}
