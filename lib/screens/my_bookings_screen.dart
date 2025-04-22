import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../models/ticket.dart';
import '../services/api_service.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Ticket> _upcomingBookings = [];
  List<Ticket> _pastBookings = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken; // Changed from token to authToken

      if (token == null) {
        setState(() {
          _error = 'Necesita iniciar sesión para ver las reservas';
          _isLoading = false;
        });
        return;
      }

      final apiService = ApiService();
      final bookings = await apiService.fetchUserBookings(token);

      final now = DateTime.now();
      final upcoming = <Ticket>[];
      final past = <Ticket>[];

      for (final booking in bookings) {
        if (booking.journeyDate.isAfter(now)) {
          upcoming.add(booking);
        } else {
          past.add(booking);
        }
      }

      // Sort upcoming bookings by journey date (ascending)
      upcoming.sort((a, b) => a.journeyDate.compareTo(b.journeyDate));

      // Sort past bookings by journey date (descending)
      past.sort((a, b) => b.journeyDate.compareTo(a.journeyDate));

      setState(() {
        _upcomingBookings = upcoming;
        _pastBookings = past;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar las reservas: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelBooking(Ticket ticket) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Necesita iniciar sesión para cancelar reservas.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancelar Reserva'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('¿Estás seguro de que deseas cancelar esta reserva?'),
              const SizedBox(height: 16),
              Text(
                'CPolítica de cancelación:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              _buildCancellationPolicy(ticket),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('NO'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('SI, CANCELAR'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Cancelar Reserva...'),
            ],
          ),
        ),
      );

      final apiService = ApiService();
      await apiService.cancelBooking(token, ticket.id);

      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reserva cancelada con éxito'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );

      _fetchBookings();
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo cancelar la reserva: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildCancellationPolicy(Ticket ticket) {
    final journeyDate = ticket.journeyDate;
    final now = DateTime.now();
    final difference = journeyDate.difference(now).inHours;

    double refundPercentage;
    if (difference > 72) {
      refundPercentage = 90; 
    } else if (difference > 48) {
      refundPercentage = 75; 
    } else if (difference > 24) {
      refundPercentage = 50; 
    } else if (difference > 12) {
      refundPercentage = 25; 
    } else {
      refundPercentage = 0; 
    }

    final refundAmount = ticket.totalWithTax * (refundPercentage / 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• ${refundPercentage.toInt()}% reembolso (S/${refundAmount.toStringAsFixed(2)})'),
        const Text('• El reembolso se procesará dentro de 5 a 7 días hábiles.'),
        const Text('• El reembolso se acreditará al método de pago original.'),


      ],
    );
  }

  void _viewTicket(Ticket ticket) {
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    bookingProvider.setBooking(ticket);
    Navigator.pushNamed(context, '/ticket');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Reservas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'PRÓXIMO'),
            Tab(text: 'PASADO'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchBookings,
              child: const Text('RELOAD'),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchBookings,
        child: TabBarView(
          controller: _tabController,
          children: [
            // Upcoming bookings tab
            _upcomingBookings.isEmpty
                ? _buildEmptyState('No hay reservas próximas')
                : _buildBookingsList(_upcomingBookings, isUpcoming: true),

            // Past bookings tab
            _pastBookings.isEmpty
                ? _buildEmptyState('No hay reservas pasadas')
                : _buildBookingsList(_pastBookings, isUpcoming: false),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_bus_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/search'),
            child: const Text('RESERVAR UN BILLETE'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList(List<Ticket> bookings, {required bool isUpcoming}) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final ticket = bookings[index];
        return _buildBookingCard(ticket, isUpcoming);
      },
    );
  }

  Widget _buildBookingCard(Ticket ticket, bool isUpcoming) {
    final journeyDate = DateFormat('EEE, dd MMM yyyy').format(ticket.journeyDate);
    final bookingDate = DateFormat('dd MMM yyyy, HH:mm').format(ticket.bookingTime);

    // Determine status color
    Color statusColor;
    if (ticket.bookingStatus == 'confirmed') {
      statusColor = Colors.green;
    } else if (ticket.bookingStatus == 'cancelled') {
      statusColor = Colors.red;
    } else if (ticket.bookingStatus == 'pending') {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header with journey info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${ticket.fromCity} a ${ticket.toCity}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        journeyDate,
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    ticket.bookingStatus.toUpperCase() ,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Booking details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Bus info
                Row(
                  children: [
                    const Icon(
                      Icons.directions_bus_outlined,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.busName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${ticket.busType} • ${ticket.busNumber}',
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

                const SizedBox(height: 16),

                // Journey time
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tiempo de viaje',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${ticket.departureTime} - ${ticket.arrivalTime}',
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

                const SizedBox(height: 16),

                // Seats and amount
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.event_seat_outlined,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Asientos',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  ticket.seats.join(', '),
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
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.payment_outlined,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Cantidad',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'S/${ticket.totalWithTax.toStringAsFixed(2)}',
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
                  ],
                ),

                const SizedBox(height: 16),

                // Booking ID and date
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.confirmation_number_outlined,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ID de Reserva',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  ticket.id,
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
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Reservado el',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  bookingDate,
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
                  ],
                ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _viewTicket(ticket),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('VER BOLETO'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isUpcoming && ticket.bookingStatus != 'cancelled'
                            ? () => _cancelBooking(ticket)
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: isUpcoming && ticket.bookingStatus != 'cancelled'
                              ? Colors.red
                              : Colors.grey,
                        ),
                        child: const Text('CANCELAR'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}