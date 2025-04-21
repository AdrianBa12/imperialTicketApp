class HorarioAutobus {
  final int id;
  final String documentId;
  final int asientosDisponibles;
  final int totalDeAsiento;
  final double precio;
  final DateTime fechaDeLlegada;
  final DateTime fechaDeSalida;
  final String claseDeBus;
  final String numeroPLacaBus;
  final dynamic terminalSalidaId;
  final dynamic terminalLlegadaId;
  final int duracionEnHoras;

  HorarioAutobus({
    required this.id,
    required this.documentId,
    required this.asientosDisponibles,
    required this.totalDeAsiento,
    required this.precio,
    required this.fechaDeLlegada,
    required this.fechaDeSalida,
    required this.claseDeBus,
    required this.numeroPLacaBus,
    required this.terminalSalidaId,
    required this.terminalLlegadaId,
    required this.duracionEnHoras,
  });

  factory HorarioAutobus.fromJson(Map<String, dynamic> json) {
  return HorarioAutobus(
    id: json['id'],
    documentId: json['documentId'],
    asientosDisponibles: (json['mapaDeAsientos'] as List)
        .where((a) => a['estado'] == 'disponible')
        .length,
    totalDeAsiento: (json['mapaDeAsientos'] as List).length,
    precio: json['precio'].toDouble(),
    fechaDeLlegada: DateTime.parse(json['fechaDeLlegada']),
    fechaDeSalida: DateTime.parse(json['fechaDeSalida']),
    claseDeBus: json['claseDeBus'],
    numeroPLacaBus: json['numeroPLacaBus'] ?? 'Desconocido', 
    terminalSalidaId: json['terminalSalidaId'] ?? '',
    terminalLlegadaId: json['terminalLlegadaId'] ?? '',
    duracionEnHoras: json['duracionEnHoras'],
  );
}
}


