import 'package:flutter/material.dart';
import '../models/seat.dart';

class SeatLayout extends StatelessWidget {
  final List<Seat> seats;
  final List<Seat> selectedSeats;
  final Function(Seat) onSeatTap;
  final int columns;
  final int aisleAfterColumn;

  const SeatLayout({
    super.key,
    required this.seats,
    required this.selectedSeats,
    required this.onSeatTap,
    this.columns = 4,
    this.aisleAfterColumn = 1,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate number of rows
    final int totalRows = (seats.length / columns).ceil();

    return Column(
      children: [
        // Bus front indicator
        Container(
          width: 120,
          height: 40,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: const Center(
            child: Text(
              'FRENTE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
        ),

        // Seat grid
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: List.generate(totalRows, (rowIndex) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _buildSeatRow(rowIndex, context),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSeatRow(int rowIndex, BuildContext context) {
    final List<Widget> rowWidgets = [];

    for (int colIndex = 0; colIndex < columns; colIndex++) {
      final int seatIndex = rowIndex * columns + colIndex;

      // Add aisle space
      if (colIndex == aisleAfterColumn) {
        rowWidgets.add(const SizedBox(width: 24));
      }

      // Add seat or empty space if we've run out of seats
      if (seatIndex < seats.length) {
        rowWidgets.add(_buildSeat(seats[seatIndex], context));
      } else {
        rowWidgets.add(const SizedBox(width: 40, height: 40));
      }

      // Add spacing between seats
      if (colIndex < columns - 1 && colIndex != aisleAfterColumn) {
        rowWidgets.add(const SizedBox(width: 8));
      }
    }

    return rowWidgets;
  }

  Widget _buildSeat(Seat seat, BuildContext context) {
    final bool isSelected = selectedSeats.any((s) => s.id == seat.id);

    // Determine seat color based on status
    Color seatColor;
    Color borderColor;

    if (seat.isBooked) {
      seatColor = Colors.grey.shade300;
      borderColor = Colors.grey.shade400;
    } else if (isSelected) {
      seatColor = Theme.of(context).colorScheme.primary;
      borderColor = Theme.of(context).colorScheme.primary;
    } else if (seat.isTemporarilyHeld) {
      seatColor = Colors.orange.shade100;
      borderColor = Colors.orange;
    } else {
      seatColor = Colors.white;
      borderColor = Colors.grey;
    }

    // Determine text color
    Color textColor = isSelected ? Colors.white : Colors.black;
    if (seat.isBooked) textColor = Colors.grey.shade700;

    return GestureDetector(
      onTap: () => onSeatTap(seat),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                seat.number,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            if (seat.seatType == 'window')
              Positioned(
                top: 2,
                right: 2,
                child: Icon(
                  Icons.window,
                  size: 10,
                  color: textColor.withValues(alpha:0.7),
                ),
              ),
            if (seat.seatType == 'aisle')
              Positioned(
                top: 2,
                right: 2,
                child: Icon(
                  Icons.airline_seat_recline_normal,
                  size: 10,
                  color: textColor.withValues(alpha:0.7),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

