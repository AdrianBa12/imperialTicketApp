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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar provincias: $e')));
    } finally {}
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
        _fromLocation!,
        _toLocation!,
        formattedDate,
      );
      debugPrint('Response de búsqueda de buses: $response');
      if (!mounted) return;

      setState(() {
        _busList =
            (response['data'] as List)
                .map((item) => HorarioAutobus.fromJson(item))
                .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al buscar buses: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  final routes = [
    ['Lima', 'Tarma', 'assets/images/city/lima_tarma.jpg'],
    ['Tarma', 'Lima', 'assets/images/city/tarma_lima.jpg'],
    ['Lima', 'Huancayo', 'assets/images/city/lima_huancayo.jpg'],
    ['Huancayo', 'Lima', 'assets/images/city/huancayo_lima.jpg'],
    ['La Merced', 'Lima', 'assets/images/city/lima_tarma.jpg'],
  ];

  Widget _popularRoutes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rutas populares',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: List.generate(routes.length, (index) {
            return _buildPopularRouteCard(
              context,
              routes[index][0],
              routes[index][1],
              routes[index][2],
              
            );
          }),
        ),
        const SizedBox(height: 24),
        const Divider(thickness: 1.2),
      ],
    );
  }

  Widget _buildPopularRouteCard(
    BuildContext context,
    String from,
    String to,
    String imagePath,
  ) {
    return GestureDetector(
      onTap: () {
        final fromProvincia = _locations.firstWhere(
          (loc) => loc.nombreProvincia == from,
          orElse:
              () => Provincia(
                id: 0,
                nombreProvincia: '',
                documentId: '',
                code: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                publishedAt: DateTime.now(),
              ),
        );
        final toProvincia = _locations.firstWhere(
          (loc) => loc.nombreProvincia == to,
          orElse:
              () => Provincia(
                id: 0,
                nombreProvincia: '',
                documentId: '',
                code: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                publishedAt: DateTime.now(),
              ),
        );

        if (fromProvincia.id != 0 && toProvincia.id != 0) {
          setState(() {
            _fromLocation = fromProvincia.id;
            _toLocation = toProvincia.id;
          });
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(imagePath, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: Text(
                '$from → $to',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      offset: Offset(0, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _popularRoutes() {
  //   final List<Map<String, String>> popularRoutes = [
  //     {'from': 'Cusco', 'to': 'Lima'},
  //     {'from': 'Arequipa', 'to': 'Cusco'},
  //     {'from': 'Puno', 'to': 'Arequipa'},
  //     {'from': 'Lima', 'to': 'Junin'},

  //   ];

  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const Text(
  //         'Rutas populares',
  //         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //       ),
  //       const SizedBox(height: 8),
  //       Wrap(
  //         spacing: 8,
  //         runSpacing: 8,
  //         children: popularRoutes.map((route) {
  //           return ActionChip(
  //             label: Text('${route['from']} → ${route['to']}'),
  //             backgroundColor: Colors.blue.shade50,
  //             onPressed: () {
  //               final from = _locations.firstWhere(
  //                   (loc) => loc.nombreProvincia == route['from'],
  //                   orElse: () => Provincia(
  //                     id: 0,
  //                     nombreProvincia: '',
  //                     documentId: '',
  //                     code: '',
  //                     createdAt: DateTime.now(),
  //                     updatedAt: DateTime.now(),
  //                     publishedAt: DateTime.now(),
  //                   ));
  //               final to = _locations.firstWhere(
  //                   (loc) => loc.nombreProvincia == route['to'],
  //                   orElse: () => Provincia(
  //                     id: 0,
  //                     nombreProvincia: '',
  //                     documentId: '',
  //                     code: '',
  //                     createdAt: DateTime.now(),
  //                     updatedAt: DateTime.now(),
  //                     publishedAt: DateTime.now(),
  //                   ));
  //               setState(() {
  //                 _fromLocation = from.id;
  //                 _toLocation = to.id;
  //               });
  //             },
  //           );
  //         }).toList(),
  //       ),
  //       const SizedBox(height: 24),
  //       Divider(thickness: 1.2),
  //     ],
  //   );
  // }

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
                decoration: const InputDecoration(
                  labelText: 'Provincia de Origen',
                  border: OutlineInputBorder(),
                ),
                items:
                    _locations.map((Provincia provincia) {
                      return DropdownMenuItem<int>(
                        value: provincia.id,
                        child: Text(
                          provincia.nombreProvincia ?? 'Nombre no disponible',
                        ),
                      );
                    }).toList(),
                onChanged: (int? value) {
                  setState(() => _fromLocation = value);
                },
                validator:
                    (value) =>
                        value == null
                            ? 'Seleccione una provincia de origen'
                            : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _toLocation,
                decoration: const InputDecoration(
                  labelText: 'Provincia de Destino',
                  border: OutlineInputBorder(),
                ),
                items:
                    _locations.map((Provincia provincia) {
                      return DropdownMenuItem<int>(
                        value: provincia.id,
                        child: Text(
                          provincia.nombreProvincia ?? 'Nombre no disponible',
                        ),
                      );
                    }).toList(),
                onChanged: (int? value) {
                  setState(() => _toLocation = value);
                },
                validator:
                    (value) =>
                        value == null
                            ? 'Seleccione una provincia de destino'
                            : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
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
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _onSearch,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Color(0xFFBF303C),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                icon: const Icon(Icons.search),
                label:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Buscar Buses'),
              ),

              // _popularRoutes(),
              const SizedBox(height: 24),

              if (_isLoading)
                Center(child: CircularProgressIndicator())
              else if (_busList.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: _busList.length,
                    itemBuilder: (context, index) {
                      final bus = _busList[index];
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.only(
                          bottom: 16,
                          left: 16,
                          right: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    bus.numeroPLacaBus,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Chip(
                                    // Chip para la clase de bus
                                    label: Text(
                                      bus.claseDeBus,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: Colors.grey[300],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.departure_board,
                                    color: Colors.blueGrey,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Salida: ${DateFormat('dd/MM/yyyy HH:mm').format(bus.fechaDeSalida)}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Colors.blueGrey,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Llegada: ${DateFormat('dd/MM/yyyy HH:mm').format(bus.fechaDeLlegada)}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.timer_outlined,
                                    color: Colors.blueGrey,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Duración: ${bus.duracionEnHoras} horas',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.event_seat,
                                    color: Colors.blueGrey,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Asientos: ${bus.asientosDisponibles}/${bus.totalDeAsiento}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'S/.${bus.precio.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Color(0xFFBF303C),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => BookingScreen(
                                                scheduleId: bus.documentId,
                                              ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(
                                            context,
                                          ).primaryColor, // Usa el color primario de tu tema
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text('Reservar'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                )
              else if (!_isLoading && _busList.isEmpty && _fromLocation != null)
                const Center(
                  child: Text('No se encontraron buses para esta ruta'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
