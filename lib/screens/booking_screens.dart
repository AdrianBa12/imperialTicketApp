import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:imperialticketapp/models/user.dart';
import 'package:imperialticketapp/screens/reserva_confirm_screen.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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
  
  static const String _apiPeruToken = '25222079ce57429371cf6d908d8b283966aad65f8e64caf50c2fff09a5727ce6';
  static const String _apiPeruUrl = 'https://apiperu.dev/api/dni/';
  final MasterService _masterService = MasterService();
  
  List<Asiento> _seatMap = [];
  final List<Pasajero> _userSelectedSeatArray = [];
  final List<TextEditingController> _nombreControllers = [];
  bool _buscandoDNI = false;
  bool _mostrarResumen = false;
  bool _mostrarFormaPago = false;
  bool _procesandoPago = false;
  bool _isLoading = true;
  User? _user;
  
  Map<String, dynamic> _scheduleData = {};
  Map<String, dynamic> _busInfo = {
    'claseDeBus': '',
    'placaBus': '',
  };
  final bool _pagoExitoso = true;
  
  String _numeroTarjeta = '';
  String _nombreTarjeta = '';
  String _expiracionTarjeta = '';
  String _cvv = '';

  @override
  void initState() {
    super.initState();
    _getScheduleDetailsById().then((_) {
      _userSelectedSeatArray.addAll(
        _seatMap.where((asiento) => asiento.estado == 'selected').map((asiento) => Pasajero(seatNo: asiento.number)).toList(),
      );
      _nombreControllers.clear();
      _nombreControllers.addAll(
      _userSelectedSeatArray.map((pasajero) => TextEditingController(text: pasajero.nombreCompleto)).toList(),
    );
  });
  }

   Future<void> _completarReserva() async {
    final reservaData = {
  'horario_de_autobus': _scheduleData['id'],
  'numeroDeasiento': _userSelectedSeatArray.map((p) => p.seatNo).toList(),
  'usuario': _user?.id,
  'nombreCompleto': _userSelectedSeatArray.isNotEmpty ? _userSelectedSeatArray[0].nombreCompleto : '', 
  'numeroDocumento': _userSelectedSeatArray.isNotEmpty ? _userSelectedSeatArray[0].numeroDocumento : '', 
  'tipoDocumento': _userSelectedSeatArray.isNotEmpty ? _userSelectedSeatArray[0].tipoDocumento.toUpperCase() : '', 
  'pasajeros': _userSelectedSeatArray.map((p) => { 
    'nombreCompleto': p.nombreCompleto,
    'numeroDocumento': p.numeroDocumento,
    'tipoDocumento': p.tipoDocumento.toUpperCase(),
  }).toList(),
  'totalPagado': (_scheduleData['precio'] * _userSelectedSeatArray.length),
  'codigoReserva': _generarCodigoReservaUnico(),
};


  final apiUrl = 'https://automatic-festival-37ec7cc8d8.strapiapp.com/api/reservas';
  final headers = {'Content-Type': 'application/json'};
  final body = jsonEncode({
    'data': reservaData,
  });

  debugPrint('Cuerpo de la petición a Strapi: $body');

  try {
    final response = await http.post(Uri.parse(apiUrl), headers: headers, body: body);

    debugPrint('Estado de la respuesta de Strapi: ${response.statusCode}');
    debugPrint('Cuerpo de la respuesta de Strapi: ${response.body}');

    if (response.statusCode == 201) {
  debugPrint('Reserva guardada exitosamente en Strapi.');
  
  final reservaDetails = {
    'codigo_reserva': reservaData['codigoReserva'],
    'pasajeros': _userSelectedSeatArray.map((p) => {...p.toJson()}).toList(), 
    'origen': _scheduleData['terminalSalidaId']['nombreTerminal'],
    'destino': _scheduleData['terminalLlegadaId']['nombreTerminal'],
    'fecha_salida': _scheduleData['fechaDeSalida'],
    'bus': _busInfo['placaBus'],
    'total_pagado': (_scheduleData['precio'] * _userSelectedSeatArray.length).toStringAsFixed(2),
    'usuario': _user?.id, 
    
  };
  final qrDataString = jsonEncode({'codigo_reserva': reservaData['codigoReserva']});

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ReservaConfirmadaScreen(qrData: qrDataString, reservaDetails: reservaDetails),
    ),
  );
    } else {
      debugPrint('Error al guardar la reserva en Strapi. Status Code: ${response.statusCode}, Body: ${response.body}');
     
    }
  } catch (e) {
    debugPrint('Error de conexión al backend: $e');
    
  }
}

  String _generarCodigoReservaUnico() {
    return DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase();
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
  final numeroDNI = _userSelectedSeatArray[index].numeroDocumento;
  
  if (numeroDNI.length != 8) {
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('El DNI debe tener 8 dígitos.')),
    );
    return;
  }

  setState(() {
    _buscandoDNI = true;
    
  });

  try {
    final url = Uri.parse('$_apiPeruUrl$numeroDNI');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiPeruToken',
    };

    final response = await http.get(url, headers: headers);
    

    if (response.statusCode == 200) {
      try {
        final decodedData = json.decode(response.body);
         

        if (decodedData['success'] == true && decodedData['data'] != null) {
          final nombres = decodedData['data']['nombres'];
          final apellidoPaterno = decodedData['data']['apellido_paterno'];
          final apellidoMaterno = decodedData['data']['apellido_materno'];
          final nombreCompleto = '$nombres $apellidoPaterno $apellidoMaterno';
         

          setState(() {
            _userSelectedSeatArray[index].nombreCompleto = nombreCompleto;
            _nombreControllers[index].text = nombreCompleto;
            
          });
        } else {
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('DNI no encontrado.')),
          );
          setState(() {
            _buscandoDNI = false;
            
          });
        }
      } catch (e) {
         
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al procesar la respuesta.')),
        );
        setState(() {
          _buscandoDNI = false;
           
        });
      }
    } else {
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al buscar DNI: ${response.statusCode}')),
      );
      setState(() {
        _buscandoDNI = false;
        
      });
    }
  } catch (e) {
    debugPrint('Error de conexión: $e'); 
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error de conexión: $e')),
    );
    setState(() {
      _buscandoDNI = false;
      
    });
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
        _nombreControllers.add(TextEditingController());
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
    setState(() {
    _userSelectedSeatArray.removeAt(index);
    _nombreControllers.removeAt(index); 
  });
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
  setState(() {
    _procesandoPago = true;
  });

  
  await Future.delayed(const Duration(seconds: 3));
  bool pagoExitoso = true; 

  setState(() {
    _procesandoPago = false;
  });

  if (pagoExitoso) {
    
    await _completarReserva();
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('El pago falló. Inténtelo de nuevo.')),
    );
  }
}

  // String generarCodigoReservaUnico() {
  //   return DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase();
  // }


  // Future<void> _confirmarPago() async {
  //   if (_numeroTarjeta.isEmpty || _nombreTarjeta.isEmpty || 
  //       _expiracionTarjeta.isEmpty || _cvv.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Complete todos los datos de la tarjeta')),
  //     );
  //     return;
  //   }

  //   setState(() => _procesandoPago = true);

  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final userData = prefs.getString('userData');
      
  //     if (userData == null) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Inicie sesión para reservar')),
  //       );
  //       return;
  //     }

  //     final userId = jsonDecode(userData)['userId'];

  //     final reservas = _userSelectedSeatArray.map((pasajero) => Reserva(
  //       numeroDeasiento: pasajero.seatNo,
  //       nombreCompleto: pasajero.nombreCompleto,
  //       numeroDocumento: pasajero.numeroDocumento,
  //       tipoDocumento: pasajero.tipoDocumento,
  //       horarioDeAutobus: widget.scheduleId,
  //       usuario: userId.toString(),
  //     )).toList();

  //     for (final reserva in reservas) {
  //       await _masterService.crearReserva(reserva.toJson());
  //     }

  //     final nuevoMapa = _seatMap.map((asiento) => Asiento(
  //       number: asiento.number,
  //       estado: _userSelectedSeatArray.any((item) => item.seatNo == asiento.number) 
  //           ? 'ocupado' 
  //           : asiento.estado,
  //     )).toList();

  //     await _masterService.actualizarMapaAsientos(
  //       widget.scheduleId,
  //       nuevoMapa.map((e) => e.toJson()).toList(),
  //     );

  //     _generarComprobante();

  //     setState(() {
  //       _mostrarResumen = false;
  //       _mostrarFormaPago = false;
  //       _procesandoPago = false;
  //       _userSelectedSeatArray.clear();
  //     });

  //     await _getScheduleDetailsById();

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Reserva completada con éxito')),
  //     );
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error al procesar pago: $e')),
  //     );
  //   } finally {
  //     setState(() => _procesandoPago = false);
  //   }
  // }

  Future<void> _generarComprobante() async {
  final fecha = DateFormat('dd MMMM yyyy', 'es').format(DateTime.now());
  final horaSalida = DateFormat('HH:mm').format(
    DateTime.parse(_scheduleData['fechaDeSalida']),
    );

    if (kIsWeb) {
    _mostrarComprobanteDialog();
    } else { 
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
            ),
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

  
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
  );

  
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/comprobante_reserva.pdf');
  await file.writeAsBytes(await pdf.save());
  await OpenFile.open(file.path);
  
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
              _buildBusInfo(_scheduleData, _busInfo),
              const SizedBox(height: 20),
              _buildSeatMap(),
              const SizedBox(height: 20),
              if (_userSelectedSeatArray.isNotEmpty) _buildPassengerForms(),
            ],
            if (_mostrarResumen) _buildResumen(_scheduleData, _userSelectedSeatArray),
            if (_mostrarFormaPago) _buildPaymentForm(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButtons(),
    );
  }

  Widget _buildSeatMap() {
  const int seatsPerRowFirstFloor = 4;
  const int firstFloorSeats = 12;
  final int totalSeats = 48; 
  final int secondFloorSeatsCount = totalSeats - firstFloorSeats;
  const int seatsPerRowSecondFloor = 4;

  Widget buildSeat(int seatNo) {
    final status = _checkSeatStatus(seatNo);
    Color color;
    bool isSelectable = true;
    switch (status) {
      case 'libre':
        color = Colors.green;
        break;
      case 'ocupado':
        color = const Color(0xFFBF303C);
        break;
      case 'selected':
        color = Colors.blue;
        break;
      case 'fixed': 
        color = Colors.grey[400]!;
        isSelectable = false;
        break;
      default:
        color = Colors.grey;
    }

    return Expanded(
      child: GestureDetector(
        onTap: isSelectable ? () => _selectSeat(seatNo) : null,
        child: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: status == 'selected'
                ? color.withValues(alpha:0.3)
                : (status == 'fixed' ? color.withValues(alpha:0.8) : Colors.white),
            border: Border.all(color: color, width: 1.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              status == 'fixed' ? '' : seatNo.toString(), 
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildRow(List<int?> seats, bool hasMiddleGap) {
    List<Widget> row = [];
    for (int? seatNo in seats) {
      if (seatNo == null) {
        row.add(const Expanded(child: SizedBox(width: 40 + 8))); 
      } else {
        row.add(buildSeat(seatNo));
        if (hasMiddleGap && seats.indexOf(seatNo) == (seats.length / 2) - 1) {
          row.add(const SizedBox(width: 24)); 
        }
      }
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: row,
    );
  }

  Widget buildFloorPlan(List<int?> floorSeatsLayout, int seatsPerRow) {
    List<Widget> floorRows = [];
    for (int i = 0; i < (floorSeatsLayout.length / seatsPerRow).ceil(); i++) {
      final startIndex = i * seatsPerRow;
      final endIndex = (i + 1) * seatsPerRow;
      final rowSeats = floorSeatsLayout.sublist(
          startIndex, endIndex > floorSeatsLayout.length ? floorSeatsLayout.length : endIndex);
      floorRows.add(buildRow(rowSeats, seatsPerRow == 4));
      floorRows.add(const SizedBox(height: 8));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: floorRows,
    );
  }

  
  List<int?> firstFloorLayout = [
    1, 2, null, 3, 
    4, 5, null, 6, 
    7, 8, null, 9, 
    10, 11, null, 12, 
  ];

  List<int?> secondFloorLayout = [
    13, 14, 15,16,
    17, 18, 19,20, 
    21, 22, null, null,
    23, 24, null, null, 
    25, 26, 27,28,
    29, 30, 31,32,
    33, 34, 35,36,
    37, 38, 39,40,
    41, 42, 43,44,
    45, 46, 47,48,null,

  ];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      const Text(
        'Seleccione sus asientos',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      const Icon(Icons.directions_bus, size: 40), 
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Primer Piso', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            buildFloorPlan(firstFloorLayout, seatsPerRowFirstFloor),
            if (secondFloorSeatsCount > 0) ...[
              const SizedBox(height: 16),
              const Text('Segundo Piso', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              buildFloorPlan(secondFloorLayout, seatsPerRowSecondFloor),
            ],
          ],
        ),
      ),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _seatLegend(Colors.grey[400]!, 'Libre'),
          _seatLegend(const Color(0xFFBF303C), 'Ocupado'),
          _seatLegend(Colors.blue, 'Seleccionado'),
          
        ],
      ),
    ],
  );
}

Widget _seatLegend(Color color, String text) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.8),
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      const SizedBox(width: 8),
      Text(text),
    ],
  );
}

Widget _buildBusInfo(Map<String, dynamic> scheduleData, Map<String, dynamic> busInfo) {
  final salida = scheduleData['terminalSalidaId']['nombreTerminal'] as String? ?? '';
  final llegada = scheduleData['terminalLlegadaId']['nombreTerminal'] as String? ?? '';
  final fechaSalida = scheduleData['fechaDeSalida'] != null
      ? DateFormat('EEEE dd MMMM - HH:mm', 'es').format(DateTime.parse(scheduleData['fechaDeSalida']))
      : '';
  final duracion = scheduleData['duracionEnHoras']?.toString() ?? '';
  final claseBus = busInfo['claseDeBus'] as String? ?? '';
  final placaBus = busInfo['placaBus'] as String? ?? '';
  final precio = scheduleData['precio']?.toStringAsFixed(2) ?? '0.00';

  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFFBF303C)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$salida → $llegada',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFBF303C)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, color: Colors.grey),
              const SizedBox(width: 8),
              Text('Salida: $fechaSalida'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: Colors.grey),
              const SizedBox(width: 8),
              Text('Duración: $duracion horas'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.directions_bus, color: Colors.grey),
              const SizedBox(width: 8),
              Text('Bus: $claseBus ($placaBus)'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('Precio:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text('S/. $precio', style: const TextStyle(fontSize: 16, color: Color(0xFFBF303C))),
            ],
          ),
        ],
      ),
    ),
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
      const SizedBox(height: 16),
      ..._userSelectedSeatArray.asMap().entries.map((entry) {
        final index = entry.key;
        final pasajero = entry.value;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _removePassenger(index),
                    ),
                  ],
                ),
                const Divider(height: 20, thickness: 0.5, color: Colors.grey),
                const Text('Tipo de Documento', style: TextStyle(fontWeight: FontWeight.w500)),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('DNI', style: TextStyle(fontSize: 14)),
                        value: 'dni',
                        groupValue: pasajero.tipoDocumento,
                        onChanged: (value) => _setDocumentType(index, value!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Pasaporte', style: TextStyle(fontSize: 14)),
                        value: 'pasaporte',
                        groupValue: pasajero.tipoDocumento,
                        onChanged: (value) => _setDocumentType(index, value!),
                      ),
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
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Nombre Completo',
                    border: const OutlineInputBorder(),
                    suffixIcon: pasajero.tipoDocumento == 'dni'
                        ? _buscandoDNI
                            ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.search),
                                onPressed: () => _buscarDNI(index),
                              )
                        : null,
                  ),
                  controller: _nombreControllers[index], 
                  onChanged: (value) => _userSelectedSeatArray[index].nombreCompleto = value,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Edad',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) =>
                      _userSelectedSeatArray[index].edad = int.tryParse(value),
                ),
              ],
            ),
          ),
        );
      }),
    ],
  );
}

Widget _buildResumen(Map<String, dynamic> scheduleData, List<Pasajero> userSelectedSeatArray) {
  final salida = scheduleData['terminalSalidaId']['nombreTerminal'] as String? ?? '';
  final llegada = scheduleData['terminalLlegadaId']['nombreTerminal'] as String? ?? '';
  final fechaSalida = scheduleData['fechaDeSalida'] != null
      ? DateFormat('EEEE dd MMMM - HH:mm', 'es').format(DateTime.parse(scheduleData['fechaDeSalida']))
      : '';
  final precioPorAsiento = scheduleData['precio']?.toStringAsFixed(2) ?? '0.00';
  final totalPrecio = (scheduleData['precio'] * userSelectedSeatArray.length).toStringAsFixed(2);

  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de Reserva',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            '$salida → $llegada',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFFBF303C)),
          ),
          Text(
            'Salida: $fechaSalida',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          const Text(
            'Detalles de los Pasajeros',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: userSelectedSeatArray.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final pasajero = userSelectedSeatArray[index];
              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_outline, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            pasajero.nombreCompleto.isNotEmpty ? pasajero.nombreCompleto : 'Pasajero ${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.event_seat_outlined, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text('Asiento: ${pasajero.seatNo}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.badge_outlined, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text('Documento: ${pasajero.tipoDocumento.toUpperCase()} ${pasajero.numeroDocumento}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text('Precio:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Text('S/. $precioPorAsiento'),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('S/. $totalPrecio', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFBF303C))),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildPaymentForm() {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Datos de Pago',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Número de Tarjeta',
              hintText: 'XXXX-XXXX-XXXX-XXXX',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.credit_card_outlined),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(19), 
              _CardNumberFormatter(), 
            ],
            onChanged: _formatCardNumber,
            validator: (value) =>
                value?.length != 19 ? 'Número de tarjeta inválido' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Nombre en la Tarjeta',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
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
                    hintText: 'MM/AA',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4), 
                    _ExpiryDateFormatter(), 
                  ],
                  onChanged: _formatExpiry,
                  validator: (value) =>
                      value?.length != 5 ? 'Formato inválido (MM/AA)' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    hintText: 'XXX',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.security_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  onChanged: (value) => _cvv = value,
                  validator: (value) =>
                      value?.length != 3 ? 'CVV inválido (3 dígitos)' : null,
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



class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = StringBuffer();
    var selectionIndex = newValue.selection.end;
    var usedSubstringIndex = 0;

    for (var i = 0; i < min(newValue.text.length, 16); i++) {
      if (usedSubstringIndex >= newValue.text.length) break;
      final currentChar = newValue.text[usedSubstringIndex];
      if (currentChar != ' ') {
        newText.write(currentChar);
        if ((i + 1) % 4 == 0 && i < 15) {
          newText.write(' ');
          if (selectionIndex > usedSubstringIndex + 1) selectionIndex++;
        }
      }
      usedSubstringIndex++;
    }

    return TextEditingValue(
      text: newText.toString(),
      selection: TextSelection.collapsed(offset: newText.length > 0 ? min(newText.length, selectionIndex) : 0),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = StringBuffer();
    var selectionIndex = newValue.selection.end;
    var usedSubstringIndex = 0;

    for (var i = 0; i < min(newValue.text.length, 4); i++) {
      if (usedSubstringIndex >= newValue.text.length) break;
      final currentChar = newValue.text[usedSubstringIndex];
      newText.write(currentChar);
      if ((i + 1) % 2 == 0 && i < 3 && newText.length < 5 && currentChar != '/') {
        newText.write('/');
        if (selectionIndex > usedSubstringIndex + 1) selectionIndex++;
      }
      usedSubstringIndex++;
    }

    return TextEditingValue(
      text: newText.toString(),
      selection: TextSelection.collapsed(offset: min(newText.length, selectionIndex)),
    );
  }
}
