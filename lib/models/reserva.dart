class Reserva {
  final int numeroDeasiento;
  final String nombreCompleto;
  final String numeroDocumento;
  final String tipoDocumento;
  final String horarioDeAutobus;
  final String usuario;

  Reserva({
    required this.numeroDeasiento,
    required this.nombreCompleto,
    required this.numeroDocumento,
    required this.tipoDocumento,
    required this.horarioDeAutobus,
    required this.usuario,
  });

  Map<String, dynamic> toJson() {
    return {
      'numeroDeasiento': numeroDeasiento,
      'nombreCompleto': nombreCompleto,
      'numeroDocumento': numeroDocumento,
      'tipoDocumento': tipoDocumento,
      'horario_de_autobus': horarioDeAutobus,
      'usuario': usuario,
    };
  }
}