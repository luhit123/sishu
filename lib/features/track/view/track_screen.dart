import 'package:flutter/material.dart';

class TrackScreen extends StatelessWidget {
  const TrackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track'),
      ),
      body: const Center(
        child: Text(
          'Growth & Vaccination Tracker Placeholder',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
