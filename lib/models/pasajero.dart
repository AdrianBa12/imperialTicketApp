class Pasajero {
  int seatNo;
  String tipoDocumento;
  String numeroDocumento;
  String nombreCompleto;
  int? edad;

  Pasajero({
    required this.seatNo,
    this.tipoDocumento = 'dni',
    this.numeroDocumento = '',
    this.nombreCompleto = '',
    this.edad,
  });
}