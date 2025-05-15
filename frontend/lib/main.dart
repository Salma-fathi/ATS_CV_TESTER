import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import ' controllers/cv_controller.dart';
import ' controllers/result_controller.dart' show ResultController;
import ' services/api_service.dart';
import ' widgets/analysis_provider.dart';
import 'views/home_page.dart';

void main() {
  // Initialize the API service
  final apiService = ApiService();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CvController(apiService: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => ResultController(apiService: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => AnalysisProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ATS CV Analyzer',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black87,
          elevation: 2,
        ),
      ),
      home: const HomePage(),
    );
  }
}
