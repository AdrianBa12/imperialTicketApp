import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';

typedef SeatStatusCallback = void Function(Map<String, dynamic> data);

class SocketService {

  static IO.Socket? _socket;
  static bool _isConnected = false;
  static String? _currentUserId;
  static final Map<String, Function> _listeners = {};

  // Getters
  bool get isConnected => _isConnected;
  String? get currentUserId => _currentUserId;
  // Callbacks
  final List<SeatStatusCallback> _seatStatusCallbacks = [];

  static Future<void> initSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('firebaseToken') ?? '';

    _socket = IO.io('http://192.168.101.5:5000/api', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'auth': {'token': token},
    });

    _socket!.onConnect((_) {
      if (kDebugMode) {
        print('🔌 Socket conectado');
      }
      _isConnected = true;
    });

    _socket!.onDisconnect((_) {
      if (kDebugMode) {
        print('❌ Socket desconectado');
      }
      _isConnected = false;
    });

    _socket!.onError((error) {
      if (kDebugMode) {
        print('⚠️ Socket error: $error');
      }
    });
  }



  // Join a bus room to get real-time seat updates
  static void joinBusRoom(String busId, DateTime date) {
    final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    if (_socket != null) {
      _socket!.emit('join-bus', {
        'busId': busId,
        'date': formattedDate,
      });
    }
  }

  // Leave a bus room
  static void leaveBusRoom(String busId, DateTime date) {
    final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    if (_socket != null) {
      _socket!.emit('leave-bus', {
        'busId': busId,
        'date': formattedDate,
      });
    }
  }

  static void selectSeats(String busId, DateTime date, List<String> seats) async {
    final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? 'guest';

    if (_socket != null) {
      _socket!.emit('select-seat', { // Cambiado de 'select-seats' a 'select-seat'
        'busId': busId,
        'date': formattedDate,
        'seats': seats,
        'userId': userId,
      });
    }
  }

  static void releaseSeats(String busId, DateTime date, List<String> seats) async {
    final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? 'guest';

    if (_socket != null) {
      _socket!.emit('deselect-seat', { // Cambiado de 'release-seats' a 'deselect-seat'
        'busId': busId,
        'date': formattedDate,
        'seats': seats,
        'userId': userId,
      });
    }
  }

  static void onSeatsSelected(Function(List<String>, String) callback) {
    if (_socket != null) {
      _socket!.off('seats-selected'); // Eliminar cualquier listener previo

      _socket!.on('seats-selected', (data) {
        callback(List<String>.from(data['seats']), data['userId']);
      });

      _listeners['seats-selected'] = callback;
    }
  }

  static void onSeatsReleased(Function(List<String>, String) callback) {
    if (_socket != null) {
      _socket!.off('seats-released'); // Eliminar cualquier listener previo

      _socket!.on('seats-released', (data) {
        callback(List<String>.from(data['seats']), data['userId']);
      });

      _listeners['seats-released'] = callback;
    }
  }

  static void notifyNewBooking(String busId, DateTime date, List<String> seats) {
    final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    if (_socket != null) {
      _socket!.emit('booking-confirmed', { // Cambiado de 'new-booking' a 'booking-confirmed'
        'busId': busId,
        'date': formattedDate,
        'seats': seats,
      });
    }
  }

  static void notifyCancelBooking(String busId, DateTime date, List<String> seats) {
    final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    if (_socket != null) {
      _socket!.emit('booking-cancelled', { // Cambiado de 'cancel-booking' a 'booking-cancelled'
        'busId': busId,
        'date': formattedDate,
        'seats': seats,
      });
    }
  }
  static void onBookingConfirmed(Function(List<String>) callback) {
    if (_socket != null) {
      _socket!.on('booking-confirmed', (data) {
        callback(List<String>.from(data['seats']));
      });

      _listeners['booking-confirmed'] = callback;
    }
  }

  static void onBookingCancelled(Function(List<String>) callback) {
    if (_socket != null) {
      _socket!.on('booking-cancelled', (data) {
        callback(List<String>.from(data['seats']));
      });

      _listeners['booking-cancelled'] = callback;
    }
  }



  // Remove all listeners
  static void removeAllListeners() {
    if (_socket != null) {
      _listeners.forEach((event, _) {
        _socket!.off(event);
      });

      _listeners.clear();
    }
  }

  // Disconnect socket
  static void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }
  }

  // Listen for seat status changes
  void onSeatStatusChanged(SeatStatusCallback callback) {
    _seatStatusCallbacks.add(callback);
  }

  // Remove seat status change listener
  void offSeatStatusChanged() {
    _seatStatusCallbacks.clear();
  }

  // Release a seat
  void releaseSeat(String busId, String seatId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('release-seat', {
        'busId': busId,
        'seatId': seatId,
        'userId': _currentUserId,
      });
    }
  }


  void holdSeat(String busId, String seatId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('hold-seat', {
        'busId': busId,
        'seatId': seatId,
        'userId': _currentUserId,
      });
    }
  }
}

