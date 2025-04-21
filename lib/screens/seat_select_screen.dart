import 'package:flutter/material.dart';
import 'package:imperialticketapp/providers/ticket_provider.dart';
import 'package:provider/provider.dart';

class SeatSelectionScreen extends StatefulWidget {
  const SeatSelectionScreen({super.key});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  int? _selectedSeat;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TicketProvider>(context);
    final selectedBus = Provider.of<TicketProvider>(context).selectedBus;

    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar Asiento')),

      body: Column(
        children: [
          if (selectedBus != null) ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Bus: ${selectedBus['idBus']} - Precio: \$${selectedBus['precio']}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),

              itemBuilder: (ctx, index) {
                final seatNumber = index + 1;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSeat = seatNumber;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          _selectedSeat == seatNumber
                              ? Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.3)
                              : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            _selectedSeat == seatNumber
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$seatNumber',
                        style: TextStyle(
                          color:
                              _selectedSeat == seatNumber
                                  ? Theme.of(context).primaryColor
                                  : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed:
                  _selectedSeat != null
                      ? () {
                        provider.selectSeat(_selectedSeat!);
                        Navigator.pushNamed(context, '/passenger-info');
                      }
                      : null,
              child: const Text('Continuar'),
            ),
          ),
        ],
      ),
    );
  }
}
