import 'package:flutter/material.dart';

class SimplePage extends StatelessWidget {
  final String title;
  const SimplePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('TODO: $title', style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
