import 'package:flutter/material.dart';
import '../models/seat.dart';

class BusSeatLayout extends StatelessWidget {
  final List<Seat> seats;
  final List<Seat> selectedSeats;
  final Function(Seat) onSeatSelected;
  final int rowsFirstFloor;
  final int rowsSecondFloor;
  final int cols;

  const BusSeatLayout({
    super.key,
    required this.seats,
    required this.selectedSeats,
    required this.onSeatSelected,
    this.rowsFirstFloor = 4,
    this.rowsSecondFloor = 6,
    this.cols = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Título del Bus
        _buildBusFront(),

        // Primer piso
        _buildFloor(context, 'Primer Piso', 0, rowsFirstFloor),

        // Escalera simulada
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.stairs, size: 16), // Icono de escaleras
              SizedBox(width: 8),
              Text(
                'Escalera al segundo piso',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),

        // Segundo piso
        _buildFloor(context, 'Segundo Piso', rowsFirstFloor * cols, rowsSecondFloor),

        // Espacio
        const SizedBox(height: 24),

        // Leyenda de colores
        _buildLegend(context),
      ],
    );
  }

  // Widget para mostrar la cabecera del bus
  Widget _buildBusFront() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade800,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.directions_bus, color: Colors.white, size: 30),
          const SizedBox(width: 8),
          Text(
            'FRENTE DEL BUS',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // Widget para representar cada piso del bus
  Widget _buildFloor(BuildContext context, String title, int startIndex, int numRows) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: List.generate(numRows, (row) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Asientos del lado izquierdo
                    ...List.generate(cols ~/ 2, (col) {
                      final seatIndex = startIndex + row * cols + col;
                      return _buildSeat(context, seatIndex);
                    }),

                    // Pasillo
                    const SizedBox(width: 24),

                    // Asientos del lado derecho
                    ...List.generate(cols ~/ 2, (col) {
                      final seatIndex = startIndex + row * cols + col + (cols ~/ 2);
                      return _buildSeat(context, seatIndex);
                    }),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // Widget para construir un asiento individual
  Widget _buildSeat(BuildContext context, int index) {
    if (index >= seats.length) {
      return const SizedBox(width: 40, height: 40);
    }

    final seat = seats[index];
    final isSelected = selectedSeats.any((s) => s.id == seat.id);

    Color seatColor = seat.isBooked
        ? Colors.grey.shade400
        : isSelected
        ? Theme.of(context).colorScheme.primary
        : Colors.white;

    return GestureDetector(
      onTap: seat.isBooked ? null : () => onSeatSelected(seat),
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: seat.isBooked
                ? Colors.grey.shade400
                : Theme.of(context).colorScheme.primary,
          ),
        ),
        child: Center(
          child: Text(
            seat.number,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected || seat.isBooked
                  ? Colors.white
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  // Widget para la leyenda de colores
  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem(context, 'Disponible', Colors.white),
        _buildLegendItem(context, 'Seleccionado', Theme.of(context).colorScheme.primary),
        _buildLegendItem(context, 'Reservado', Colors.grey.shade400),
      ],
    );
  }

  // Widget para cada elemento de la leyenda
  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Theme.of(context).colorScheme.primary),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}