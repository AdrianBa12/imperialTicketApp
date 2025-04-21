import 'package:flutter/material.dart';
import 'package:imperialticketapp/providers/ticket_provider.dart';

import 'package:provider/provider.dart';


class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});
  
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
  
}

  class _PaymentScreenState extends State<PaymentScreen> {
    @override
    Widget build(BuildContext context) {
    final provider = Provider.of<TicketProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Método de Pago')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Seleccione método de pago:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            _buildPaymentOption('Tarjeta de Crédito', 'credit_card', provider),
            _buildPaymentOption('PayPal', 'paypal', provider),
            _buildPaymentOption('Transferencia Bancaria', 'bank_transfer', provider),
            const Spacer(),
            ElevatedButton(
              onPressed: provider.paymentMethod.isNotEmpty
                  ? () => _completePurchase(context)
                  : null,
              child: const Text('Confirmar Compra'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String method, String icon, TicketProvider provider) {
    return Card(
      child: ListTile(
        leading: Icon(_getIcon(icon)),
        title: Text(method),
        trailing: Radio<String>(
          value: method,
          groupValue: provider.paymentMethod,
          onChanged: (value) => provider.setPaymentMethod(value ?? ''),
        ),
        onTap: () => provider.setPaymentMethod(method),
      ),
    );
  }

  IconData _getIcon(String icon) {
    switch (icon) {
      case 'credit_card': return Icons.credit_card;
      case 'paypal': return Icons.payment;
      case 'bank_transfer': return Icons.account_balance;
      default: return Icons.payment;
    }
  }

  void _completePurchase(BuildContext context) {
    final provider = Provider.of<TicketProvider>(context, listen: false);
     
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Compra Exitosa'),
        content: const Text('Su boleto ha sido reservado exitosamente.'),
        actions: [
          TextButton(
            onPressed: () {
              provider.reset();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}