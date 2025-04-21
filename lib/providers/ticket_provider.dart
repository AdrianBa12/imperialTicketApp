import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:imperialticketapp/models/horario_de_autobus.dart';
import 'package:imperialticketapp/models/provincia.dart';
import 'package:imperialticketapp/models/terminal.dart';


import 'package:imperialticketapp/services/provincia_service.dart';
import 'package:imperialticketapp/services/terminal_service.dart';
import 'package:imperialticketapp/services/bus_service.dart';


class TicketProvider with ChangeNotifier {
  Map<String, dynamic>? _selectedBus;
  final List<dynamic> _availableBuses = [];

  List<dynamic> get availableBuses => _availableBuses;
  Provincia? _originProvince;
  Provincia? _destinationProvince;
  DateTime? _selectedDate;

  HorarioAutobus? _selectedSchedule;
  int? _selectedSeat;
  String _passengerName = '';
  String _passengerDni = '';
  String _paymentMethod = '';
  
  List<Terminal> _terminals = [];
  List<Provincia> _provinces = [];
  List<HorarioAutobus> _availableSchedules = [];
  
  bool _isLoading = false;
  
  String? _error;
  String? _errorMessage;
  Exception? _exception;

  
  List<Terminal> get terminals => _terminals;
  List<Provincia> get provinces => _provinces;
  List<HorarioAutobus> get availableSchedules => _availableSchedules;
  Map<String, dynamic>? get selectedBus => _selectedBus;

  Provincia? get originProvince => _originProvince;
  Provincia? get destinationProvince => _destinationProvince;
  DateTime? get selectedDate => _selectedDate;
  HorarioAutobus? get selectedSchedule => _selectedSchedule;
  int? get selectedSeat => _selectedSeat;
  String get passengerName => _passengerName;
  String get passengerDni => _passengerDni;
  String get paymentMethod => _paymentMethod;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get errorMessage => _errorMessage;
  Exception? get exception => _exception;

  TicketProvider() {
    _initializeData();
  }

  void _safeNotifyListeners() {
    if (!_isLoading) notifyListeners(); 
  }

  void setOriginProvince(Provincia? province) {
    _originProvince = province;
    notifyListeners();
  }
  void setSelectedBus(Map<String, dynamic> bus) {
    _selectedBus = bus;
    notifyListeners();
  }


  void setDestinationProvince(Provincia? province) {
    _destinationProvince = province;
    notifyListeners();
  }

  void setSelectedDate(DateTime? date) {
    _selectedDate = date;
    notifyListeners();
  }


  Future<void> _initializeData() async {
  await loadProvinces(); 
  
}
  Future<void> loadProvinces() async {
  if (_provinces.isNotEmpty) return;
  
  _isLoading = true;
  _safeNotifyListeners();

  try {
    _provinces = await ProvinciaService.getProvincias();
    if (_provinces.isEmpty) {
      debugPrint('Advertencia: Lista de provincias vacía');
    }
  } catch (e) {
    debugPrint('Error cargando provincias: $e');
    _provinces = [];
  } finally {
    _isLoading = false;
    _safeNotifyListeners();
  }
}

  Future<void> loadTerminals() async {
  if (_terminals.isNotEmpty || _isLoading) return;
  
  _isLoading = true;
  _error = null; 
  _safeNotifyListeners();
  
  try {
    _terminals = await TerminalService.getTerminales();
  } catch (e) {
    _error = 'No se pudieron cargar las terminales. Intente nuevamente.';
    debugPrint('Error loadTerminals: $e');
  } finally {
    _isLoading = false;
    _safeNotifyListeners();
  }
}
 
  Future<void> searchBuses(DateTime date) async {
  if (originProvince == null || destinationProvince == null) {
    _errorMessage = 'Seleccione origen y destino primero';
    _setLoading(false);
    return;
  }

  try {
    _setLoading(true);
    _errorMessage = null;
    _availableSchedules = [];

    final results = await BusService.searchByProvinces(
      originProvinceId: originProvince!.id,
      destinationProvinceId: destinationProvince!.id,
      date: date,
    );

    if (results.isEmpty) {
      _errorMessage = 'No hay horarios disponibles para esta ruta y fecha';
    } else {
      _availableSchedules = results;
    }
  } catch (e, stackTrace) {
    debugPrint('Error en searchBuses: $e\n$stackTrace');
    _errorMessage = _getErrorMessage(e);
  } finally {
    _setLoading(false);
    notifyListeners();
  }
}
String _getErrorMessage(dynamic error) {
  if (error is SocketException) return 'Error de conexión a internet';
  if (error is TimeoutException) return 'Tiempo de espera agotado';
  if (error is FormatException) return 'Error en el formato de los datos';
  if (error is HttpException) return 'Error HTTP: ${error.message}';
  if (error is Exception) return 'Error desconocido: ${error.toString()}';
  return 'Error al buscar horarios. Intente nuevamente';
}

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void selectSchedule(HorarioAutobus schedule) {
    _selectedSchedule = schedule;
    notifyListeners();
  }

  void selectSeat(int seatNumber) {
    _selectedSeat = seatNumber;
    notifyListeners();
  }

  void setPassengerInfo(String name, String dni) {
    _passengerName = name;
    _passengerDni = dni;
    notifyListeners();
  }
  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void reset() {
    _originProvince = null;
    _destinationProvince = null;
    _selectedDate = null;
    _selectedSchedule = null;
    _selectedSeat = null;
    _passengerName = '';
    _passengerDni = '';
    _paymentMethod = '';
    notifyListeners();
  }
}