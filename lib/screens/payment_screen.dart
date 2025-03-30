import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material;
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../services/payment_service.dart';



class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
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
      if (authProvider.firebaseUser?.email == null) {
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
        email: authProvider.firebaseUser!.email!,
        name: authProvider.firebaseUser!.displayName ?? bookingProvider.passengerName ?? 'Cliente',
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

  Future<void> _processPayment(
      AuthProvider auth,
      BookingProvider booking
      ) async {
    return await PaymentService.completePaymentWithSheet(
      context: context,
      amount: booking.totalPrice,
      currency: 'PEN',
      bookingId: booking.bookingId!,
      email: auth.firebaseUser!.email!,
      name: auth.firebaseUser!.displayName ??
          booking.passengerName ?? 'Cliente',
    );
  }

  Future<void> _handleSuccessfulPayment(
      BookingProvider booking,
      Map<String, dynamic> result
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
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bookingProvider.fromCity ?? 'Desde',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                bus.departureTime,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                bookingProvider.toCity ?? 'Hasta',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.right,
                              ),
                              Text(
                                bus.arrivalTime,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bus',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                bus.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Asientos',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                selectedSeats.map((s) => s.number).join(', '),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pasajero',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                bookingProvider.passengerName ?? 'No proporcionado',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Contacto',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                bookingProvider.passengerPhone ?? 'No proporcionado',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),



            const SizedBox(height: 24),

            // Payment methods
            Text(
              'Metodos de Pago',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Payment method selection
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

            // Error message if any
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

            // Secure payment note
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



