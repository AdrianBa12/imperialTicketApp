import 'package:flutter/material.dart';
import 'package:imperialticketapp/screens/booking_screens.dart';
import 'package:intl/intl.dart';
import '../models/provincia.dart';
import '../models/horario_de_autobus.dart';
import '../services/master.service.dart';


class SearchScreen extends StatefulWidget {
  
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final MasterService _masterService = MasterService();
  List<Provincia> _locations = [];
  List<HorarioAutobus> _busList = [];
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  int? _fromLocation;
  int? _toLocation;

  @override
  void initState() {
    super.initState();
    _getAllLocations();
    
  }

  Future<void> _getAllLocations() async {
    try {
      final response = await _masterService.getProvincias();
       
      if (!mounted) return; 
      
      setState(() {
        _locations = response.map((item) => Provincia.fromJson(item)).toList();
      });
        } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar provincias: $e')),
      );
    } finally {
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _onSearch() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fromLocation == null || _toLocation == null || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, complete todos los campos')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _busList = [];
    });

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final response = await _masterService.searchBus(
        _fromLocation! ,
        _toLocation!,
        formattedDate,
      );
      debugPrint('Response de búsqueda de buses: $response');
      if (!mounted) return;

      setState(() {
        _busList = (response['data'] as List)
            .map((item) => HorarioAutobus.fromJson(item))
            .toList();
      });
    } catch (e) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al buscar buses: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar Buses')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<int>(
                value: _fromLocation,
                decoration: InputDecoration(
                  labelText: 'Provincia de Origen',
                  border: OutlineInputBorder(),
                ),
                items: _locations.map((Provincia provincia) {
                  return DropdownMenuItem<int>(
                    value: provincia.id,
                    child: Text(provincia.nombreProvincia ?? 'Nombre no disponible'),
                  );
                }).toList(),
                onChanged: (int? value) {
                  setState(() => _fromLocation = value);
                },
                validator: (value) =>
                    value == null ? 'Seleccione un origen' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _toLocation,
                decoration: InputDecoration(
                  labelText: 'Provincia de Destino',
                  border: OutlineInputBorder(),
                ),
                items: _locations.map((Provincia provincia) {
                  return DropdownMenuItem<int>(
                    value: provincia.id,
                    child: Text(provincia.nombreProvincia ?? 'Nombre no disponible'),
                  );
                }).toList(),
                onChanged: (int? value) {
                  setState(() => _toLocation = value);
                },
                validator: (value) =>
                    value == null ? 'Seleccione un destino' : null,
              ),
              SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fecha de Viaje',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null
                            ? 'Seleccione una fecha'
                            : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                      ),
                      Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _onSearch,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Buscar Buses'),
                
              ),
              SizedBox(height: 24),
              if (_isLoading)
                Center(child: CircularProgressIndicator())
              else if (_busList.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: _busList.length,
                    itemBuilder: (context, index) {
                      final bus = _busList[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${bus.numeroPLacaBus} - ${bus.claseDeBus}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Salida: ${DateFormat('dd/MM/yyyy HH:mm').format(bus.fechaDeSalida)}',
                              ),
                              Text(
                                'Llegada: ${DateFormat('dd/MM/yyyy HH:mm').format(bus.fechaDeLlegada)}',
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Duración: ${bus.duracionEnHoras} horas',
                              ),
                              Text(
                                'Asientos disponibles: ${bus.asientosDisponibles}/${bus.totalDeAsiento}',
                              ),
                              Text(
                                'Precio: S/.${bus.precio.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              SizedBox(height: 16),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BookingScreen(
                                          scheduleId: bus.documentId,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text('Reservar'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                )
              else if (!_isLoading && _busList.isEmpty && _fromLocation != null)
                Center(
                  child: Text('No se encontraron buses para esta ruta'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

