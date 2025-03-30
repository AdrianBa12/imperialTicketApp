import 'package:flutter/foundation.dart';
import '../models/bus.dart';
import '../models/seat.dart';
import '../models/ticket.dart';

class BookingProvider with ChangeNotifier {
  // User selection data
  String? _fromCity;
  String? _toCity;
  DateTime? _journeyDate;
  double _totalPrice = 0.0;
  double? _discount;


  // Selected bus and route
  Bus? _selectedBus;
  String? _selectedRouteId;

  // Selected seats
  String? _bookingId;
  List<Seat> _selectedSeats = [];

  // Passenger details
  String? _passengerName;
  String? _passengerEmail;
  String? _passengerPhone;

  // User ID for booking
  String? _userId;

  // Final booking/ticket
  Ticket? _booking;

  // Getters
  String? get bookingId => _bookingId;
  String? get fromCity => _fromCity;
  String? get toCity => _toCity;
  DateTime? get journeyDate => _journeyDate;
  Bus? get selectedBus => _selectedBus;
  String? get selectedRouteId => _selectedRouteId;
  List<Seat> get selectedSeats => _selectedSeats;
  String? get passengerName => _passengerName;
  String? get passengerEmail => _passengerEmail;
  String? get passengerPhone => _passengerPhone;
  String? get userId => _userId;
  Ticket? get booking => _booking;
  double? get discount => _discount;

  double get totalPrice => _totalPrice;

  // Setters
  void setTotalPrice(double price) {
    _totalPrice = price;
    notifyListeners();
  }
  void calculateTotal() {
    _totalPrice = _selectedSeats.fold(0.0, (sum, seat) => sum + (seat.price));
    notifyListeners();
  }

  void toggleSeatSelection(Seat seat) {
    if (!seat.isAvailable) return;

    _selectedSeats.contains(seat)
        ? _selectedSeats.remove(seat)
        : _selectedSeats.add(seat);

    calculateTotal();
  }

  void clearSelection() {
    _selectedSeats.clear();
    _totalPrice = 0.0;
    notifyListeners();
  }



  void clearSeatSelection() {
    _selectedSeats.clear();
    _totalPrice = 0.0;
    notifyListeners();
  }
  void selectBus(Bus bus) {
    _selectedBus = bus;
    notifyListeners();
  }

  void applyDiscount(double amount) {
    _discount = amount;
    notifyListeners();
  }



  void setBookingId(String id) {
    _bookingId = id;
    notifyListeners();
  }

  void setFromCity(String city) {
    _fromCity = city;
    notifyListeners();
  }

  void setToCity(String city) {
    _toCity = city;
    notifyListeners();
  }



  void setJourneyDate(dynamic date) {
    if (date is String) {
      _journeyDate = DateTime.tryParse(date);
    } else if (date is DateTime) {
      _journeyDate = date;
    } else {
      _journeyDate = null;
    }
    notifyListeners();
  }

  void setSelectedBus(Bus bus, String routeId) {
    _selectedBus = bus;
    notifyListeners();
  }

  void setSelectedRouteId(String routeId) {
    _selectedRouteId = routeId;
    notifyListeners();
  }

  void toggleSeatSelectionApp(Seat seat) {
    final index = _selectedSeats.indexWhere((s) => s.id == seat.id);

    if (index >= 0) {
      // Seat is already selected, remove it
      _selectedSeats.removeAt(index);
    } else {
      // Seat is not selected, add it
      _selectedSeats.add(seat);
    }

    notifyListeners();
  }

  void clearSelectedSeats() {
    _selectedSeats = [];
    notifyListeners();
  }

  void setPassengerDetails({
    required String name,
    required String email,
    required String phone,
  }) {
    _passengerName = name;
    _passengerEmail = email;
    _passengerPhone = phone;
    notifyListeners();
  }

  void setUserId(String userId) {
    _userId = userId;
    notifyListeners();
  }

  void setBooking(Ticket ticket) {
    _booking = ticket;
    notifyListeners();
  }

  // Clear all data
  void clearAll() {
    _fromCity = null;
    _toCity = null;
    _journeyDate = null;
    _selectedBus = null;
    _selectedRouteId = null;
    _selectedSeats = [];
    _passengerName = null;
    _passengerEmail = null;
    _passengerPhone = null;
    _booking = null;
    notifyListeners();
  }

  // Clear booking data but keep user preferences
  void clearBookingData() {
    _selectedBus = null;
    _selectedRouteId = null;
    _selectedSeats = [];
    _booking = null;
    notifyListeners();
  }

}