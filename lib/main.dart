import 'package:flutter/material.dart';
import 'package:gym_tracker/common/utils/getit_utils.dart';

void main() async {
  await GetItUtils.setup();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gym tracker',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const Scaffold(),
    );
  }
}
