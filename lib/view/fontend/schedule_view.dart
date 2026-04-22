import 'package:flutter/material.dart';

class ScheduleView extends StatelessWidget {
  const ScheduleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Training'),
      ),
      body: const Center(
        child: Text('Màn hình Schedule Training'),
      ),
    );
  }
}
