import 'package:flutter/material.dart';

class ExerciseLibraryView extends StatelessWidget {
  const ExerciseLibraryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Library'),
      ),
      body: const Center(
        child: Text('Màn hình Exercise Library'),
      ),
    );
  }
}
