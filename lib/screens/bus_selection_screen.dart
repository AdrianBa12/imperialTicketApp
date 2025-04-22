import 'package:flutter/material.dart';

import 'package:imperialticketapp/models/horario_de_autobus.dart';
import 'package:imperialticketapp/screens/booking_screens.dart';
import 'package:intl/intl.dart';

class BusSelectionScreen extends StatefulWidget {
  final int fromId;
  final int toId;
  final DateTime fecha;

  const BusSelectionScreen({
    super.key,
    required this.fromId,
    required this.toId,
    required this.fecha,
  });

  @override
  State<BusSelectionScreen> createState() => _BusSelectionScreenState();
}

class _BusSelectionScreenState extends State<BusSelectionScreen> {
  final List<HorarioAutobus> _busList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
  }

  
  Future<void> _fetchBusSchedules() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate a network call to fetch bus schedules
      await Future.delayed(const Duration(seconds: 2));
      // Replace with actual API call to fetch bus schedules
      // _busList = await BusService.searchByProvinces(
      //   originProvinceId: widget.fromId,
      //   destinationProvinceId: widget.toId,
      //   date: widget.fecha,
      // );
    } catch (e) {
      debugPrint('Error fetching bus schedules: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resultados de Buses')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _busList.isEmpty
              ? const Center(child: Text('No se encontraron buses para esta ruta'))
              : ListView.builder(
                  itemCount: _busList.length,
                  itemBuilder: (context, index) {
                    final bus = _busList[index];
                    return Card(
                      margin: const EdgeInsets.all(12),
                      child: ListTile(
                        title: Text('${bus.numeroPLacaBus} - ${bus.claseDeBus}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Salida: ${DateFormat('dd/MM/yyyy HH:mm').format(bus.fechaDeSalida)}'),
                            Text('Llegada: ${DateFormat('dd/MM/yyyy HH:mm').format(bus.fechaDeLlegada)}'),
                            Text('Duración: ${bus.duracionEnHoras} horas'),
                            Text('Precio: S/.${bus.precio.toStringAsFixed(2)}'),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookingScreen(scheduleId: bus.documentId),
                              ),
                            );
                          },
                          child: const Text('Reservar'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
