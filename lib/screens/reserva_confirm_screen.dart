import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';

class ReservaConfirmadaScreen extends StatelessWidget {
  final String qrData;
  final Map<String, dynamic> reservaDetails;

  const ReservaConfirmadaScreen({super.key, required this.qrData, required this.reservaDetails});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reserva Confirmada'),
        automaticallyImplyLeading: false, 
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                '¡Su reserva ha sido confirmada!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200.0,
              ),
              const SizedBox(height: 20),
              const Text(
                'Presente este código QR al abordar.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              const Text(
                'Detalles de su Reserva:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              _buildDetailRow('Código de Reserva', reservaDetails['codigo_reserva']),
              _buildDetailRow('Origen', reservaDetails['origen']),
              _buildDetailRow('Destino', reservaDetails['destino']),
              _buildDetailRow('Fecha de Salida', DateFormat('EEEE dd MMMM - HH:mm', 'es').format(DateTime.parse(reservaDetails['fecha_salida']))),
              _buildDetailRow('Bus', reservaDetails['bus'] ?? 'No especificado'),
              const SizedBox(height: 10),
              const Text('Pasajeros:', style: TextStyle(fontWeight: FontWeight.bold)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (reservaDetails['pasajeros'] as List<dynamic>).map((pasajero) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text('- ${pasajero['nombre']} (Asiento ${pasajero['asiento']}, ${pasajero['documento']})'),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              _buildDetailRow('Total Pagado', 'S/. ${reservaDetails['total_pagado']}', isBold: true),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, ModalRoute.withName('/')); 
                },
                child: const Text('Volver al Inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value),
        ],
      ),
    );
  }
}