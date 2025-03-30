import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import '../models/seat.dart';
import '../widgets/bus_seat_layout.dart';
import '../services/socket_service.dart';
import '../services/api_service.dart';

class SeatSelectionScreen extends StatefulWidget {
  const SeatSelectionScreen({super.key});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  bool _isLoading = true;
  List<Seat> _seats = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSeats();
    _setupSocketListeners();
  }

  @override
  void dispose() {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    final bus = provider.selectedBus;

    if (bus != null && provider.selectedSeats.isNotEmpty) {
      SocketService.releaseSeats(
        bus.id,
        provider.journeyDate!,
        provider.selectedSeats.map((s) => s.number).toList(),
      );
    }
    SocketService.removeAllListeners();
    super.dispose();
  }


  List<dynamic> _extractSeatsFromResponse(Map<String, dynamic> response) {
    const possiblePaths = [
      ['bus', 'seats'],
      ['data', 'bus', 'seats'],
      ['seats'],
      ['items']
    ];

    for (final path in possiblePaths) {
      dynamic current = response;
      bool pathValid = true;

      for (final key in path) {
        if (current is Map && current.containsKey(key)) {
          current = current[key];
        } else {
          pathValid = false;
          break;
        }
      }

      if (pathValid && current is List) {
        debugPrint('Asientos encontrados en el camino.: ${path.join(' > ')}');
        return current;
      }
    }

    debugPrint('No se encontraron asientos en la respuesta. Llaves disponibles: ${response.keys.join(', ')}');
    return [];
  }

  Future<void> _fetchSeats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = Provider.of<BookingProvider>(context, listen: false);
      final bus = provider.selectedBus;

      if (bus == null || provider.journeyDate == null) {
        throw Exception('Fecha de autobús o viaje no seleccionada');
      }

      final response = await ApiService.checkAvailableSeats(
          bus.id,
          provider.journeyDate!.toIso8601String()
      );

      final seatsData = _extractSeatsFromResponse(response);

      if (seatsData.isEmpty) {
        throw Exception('No se encontraron datos de asientos en la respuesta');
      }

      if (response['bus'] == null) {
        throw Exception('Bus data is missing in response');
      }

      if (response['bus']['seats'] == null) {
        throw Exception('Seats data is missing in bus object');
      }

      if (response['bus']['seats'] is! List) {
        throw Exception('Seats data is not a list');
      }

      final seats = (response['bus']['seats'] as List).map((seatJson) {
        try {
          return Seat.fromJson(seatJson);
        } catch (e) {
          debugPrint('Error al analizar el asiento: $seatJson');
          throw Exception('Formato de asiento no válido: ${e.toString()}');
        }
      }).toList();

      setState(() {
        _seats = seats;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar los asientos: ${e.toString().replaceAll('Exception: ', '')}';
        _isLoading = false;
      });
    }
  }

  void _setupSocketListeners() {
    SocketService.onSeatsSelected((seats, userId) {
      setState(() {
        for (final seatNumber in seats) {
          final seatIndex = _seats.indexWhere((s) => s.number == seatNumber);
          if (seatIndex != -1) {
            _seats[seatIndex] = _seats[seatIndex].copyWith(

              isSelected: false,
              isTemporarilyHeld: true,
              heldByUserId: userId,
            );
          }
        }
      });
    });

    SocketService.onSeatsReleased((seats, userId) {
      setState(() {
        for (final seatNumber in seats) {
          final seatIndex = _seats.indexWhere((s) => s.number == seatNumber);
          if (seatIndex != -1 && _seats[seatIndex].heldByUserId == userId) {
            _seats[seatIndex] = _seats[seatIndex].copyWith(

              isSelected: false,
              isTemporarilyHeld: false,
              heldByUserId: null,
            );
          }
        }
      });
    });

    SocketService.onBookingConfirmed((seats) {
      setState(() {
        for (final seatNumber in seats) {
          final seatIndex = _seats.indexWhere((s) => s.number == seatNumber);
          if (seatIndex != -1) {
            _seats[seatIndex] = _seats[seatIndex].copyWith(

              isSelected: false,
            );
          }
        }
      });
    });
  }

  void _toggleSeatSelection(Seat seat) {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    final bus = provider.selectedBus;

    if (bus == null || provider.journeyDate == null) {
      return;
    }

    if (seat.isAvailable) {
      final isSelected = provider.selectedSeats.contains(seat);

      if (isSelected) {
        provider.toggleSeatSelection(seat);
        SocketService.releaseSeats(bus.id, provider.journeyDate!, [seat.number]);
      } else {
        provider.toggleSeatSelection(seat);
        SocketService.selectSeats(bus.id, provider.journeyDate!, [seat.number]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context);
    final bus = provider.selectedBus;
    final selectedSeats = provider.selectedSeats;

    if (bus == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Seleccionar Asientos'),
        ),
        body: const Center(
          child: Text('Ningún autobús seleccionado'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Asientos'),
      ),
      body: Column(
        children: [
          // Bus details header
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primary,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bus.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bus.busType,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha:0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${bus.fare.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'por asiento',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha:0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.fromCity ?? 'Desde',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha:0.8),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bus.departureTime,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white.withValues(alpha:08),
                          size: 16,
                        ),
                        Text(
                          '${bus.duration} mins',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha:0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            provider.toCity ?? 'Hasta',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha:0.8),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.right,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bus.arrivalTime,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Seat selection instructions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seleccionar Asientos',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Toque los asientos disponibles para seleccionarlos.',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildSeatLegend('Disponible', Colors.white, Colors.grey),
                    const SizedBox(width: 16),
                    _buildSeatLegend('Seleccionado', Theme.of(context).colorScheme.primary, Colors.white),
                    const SizedBox(width: 16),
                    _buildSeatLegend('Reservado', Colors.grey.shade300, Colors.grey),
                  ],
                ),
              ],
            ),
          ),

          // Seat layout
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No se pudieron cargar los asientos: $_error',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchSeats,
                    child: const Text('RELOAD'),
                  ),
                ],
              ),
            )
                : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: BusSeatLayout(
                  seats: _seats,
                  selectedSeats: selectedSeats,
                  onSeatSelected: _toggleSeatSelection,
                ),
              ),
            ),
          ),

          // Bottom bar with selected seats and continue button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedSeats.isEmpty
                            ? 'No hay asientos seleccionados'
                            : '${selectedSeats.length} ${selectedSeats.length == 1 ? 'seat' : 'seats'} selected',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (selectedSeats.isNotEmpty)
                        Text(
                          selectedSeats.map((s) => s.number).join(', '),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      if (selectedSeats.isNotEmpty)
                        Text(
                          'Total: S/${(bus.fare * selectedSeats.length).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: selectedSeats.isEmpty
                      ? null
                      : () {
                    Navigator.pushNamed(context, '/booking');
                  },
                  child: const Text('CONTINUAR'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatLegend(String label, Color color, Color borderColor) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}



