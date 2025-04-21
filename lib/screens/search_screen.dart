import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/booking_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/city_selector.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final List<String> _popularCities = [
    'Lima', 'Huancayo', 'Tarma','Arequipa'

  ];

  final routes = [
    ['Lima', 'Tarma', 'assets/images/city/lima_tarma.jpg'],
    ['Tarma', 'Lima', 'assets/images/city/tarma_lima.jpg'],
    ['Lima', 'Huancayo', 'assets/images/city/lima_huancayo.jpg'],
    ['Huancayo', 'Lima', 'assets/images/city/huancayo_lima.jpg'],
    ['Arequipa','Lima','assets/images/city/lima_tarma.jpg'],
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<BookingProvider>(context, listen: false);
      setState(() {
        _fromController.text = provider.fromCity ?? '';
        _toController.text = provider.toCity ?? '';
        _selectedDate = provider.journeyDate ?? DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      Provider.of<BookingProvider>(context, listen: false).setJourneyDate(picked);
    }
  }



  void _swapCities() {
    setState(() {
      final temp = _fromController.text;
      _fromController.text = _toController.text;
      _toController.text = temp;
    });

    final provider = Provider.of<BookingProvider>(context, listen: false);
    provider.setFromCity(_fromController.text);
    provider.setToCity(_toController.text);
  }


  void _searchBuses() {
    if (_fromController.text.trim().isEmpty) {
      _showSnackBar('Por favor seleccione la ciudad de origen');
      return;
    }
    if (_toController.text.trim().isEmpty) {
      _showSnackBar('Por favor seleccione la ciudad de destino');
      return;
    }
    if (_fromController.text.trim() == _toController.text.trim()) {
      _showSnackBar('Origen y destino no pueden ser el mismo');
      return;
    }

    final provider = Provider.of<BookingProvider>(context, listen: false);
    provider.setFromCity(_fromController.text.trim());
    provider.setToCity(_toController.text.trim());
    provider.setJourneyDate(_selectedDate);

    Navigator.pushNamed(context, '/bus-list');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Buses'),
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // From city
                      GestureDetector(
                        onTap: () async {
                          final selectedCity = await showModalBottomSheet<String>(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            builder: (context) => CitySelector(
                              title: 'Seleccionar Origen',
                              cities: _popularCities,
                            ),
                          );

                          if (selectedCity != null) {
                            setState(() {
                              _fromController.text = selectedCity;
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: TextField(
                            controller: _fromController,
                            decoration: InputDecoration(
                              labelText: 'Desde',
                              prefixIcon: const Icon(Icons.location_on_outlined),
                              suffixIcon: _fromController.text.isNotEmpty
                                  ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _fromController.clear();
                                  });
                                },
                              )
                                  : null,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ),

                      // Swap button
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Divider(),
                            ),
                            IconButton(
                              onPressed: _swapCities,
                              icon: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.swap_vert,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(),
                            ),
                          ],
                        ),
                      ),


                      GestureDetector(
                        onTap: () async {
                          final selectedCity = await showModalBottomSheet<String>(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            builder: (context) => CitySelector(
                              title: 'Seleccionar Destino',
                              cities: _popularCities,
                            ),
                          );

                          if (selectedCity != null) {
                            setState(() {
                              _toController.text = selectedCity;
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: TextField(
                            controller: _toController,
                            decoration: InputDecoration(
                              labelText: 'Hasta',
                              prefixIcon: const Icon(Icons.location_on_outlined),
                              suffixIcon: _toController.text.isNotEmpty
                                  ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _toController.clear();
                                  });
                                },
                              )
                                  : null,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Date selector
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Fecha del viaje',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('EEE, dd MMM yyyy').format(_selectedDate),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Search button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _searchBuses,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'BUSCAR BUSES',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Popular routes
              Text(
                'Rutas populares',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // Popular route cards
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

              // Offers section
              Text(
                'Ofertas y descuentos',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // Offer cards
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildOfferCard(
                      context,
                      'PRIMERO50',
                      'Obtenga un 35% de descuento en su primera reserva',
                      Colors.blue.shade100,
                      Colors.blue.shade700,
                    ),
                    _buildOfferCard(
                      context,
                      'FINDESEMANA10',
                      '10% de descuento en viajes de fin de semana',
                      Colors.green.shade100,
                      Colors.green.shade700,
                    ),
                    _buildOfferCard(
                      context,
                      'VERANO25',
                      '25% de descuento en viajes de vacaciones de verano',
                      Colors.orange.shade100,
                      Colors.orange.shade700,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopularRouteCard(
      BuildContext context, String from, String to, String imagePath) {
    return GestureDetector(
      onTap: () {
        // Actualizar los controladores de texto
        _fromController.text = from;
        _toController.text = to;

        // Opcional: Navegar a otra pantalla o actualizar la UI
        if (kDebugMode) {
          print('Seleccionado: $from → $to');
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('$from → $to', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildOfferCard(
      BuildContext context,
      String code,
      String description,
      Color backgroundColor,
      Color textColor,
      ) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  code,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'TOQUE PARA COPIAR',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.copy,
                    size: 14,
                    color: textColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}