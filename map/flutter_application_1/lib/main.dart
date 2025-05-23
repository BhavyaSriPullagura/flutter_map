import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'pickup_location.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Responsive Drag Pin Location Picker',
      debugShowCheckedModeBanner: false,
      home: const LocationPickerScreen(),
    );
  }
}

   

