import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:imperialticketapp/services/secure_service.dart';
import '../models/bus.dart';
import '../models/route.dart';
import '../models/booking.dart';
import '../models/seat.dart';
import '../models/ticket.dart';

class ApiService {

  static const baseUrl = 'http://192.168.101.5:5000/api';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> signInWithEmailAndPassword(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final token = await _getJwtTokenFromBackend(userCredential.user!.uid);
    await SecureStorage.storeToken(token); 
    return token;
  }

  Future<String> _getJwtTokenFromBackend(String uid) async {
    final response = await http.post(
      Uri.parse('https://192.168.101.5:5000/api/generate-token'),
      body: json.encode({'uid': uid}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['token'];
    } else {
      throw Exception('Failed to get JWT token');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      if (kDebugMode) {
        print('Error al cerrar sesión: $e');
      }
      rethrow;
    }
  }

  Future<List<Seat>> getSeats(String id) async {
      final response = await http.get(
        Uri.parse('$baseUrl/buses/$id/seats'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data["seats"];
      } else {
        throw Exception('Error al obtener los asientos');
      }

  }

  Future<List<BusRoute>> getRoutes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/routes'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> routesData = json.decode(response.body)['routes'];
        return routesData.map((json) => BusRoute.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load routes');
      }
    } catch (e) {
      debugPrint('Error fetching routes: ${e.toString()}');
      return [];
    }
  }

  Future<List<Bus>> searchBuses(String fromCity, String toCity, String date) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/buses/search?from=$fromCity&to=$toCity&date=$date'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> busesData = json.decode(response.body)['buses'];
        return busesData.map((json) => Bus.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search buses');
      }
    } catch (e) {
      debugPrint('Error searching buses: ${e.toString()}');
      return [];
    }
  }

  Future<Bus?> getBusDetails(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/buses/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final busData = json.decode(response.body)['bus'];
        return Bus.fromJson(busData);
      } else {
        throw Exception('Failed to get bus details');
      }
    } catch (e) {
      debugPrint('Error fetching bus details: ${e.toString()}');
      return null;
    }
  }

  Future<Map<String, dynamic>> createBooking(String authToken, Booking booking) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode(booking.toJson()),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'booking': Booking.fromJson(responseData['booking']),
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to create booking',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  Future<List<Ticket>> fetchUserBookings(String authToken) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['bookings'];
        return data.map((json) => Ticket.fromJson(json)).toList();
      } else {
        final error = json.decode(response.body)['message'] ?? 'Failed to fetch bookings';
        throw Exception(error);
      }
    } catch (e) {
      throw Exception('Failed to fetch bookings: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> checkAvailableSeats(String busId, String date) async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.101.5:5000/api/buses/$busId?date=$date'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<Booking?> getBookingDetails(String authToken, String bookingId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/$bookingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final bookingData = json.decode(response.body)['booking'];
        return Booking.fromJson(bookingData);
      } else {
        throw Exception('Failed to get booking details');
      }
    } catch (e) {
      debugPrint('Error fetching booking details: ${e.toString()}');
      return null;
    }
  }

  Future<void> cancelBooking(String authToken, String bookingId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/bookings/$bookingId/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body)['message'] ?? 'Failed to cancel booking';
        throw Exception(error);
      }
    } catch (e) {
      throw Exception('Failed to cancel booking: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> createPaymentIntent(
      String authToken,
      double amount,
      String currency,
      String bookingId,
      ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payments/create-payment-intent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'amount': (amount * 100).toInt(), 
          'currency': currency,
          'bookingId': bookingId,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'clientSecret': responseData['clientSecret'],
          'ephemeralKey': responseData['ephemeralKey'],
          'customerId': responseData['customer'],
          'publishableKey': responseData['publishableKey'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to create payment intent',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  Future<bool> checkServerStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/status'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error checking server status: ${e.toString()}');
      return false;
    }
  }

}
