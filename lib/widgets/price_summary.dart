import 'package:flutter/material.dart';

class PriceSummary extends StatelessWidget {
  final double priceWithTax; // Precio final CON IGV incluido
  final int seatCount;
  final double serviceFee;
  final double discount;
  final bool showDetails;

  const PriceSummary({
    super.key,
    required this.priceWithTax, // Ahora recibe el precio con impuestos
    required this.seatCount,
    required this.serviceFee,
    this.discount = 0.0,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    // Calcula el desglose
    final subtotal = priceWithTax / 1.18; // Remueve el IGV para mostrar el desglose
    final tax = priceWithTax - subtotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detalles del precio',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildPriceRow(
          label: 'Subtotal ($seatCount asientos)',
          value: subtotal,
        ),
        if (discount > 0) ...[
          const SizedBox(height: 8),
          _buildPriceRow(
            label: 'Descuento',
            value: -discount,
          ),
        ],
        if (showDetails) ...[
          const SizedBox(height: 8),
          _buildPriceRow(
            label: 'Tarifa de servicio (5%)',
            value: serviceFee,
          ),
          const SizedBox(height: 8),
          _buildPriceRow(
            label: 'IGV (18%)',
            value: tax,
          ),
        ],
        const Divider(height: 24),
        _buildPriceRow(
          label: 'Total a pagar (IGV incluido)',
          value: priceWithTax - discount,
          isTotal: true,
        ),
      ],
    );
  }

  Widget _buildPriceRow({
    required String label,
    required double value,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          'S/${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: value < 0 ? Colors.red : Colors.black,
          ),
        ),
      ],
    );
  }
}