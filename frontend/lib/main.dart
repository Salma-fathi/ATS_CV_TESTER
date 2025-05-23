import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import ' controllers/cv_controller.dart';
import ' controllers/result_controller.dart' show ResultController;
import ' services/api_service.dart';
import ' widgets/analysis_provider.dart';
import 'utils/language_provider.dart/language_provider.dart';
import 'views/home_page.dart';

// Define brand colors as constants for consistent usage throughout the app
class AppColors {
  // Primary brand colors
  static const Color primary = Color(0xFF00BFA5); // Teal as primary brand color
  static const Color secondary = Color(0xFF546E7A); // Blue-grey as secondary color
  
  // Score indicator colors
  static const Color scoreHigh = Color(0xFF4CAF50); // Green for high scores
  static const Color scoreMedium = Color(0xFFFFC107); // Amber for medium scores
  static const Color scoreLow = Color(0xFFF44336); // Red for low scores
  
  // Background colors
  static const Color backgroundDark = Color(0xFF212121);
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color cardBackground = Color(0xFF2A2A2A);
  
  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color textHighlight = Color(0xFF80CBC4);
}

void main() {
  // Initialize the API service
  final apiService = ApiService();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(),
        ),
        ChangeNotifierProxyProvider<LanguageProvider, CvController>(
          create: (context) => CvController(
            apiService: apiService,
            languageProvider: Provider.of<LanguageProvider>(context, listen: false),
          ),
          update: (context, languageProvider, previous) => 
            previous ?? CvController(
              apiService: apiService,
              languageProvider: languageProvider
            ),
        ),
        // Provide the ResultController with the ApiService
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
      title: 'ResumeWise AI',
      theme: ThemeData.dark().copyWith(
        // Apply custom brand colors to theme
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        cardColor: AppColors.cardBackground,
        
        // Custom app bar theme
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.backgroundDark,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: AppColors.textPrimary,
          ),
          iconTheme: IconThemeData(
            color: AppColors.primary,
          ),
        ),
        
        // Custom text theme
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            fontSize: 28,
            color: AppColors.textPrimary,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            fontSize: 24,
            color: AppColors.textPrimary,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: AppColors.textPrimary,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w500,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.normal,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.normal,
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        
        // Custom button theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        
        // Custom input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.cardBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          hintStyle: const TextStyle(color: AppColors.textSecondary),
        ),
        
        // Custom card theme
        cardTheme: CardTheme(
          color: AppColors.cardBackground,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
        ),
      ),
      home: const HomePage(),
    );
  }
}