import 'dart:async';
import 'package:flutter/foundation.dart';

class PaymentService {

  Future<PaymentResult> processPayment({
    required double amount,
    required PaymentMethod method,
    required Map<String, dynamic> reservationData,
  }) async {
    try {
      _validatePaymentData(amount, method, reservationData);

      debugPrint('Iniciando procesamiento de pago...');
      await _simulatePaymentProcessing();
      
      final transactionId = _generateTransactionId();
      
      debugPrint('Pago procesado exitosamente. ID: $transactionId');
      return PaymentResult.success(
        transactionId: transactionId,
        amount: amount,
        method: method,
      );
      
    } on PaymentException catch (e) {
      debugPrint('Error en pago: ${e.message}');
      return PaymentResult.failure(error: e.message);
    } catch (e) {
      debugPrint('Error desconocido: $e');
      return PaymentResult.failure(
        error: 'Error desconocido al procesar el pago',
      );
    }
  }

  void _validatePaymentData(
    double amount, 
    PaymentMethod method, 
    Map<String, dynamic> data
  ) {
    if (amount <= 0) throw PaymentException('Monto inválido');
    if (!data.containsKey('reservationId')) {
      throw PaymentException('Datos de reserva incompletos');
    }
  }

  Future<void> _simulatePaymentProcessing() async {
    await Future.delayed(const Duration(seconds: 2));
    if (kDebugMode && DateTime.now().second % 10 == 0) {
      throw PaymentException('Falló la conexión con la pasarela de pago');
    }
  }

  String _generateTransactionId() {
    return 'TXN-${DateTime.now().millisecondsSinceEpoch}';
  }
}

enum PaymentMethod {
  creditCard,
  debitCard,
  cash,
  bankTransfer,
  other,
}

class PaymentResult {
  final bool success;
  final String? transactionId;
  final double? amount;
  final PaymentMethod? method;
  final String? error;

  PaymentResult._({
    required this.success,
    this.transactionId,
    this.amount,
    this.method,
    this.error,
  });

  factory PaymentResult.success({
    required String transactionId,
    required double amount,
    required PaymentMethod method,
  }) => PaymentResult._(
    success: true,
    transactionId: transactionId,
    amount: amount,
    method: method,
  );

  factory PaymentResult.failure({
    required String error,
  }) => PaymentResult._(
    success: false,
    error: error,
  );
}

class PaymentException implements Exception {
  final String message;
  PaymentException(this.message);
}