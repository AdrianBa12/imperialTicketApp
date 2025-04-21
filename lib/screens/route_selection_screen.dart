import 'package:flutter/material.dart';
import 'package:imperialticketapp/models/provincia.dart';
import 'package:imperialticketapp/providers/ticket_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class RouteSelectionScreen extends StatefulWidget {
  const RouteSelectionScreen({super.key});

  @override
  State<RouteSelectionScreen> createState() => _RouteSelectionScreenState();
}

class _RouteSelectionScreenState extends State<RouteSelectionScreen> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  Future<void> _loadProvinces() async {
    final provider = Provider.of<TicketProvider>(context, listen: false);
    if (provider.provinces.isEmpty) {
      await provider.loadProvinces();
    }
  }

  Widget _buildProvinceDropdown(
    String label,
    Provincia? value,
    ValueChanged<Provincia?> onChanged,
    List<Provincia> options,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonFormField<Provincia>(
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
          ),
          value: value,
          isExpanded: true,
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(
                'Seleccione $label',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ...options.map(
              (p) => DropdownMenuItem(
                value: p,
                child: Text(p.nombreProvincia ?? 'Provincia desconocida'),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: InkWell(
          onTap: () => _selectDate(context),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Fecha de viaje',
              border: InputBorder.none,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDate != null
                      ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                      : 'Seleccionar fecha',
                  style: TextStyle(
                    color: _selectedDate != null ? Colors.black : Colors.grey,
                  ),
                ),
                const Icon(Icons.calendar_today, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TicketProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar Ruta'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProvinceDropdown(
              'Origen',
              provider.originProvince,
              provider.setOriginProvince,
              provider.provinces,
            ),
            const SizedBox(height: 16),
            _buildProvinceDropdown(
              'Destino',
              provider.destinationProvince,
              provider.setDestinationProvince,
              provider.provinces
                  .where((p) => p.id != provider.originProvince?.id)
                  .toList(),
            ),
            const SizedBox(height: 16),
            _buildDateSelector(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (!mounted) return;
                  if (provider.originProvince == null ||
                      provider.destinationProvince == null ||
                      _selectedDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Seleccione origen, destino y fecha'),
                        duration: Duration(seconds: 5),
                      ),
                    );
                    return;
                  }

                  await provider.searchBuses(_selectedDate!);
                  
                  if (!mounted) return;
                  if (provider.availableBuses.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No se encontraron buses disponibles'),
                      ),
                    );
                    return;
                  }

                  Navigator.pushNamed(context, '/bus-selection');
                },
                icon: const Icon(Icons.search),
                label: const Text('Buscar viajes'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
