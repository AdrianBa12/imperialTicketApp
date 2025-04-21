import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pasajero.dart';
import '../models/asiento.dart';
import '../models/reserva.dart';
import '../services/master.service.dart';


class BookingScreen extends StatefulWidget {
  final String scheduleId;
  
  const BookingScreen({super.key, required this.scheduleId});

  @override
  State<BookingScreen> createState() => _BookingScreenState();

}

class _BookingScreenState extends State<BookingScreen> {
  final MasterService _masterService = MasterService();
  final _formKey = GlobalKey<FormState>();
  
  List<Asiento> _seatMap = [];
  List<Pasajero> _userSelectedSeatArray = [];
  bool _buscandoDNI = false;
  bool _mostrarResumen = false;
  bool _mostrarFormaPago = false;
  bool _procesandoPago = false;
  bool _isLoading = true;
  
  Map<String, dynamic> _scheduleData = {};
  Map<String, dynamic> _busInfo = {
    'claseDeBus': '',
    'placaBus': '',
  };
  
  // Datos de tarjeta
  String _numeroTarjeta = '';
  String _nombreTarjeta = '';
  String _expiracionTarjeta = '';
  String _cvv = '';

  @override
  void initState() {
    super.initState();
    _getScheduleDetailsById();
  }

  Future<void> _getScheduleDetailsById() async {
    setState(() => _isLoading = true);
    try {
      final response = await _masterService.getScheduleById(widget.scheduleId);
      setState(() {
        _scheduleData = response['data'];
        _seatMap = (response['data']['mapaDeAsientos'] as List)
            .map((item) => Asiento(number: item['number'], estado: item['estado']))
            .toList();
        _busInfo = {
          'claseDeBus': response['data']['claseDeBus'],
          'placaBus': response['data']['placaBus'],
        };
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar detalles: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _buscarDNI(int index) async {
    final dni = _userSelectedSeatArray[index].numeroDocumento;

    if (dni.isEmpty || dni.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese un DNI válido (8 dígitos)')),
      );
      return;
    }

    setState(() => _buscandoDNI = true);

    try {
      final response = await _masterService.buscarPorDNI(dni);
      if (response['success'] && response['data'] != null) {
        setState(() {
          _userSelectedSeatArray[index].nombreCompleto = response['data']['nombre_completo'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'No se encontraron datos')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al consultar DNI: $e')),
      );
    } finally {
      setState(() => _buscandoDNI = false);
    }
  }

  String _checkSeatStatus(int seatNo) {
    final seat = _seatMap.firstWhere((s) => s.number == seatNo);
    final isSelected = _userSelectedSeatArray.any((item) => item.seatNo == seatNo);
    
    if (isSelected) return 'selected';
    return seat.estado;
  }

  void _selectSeat(int seatNo) {
    if (_userSelectedSeatArray.length >= 4 && 
        !_userSelectedSeatArray.any((item) => item.seatNo == seatNo)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo 4 asientos por reserva')),
      );
      return;
    }

    final seat = _seatMap.firstWhere((s) => s.number == seatNo);
    if (seat.estado == 'ocupado') return;

    setState(() {
      final existingIndex = _userSelectedSeatArray.indexWhere((item) => item.seatNo == seatNo);
      
      if (existingIndex == -1) {
        _userSelectedSeatArray.add(Pasajero(seatNo: seatNo));
      } else {
        _userSelectedSeatArray.removeAt(existingIndex);
      }
    });
  }

  void _setDocumentType(int index, String type) {
    setState(() {
      _userSelectedSeatArray[index].tipoDocumento = type;
      if (type == 'dni') {
        _userSelectedSeatArray[index].nombreCompleto = '';
        _userSelectedSeatArray[index].edad = null;
      }
    });
  }

  void _removePassenger(int index) {
    setState(() => _userSelectedSeatArray.removeAt(index));
  }

  void _bookNow() {
    if (_userSelectedSeatArray.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione al menos un asiento')),
      );
      return;
    }

    for (final pasajero in _userSelectedSeatArray) {
      if (pasajero.numeroDocumento.isEmpty || 
          (pasajero.tipoDocumento == 'dni' && pasajero.numeroDocumento.length != 8) ||
          (pasajero.tipoDocumento == 'pasaporte' && pasajero.numeroDocumento.length < 6) ||
          pasajero.nombreCompleto.isEmpty ||
          pasajero.edad == null ||
          pasajero.edad! < 0 || pasajero.edad! > 120) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complete todos los campos correctamente')),
        );
        return;
      }
    }

    setState(() {
      _mostrarResumen = true;
      _mostrarFormaPago = false;
    });
  }

  Future<void> _confirmarPago() async {
    if (_numeroTarjeta.isEmpty || _nombreTarjeta.isEmpty || 
        _expiracionTarjeta.isEmpty || _cvv.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete todos los datos de la tarjeta')),
      );
      return;
    }

    setState(() => _procesandoPago = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('userData');
      
      if (userData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inicie sesión para reservar')),
        );
        return;
      }

      final userId = jsonDecode(userData)['userId'];

      // Crear reservas
      final reservas = _userSelectedSeatArray.map((pasajero) => Reserva(
        numeroDeasiento: pasajero.seatNo,
        nombreCompleto: pasajero.nombreCompleto,
        numeroDocumento: pasajero.numeroDocumento,
        tipoDocumento: pasajero.tipoDocumento,
        horarioDeAutobus: widget.scheduleId,
        usuario: userId.toString(),
      )).toList();

      for (final reserva in reservas) {
        await _masterService.crearReserva(reserva.toJson());
      }

      // Actualizar mapa de asientos
      final nuevoMapa = _seatMap.map((asiento) => Asiento(
        number: asiento.number,
        estado: _userSelectedSeatArray.any((item) => item.seatNo == asiento.number) 
            ? 'ocupado' 
            : asiento.estado,
      )).toList();

      await _masterService.actualizarMapaAsientos(
        widget.scheduleId,
        nuevoMapa.map((e) => e.toJson()).toList(),
      );

      // Generar comprobante
      _generarComprobante();

      // Resetear estado
      setState(() {
        _mostrarResumen = false;
        _mostrarFormaPago = false;
        _procesandoPago = false;
        _userSelectedSeatArray.clear();
      });

      await _getScheduleDetailsById();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reserva completada con éxito')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar pago: $e')),
      );
    } finally {
      setState(() => _procesandoPago = false);
    }
  }

  Future<void> _generarComprobante() async {
  final fecha = DateFormat('dd MMMM yyyy', 'es').format(DateTime.now());
  final horaSalida = DateFormat('HH:mm').format(
    DateTime.parse(_scheduleData['fechaDeSalida']),
    );

    if (kIsWeb) {
    // Solución para web - Mostrar el comprobante en un diálogo
    _mostrarComprobanteDialog();
    } else {
    // Solución para móvil - Generar PDF
    await _generarPDF();
    }
  
  }

  void _mostrarComprobanteDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Reserva Exitosa'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detalles del Viaje:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Ruta: ${_scheduleData['terminalSalidaId']['nombreTerminal']} → ${_scheduleData['terminalLlegadaId']['nombreTerminal']}'),
            Text('Fecha: ${DateFormat('EEEE dd MMMM yyyy', 'es').format(DateTime.parse(_scheduleData['fechaDeSalida']))}'),
            // Text('Hora: $horaSalida'),
            Text('Bus: ${_busInfo['claseDeBus']} (${_busInfo['placaBus']})'),
            SizedBox(height: 20),
            Text('Pasajeros:', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._userSelectedSeatArray.map((p) => 
              Text('Asiento ${p.seatNo}: ${p.nombreCompleto} (${p.tipoDocumento} ${p.numeroDocumento})')
            ).toList(),
            SizedBox(height: 20),
            Text('Total: S/. ${(_scheduleData['precio'] * _userSelectedSeatArray.length).toStringAsFixed(2)}', 
                 style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cerrar'),
        ),
      ],
    ),
  );
}


Future<void> _generarPDF() async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Header(level: 0, text: 'COMPROBANTE DE RESERVA'),
            pw.SizedBox(height: 20),
            pw.Text('Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'),
            pw.Divider(),
            pw.Text('Detalles del Viaje:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text('Ruta: ${_scheduleData['terminalSalidaId']['nombreTerminal']} → ${_scheduleData['terminalLlegadaId']['nombreTerminal']}'),
            pw.Text('Fecha: ${DateFormat('EEEE dd MMMM yyyy', 'es').format(DateTime.parse(_scheduleData['fechaDeSalida']))}'),
            
            pw.Text('Bus: ${_busInfo['claseDeBus']} (${_busInfo['placaBus']})'),
            pw.SizedBox(height: 20),
            pw.Text('Pasajeros:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ..._userSelectedSeatArray.map((p) => 
              pw.Text('Asiento ${p.seatNo}: ${p.nombreCompleto} (${p.tipoDocumento} ${p.numeroDocumento})')
            ),
            pw.SizedBox(height: 20),
            pw.Text('Total: S/. ${(_scheduleData['precio'] * _userSelectedSeatArray.length).toStringAsFixed(2)}', 
                   style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ],
        );
      },
    ),
  );

  // Opción 1: Mostrar el PDF directamente
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
  );

  // Opción 2: Guardar el PDF y abrirlo
  /*
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/comprobante_reserva.pdf');
  await file.writeAsBytes(await pdf.save());
  await OpenFile.open(file.path);
  */
}
  

  void _formatCardNumber(String value) {
    value = value.replaceAll(' ', '').replaceAll(RegExp(r'[^0-9]'), '');
    final parts = <String>[];
    for (var i = 0; i < value.length; i += 4) {
      parts.add(value.substring(i, i + 4 > value.length ? value.length : i + 4));
    }
    setState(() => _numeroTarjeta = parts.join(' '));
  }

  void _formatExpiry(String value) {
    value = value.replaceAll('/', '').replaceAll(RegExp(r'[^0-9]'), '');
    if (value.length > 2) {
      value = '${value.substring(0, 2)}/${value.substring(2)}';
    }
    setState(() => _expiracionTarjeta = value);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reserva')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reserva de Asientos')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_mostrarResumen && !_mostrarFormaPago) ...[
              _buildBusInfo(),
              const SizedBox(height: 20),
              _buildSeatMap(),
              const SizedBox(height: 20),
              if (_userSelectedSeatArray.isNotEmpty) _buildPassengerForms(),
            ],
            if (_mostrarResumen) _buildResumen(),
            if (_mostrarFormaPago) _buildPaymentForm(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButtons(),
    );
  }

  Widget _buildBusInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_scheduleData['terminalSalidaId']['nombreTerminal']} → ${_scheduleData['terminalLlegadaId']['nombreTerminal']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
  'Salida: ${DateFormat('EEEE dd MMMM yyyy - HH:mm', 'es').format(DateTime.parse(_scheduleData['fechaDeSalida']))}',
),
            Text('Duración: ${_scheduleData['duracionEnHoras']} horas'),
            Text('Bus: ${_busInfo['claseDeBus']} (${_busInfo['placaBus']})'),
            Text('Precio: S/. ${_scheduleData['precio'].toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildSeatMap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seleccione sus asientos',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: _seatMap.length,
          itemBuilder: (context, index) {
            final seatNo = _seatMap[index].number;
            final status = _checkSeatStatus(seatNo);
            
            Color color;
            switch (status) {
              case 'libre':
                color = Colors.green;
                break;
              case 'ocupado':
                color = Colors.red;
                break;
              case 'selected':
                color = Colors.blue;
                break;
              default:
                color = Colors.grey;
            }

            return GestureDetector(
              onTap: () => _selectSeat(seatNo),
              child: Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  border: Border.all(color: color),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    seatNo.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPassengerForms() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Datos de los pasajeros',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._userSelectedSeatArray.asMap().entries.map((entry) {
          final index = entry.key;
          final pasajero = entry.value;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Asiento ${pasajero.seatNo}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _removePassenger(index),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('DNI'),
                        selected: pasajero.tipoDocumento == 'dni',
                        onSelected: (selected) => 
                            _setDocumentType(index, selected ? 'dni' : ''),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Pasaporte'),
                        selected: pasajero.tipoDocumento == 'pasaporte',
                        onSelected: (selected) => 
                            _setDocumentType(index, selected ? 'pasaporte' : ''),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Número de Documento',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => 
                        _userSelectedSeatArray[index].numeroDocumento = value,
                    validator: (value) {
                      if (pasajero.tipoDocumento == 'dni' && value?.length != 8) {
                        return 'DNI debe tener 8 dígitos';
                      }
                      if (pasajero.tipoDocumento == 'pasaporte' && (value?.length ?? 0) < 6) {
                        return 'Mínimo 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  if (pasajero.tipoDocumento == 'dni')
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Nombre Completo',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) => 
                                _userSelectedSeatArray[index].nombreCompleto = value,
                          ),
                        ),
                        IconButton(
                          icon: _buscandoDNI
                              ? const CircularProgressIndicator()
                              : const Icon(Icons.search),
                          onPressed: () => _buscarDNI(index),
                        ),
                      ],
                    )
                  else
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Nombre Completo',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => 
                          _userSelectedSeatArray[index].nombreCompleto = value,
                    ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Edad',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => 
                        _userSelectedSeatArray[index].edad = int.tryParse(value ?? ''),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildResumen() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen de Reserva',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DataTable(
              columns: const [
                DataColumn(label: Text('Asiento')),
                DataColumn(label: Text('Nombre')),
                DataColumn(label: Text('Documento')),
                DataColumn(label: Text('Precio')),
              ],
              rows: _userSelectedSeatArray.map((pasajero) {
                return DataRow(cells: [
                  DataCell(Text(pasajero.seatNo.toString())),
                  DataCell(Text(pasajero.nombreCompleto)),
                  DataCell(Text('${pasajero.tipoDocumento.toUpperCase()} ${pasajero.numeroDocumento}')),
                  DataCell(Text('S/. ${_scheduleData['precio'].toStringAsFixed(2)}')),
                ]);
              }).toList(),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Total: S/. ${(_scheduleData['precio'] * _userSelectedSeatArray.length).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Datos de Pago',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Número de Tarjeta',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: _formatCardNumber,
              validator: (value) =>
                  value?.length != 19 ? 'Número inválido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Nombre en la Tarjeta',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _nombreTarjeta = value,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Expiración (MM/AA)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _formatExpiry,
                    validator: (value) =>
                        value?.length != 5 ? 'Formato inválido' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    onChanged: (value) => _cvv = value,
                    validator: (value) =>
                        value?.length != 3 ? 'CVV inválido' : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    if (_mostrarFormaPago) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _procesandoPago ? null : _confirmarPago,
          child: _procesandoPago
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Confirmar Pago'),
        ),
      );
    }

    if (_mostrarResumen) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() {
                  _mostrarResumen = false;
                  _mostrarFormaPago = false;
                }),
                child: const Text('Atrás'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => setState(() {
                  _mostrarResumen = false;
                  _mostrarFormaPago = true;
                }),
                child: const Text('Continuar a Pago'),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: _userSelectedSeatArray.isEmpty ? null : _bookNow,
        child: const Text('Reservar Ahora'),
      ),
    );
  }
}