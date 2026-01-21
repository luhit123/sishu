import 'package:flutter/material.dart';

class ConsultScreen extends StatelessWidget {
  const ConsultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consult'),
      ),
      body: const Center(
        child: Text(
          'Doctor Consultation Placeholder',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
