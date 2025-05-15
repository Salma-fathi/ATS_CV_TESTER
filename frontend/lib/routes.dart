// lib/routes.dart
import 'package:flutter/material.dart';
import 'views/home_page.dart';
import 'views/upload_page.dart';
import 'views/results_page.dart';
// Import other pages as needed

final Map<String, WidgetBuilder> routes = {
  '/home': (context) => HomePage(),
  '/upload': (context) => UploadPage(),
  '/results': (context) => ResultsPage(), // Ensure this route exists
  // Add other routes here
};