import 'package:flutter/material.dart';

class CaloTrackingView extends StatelessWidget {
  const CaloTrackingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calo Tracking'),
      ),
      body: const Center(
        child: Text('Màn hình Calo Tracking'),
      ),
    );
  }
}
