class Asiento {
  final int number;
  final String estado;

  Asiento({required this.number, required this.estado});

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'estado': estado,
    };
  }
}