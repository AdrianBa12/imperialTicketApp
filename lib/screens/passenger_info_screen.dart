import 'package:flutter/material.dart';
import 'package:imperialticketapp/providers/ticket_provider.dart';

import 'package:provider/provider.dart';

class PassengerInfoScreen extends StatefulWidget {
  const PassengerInfoScreen({super.key});
  @override
  State<PassengerInfoScreen> createState() => _PassengerInfoScreenState();
}

class _PassengerInfoScreenState extends State<PassengerInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dniController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Información del Pasajero')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre Completo'),
                validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dniController,
                decoration: const InputDecoration(labelText: 'DNI'),
                keyboardType: TextInputType.number,
                validator: (value) => value?.length != 8 ? 'DNI debe tener 8 dígitos' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Continuar a Pago'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      Provider.of<TicketProvider>(context, listen: false)
        .setPassengerInfo(_nameController.text, _dniController.text);
      Navigator.pushNamed(context, '/payment');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dniController.dispose();
    super.dispose();
  }
}