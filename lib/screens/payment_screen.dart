import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material;
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../services/payment_service.dart';

class PaymentScreenState extends StatefulWidget {
  const PaymentScreenState({super.key});

  @override
  State<PaymentScreenState> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreenState> {
  String? _errorMessage;
  int _selectedPaymentMethod = 0;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'title': 'Credito/Tarjeta Devito',
      'subtitle': 'Pague de forma segura con su tarjeta',
      'icon': Icons.credit_card,
    },
    {
      'title': 'GPAY',
      'subtitle': 'Pague usando cualquier aplicación GPAY',
      'icon': Icons.account_balance,
    },
    {
      'title': 'Banca neta',
      'subtitle': 'Pagar usando su cuenta bancaria',
      'icon': Icons.account_balance_wallet,
    },
    {
      'title': 'Wallet',
      'subtitle': 'Pay using digital wallets',
      'icon': Icons.wallet,
    },
  ];

  Future<void> _handlePayment() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);

      if (bookingProvider.selectedSeats.isEmpty) {
        throw Exception('Seleccione al menos un asiento');
      }
      if (!authProvider.isAuthenticated) {
        throw Exception('Autenticación requerida');
      }
      if (bookingProvider.bookingId == null) {
        throw Exception('ID de reserva no encontrado');
      }
      if (authProvider.userModel?.email == null) {
        throw Exception('Email de usuario no registrado');
      }

      if (bookingProvider.totalPrice == 0) {
        bookingProvider.calculateTotal();
      }

      await PaymentService.completePaymentWithSheet(
        context: context,
        amount: bookingProvider.totalPrice,
        currency: 'PEN',
        bookingId: bookingProvider.bookingId!,
        email: authProvider.userModel!.email,
        // name: authProvider.userModel!.username ?? bookingProvider.passengerName ?? 'Cliente',
        name: authProvider.userModel!.username,
      );

      if (mounted) Navigator.pushNamed(context, '/ticket');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSuccessfulPayment(
    BookingProvider booking,
    Map<String, dynamic> result,
  ) async {
    await PaymentService.verifyPayment(result['paymentIntentId']);

    booking.clearSelection();

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/payment-success',
      (route) => false,
      arguments: {
        'bookingId': booking.bookingId,
        'amount': booking.totalPrice,
        'paymentId': result['paymentIntentId'],
        'receiptUrl': result['receiptUrl'],
      },
    );
  }

  void _handlePaymentFailure(dynamic error) {
    debugPrint('Error en el pago: $error');
    if (!mounted) return;

    setState(() {
      _errorMessage = error.toString().replaceAll('Exception: ', '');
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $_errorMessage'),
        duration: Duration(seconds: 5),
      ),
    );
  }

  void _resetLoadingState() {
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final bus = bookingProvider.selectedBus;
    final selectedSeats = bookingProvider.selectedSeats;

    if (bus == null || selectedSeats.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Payment'),
        ),
        body: const Center(
          child: Text('No hay información de reserva disponible'),
        ),
      );
    }

    final baseAmount = bus.fare * selectedSeats.length;
    final serviceFee = baseAmount * 0.05;
    final gst = baseAmount * 0.18;
    final discountAmount = bookingProvider.discount ?? 0.0;
    final price = baseAmount + serviceFee + gst - discountAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Booking summary card
                  material.Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Resumen de Reserva',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          
                          // ... (resto del código del resumen de la reserva)
                          // ... (resto de los widgets)
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Metodos de Pago',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  material.Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: List.generate(
                          _paymentMethods.length,
                          (index) => RadioListTile(
                            title: Text(
                              _paymentMethods[index]['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(_paymentMethods[index]['subtitle']),
                            secondary: Icon(_paymentMethods[index]['icon']),
                            value: index,
                            groupValue: _selectedPaymentMethod,
                            onChanged: (value) {
                              setState(() {
                                _selectedPaymentMethod = value as int;
                              });
                            },
                            activeColor: Theme.of(context).colorScheme.primary,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade700,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handlePayment,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _isLoading
                            ? Colors.grey
                            : Theme.of(context).colorScheme.primary,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'PAGAR S/${price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pago seguro con tecnología de Stripe',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}


