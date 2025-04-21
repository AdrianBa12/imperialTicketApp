import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';

class PaymentService {
  static const String _baseUrl = 'http://192.168.101.5:5000/api';
  static const String _secretKey =
      "sk_test_51OqTwwJ5bCJjLaWJ2maitwEt6xrNDJefHFWiTMEvya4M4kSWPkXwkxR1H1zw8iCefeezKgkHeu9dm9n8ZgPEvexD00WEkNvagk";
  static String? _authToken;

  static Future<void> initialize() async {
    Stripe.publishableKey =
        'pk_test_51OqTwwJ5bCJjLaWJRYviZMsKdA0ArSX6TH6NZ8TxaQiWey6TKzJdgXZrKtW9FqDBuLvx8PYVmLMoEdu9iNYEbXuf009soPlNub';
    await Stripe.instance.applySettings();
  }

  static Future<Map<String, dynamic>> completePayment({
    required BuildContext context,
    required double amount,
    required String currency,
  }) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);

      if (authProvider.userModel?.email == null) {
        throw Exception('User email is required');
      }

      if (bookingProvider.bookingId == null) {
        throw Exception('Booking ID is missing');
      }

      final paymentIntent = await _createPaymentIntent(
        amount: amount,
        currency: currency,
        bookingId: bookingProvider.bookingId!,
        email: authProvider.userModel!.email,
        name: authProvider.userModel!.username ,
      );

      await _presentPaymentSheet(
        clientSecret: paymentIntent['clientSecret'],
        bookingId: bookingProvider.bookingId!,
      );


      return {
        'status': 'succeeded',
        'paymentId': paymentIntent['paymentIntentId'],
      };
    } catch (e) {
      debugPrint('Payment error: $e');
      rethrow;
    }
  }

  static void updateAuthToken(String token) {
    _authToken = token;
  }

  static Future<void> completePaymentWithSheet({
    required BuildContext context,
    required double amount,
    required String currency,
    required String bookingId,
    required String email,
    required String name,
  }) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.userModel == null) {
        throw Exception("Debes iniciar sesión antes de realizar un pago");
      }

      final paymentIntent = await _createPaymentIntent(
        amount: amount,
        currency: currency,
        bookingId: bookingId,
        email: authProvider.userModel!.email,
        name: authProvider.userModel!.username ,
      );

      await _presentPaymentSheet(
        clientSecret: paymentIntent['clientSecret'],
        bookingId: bookingId,
      );

      await _confirmPayment(
        paymentIntentId: paymentIntent['paymentIntentId'],
        bookingId: bookingId,
      );
    } catch (e) {
      debugPrint('Error en el proceso de pago: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> _createPaymentIntent({
    required double amount,
    required String currency,
    required String bookingId,
    required String email,
    required String name,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/payments/create-payment-intent'),
        headers: _buildHeaders(),
        body: json.encode({
          'amount': (amount * 100).round(),
          'currency': currency.toLowerCase(),
          'bookingId': bookingId,
          'email': email,
          'name': name,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode != 200) {
        throw Exception(responseData['error'] ?? 'Error al crear PaymentIntent');
      }

      return {
        'clientSecret': responseData['clientSecret'],
        'paymentIntentId': responseData['paymentIntentId'],
      };
    } catch (e) {
      debugPrint('Error en _createPaymentIntent: $e');
      rethrow;
    }
  }

  static Future<void> _presentPaymentSheet({
    required String clientSecret,
    required String bookingId,
  }) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'TurismoImperial',
          customerId: 'cus_$bookingId',
          style: ThemeMode.light,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Colors.blue.shade500,
            ),
          ),
        ),
      );

      await Stripe.instance.presentPaymentSheet();
    } on StripeException catch (e) {
      throw Exception('Payment failed: ${e.error.localizedMessage}');
    }
  }

  static Future<void> _confirmPayment({
    required String paymentIntentId,
    required String bookingId,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/payments/confirm'),
      headers: _buildHeaders(),
      body: json.encode({
        'paymentIntentId': paymentIntentId,
        'bookingId': bookingId,
      }),
    );
    _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getPaymentStatus(
    String paymentIntentId,
  ) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/payments/status/$paymentIntentId'),
      headers: _buildHeaders(),
    );
    return _handleResponse(response);
  }

  static Map<String, String> _buildHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_authToken',
    };
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final responseData = json.decode(response.body);
    if (response.statusCode != 200) {
      throw Exception(responseData['error'] ?? 'Error en la solicitud');
    }
    return responseData;
  }

  Future<Map<String, dynamic>> createPaymentIntent({
    required BuildContext context,
    required double amount,
    required String currency,
    required String bookingId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': (amount * 100).toInt().toString(), 
          'currency': currency,
          'payment_method_types[]': 'card',
        },
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'clientSecret': responseData['client_secret'],
          'paymentIntentId': responseData['id'],
        };
      } else {
        return {
          'success': false,
          'error': responseData['error']['message'] ?? 'Error en el pago',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<void> registerPayment(
      String bookingId, double amount, String status) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/payments'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'bookingId': bookingId,
        'amount': amount,
        'status': status,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Error al registrar el pago en la base de datos");
    }
  }

  Future<bool> confirmPayment({
    required BuildContext context,
    required String paymentIntentId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/$paymentIntentId/confirm"),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      final responseData = jsonDecode(response.body);
      return response.statusCode == 200 && responseData['status'] == 'succeeded';
    } catch (e) {
      return false;
    }
  }

  static Future<void> verifyPaymentSuccess(String paymentIntentId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/payments/verify/$paymentIntentId'),
      headers: _buildHeaders(),
    );

    final result = json.decode(response.body);
    if (result['status'] != 'succeeded') {
      throw Exception('El pago no fue completado');
    }
  }

  static Future<Map<String, dynamic>> verifyPayment(String paymentIntentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/payments/verify/$paymentIntentId'),
        headers: _buildHeaders(),
      );

      final data = json.decode(response.body);

      if (response.statusCode != 200) {
        throw Exception(data['error'] ?? 'Verification failed');
      }
      return data['data']; 
    } catch (e) {
      debugPrint('Payment verification error: $e');
      rethrow;
    }
  }
}