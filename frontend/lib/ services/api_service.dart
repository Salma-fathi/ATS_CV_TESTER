import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class ApiService {
  // Base URL for API calls
  final String baseUrl;
  
  // Configurable timeout durations
  final Duration analyzeTimeout;
  final Duration resultTimeout;
  final Duration healthTimeout;
  
  // Constructor with default values
  ApiService({
    this.baseUrl = 'http://localhost:5000/api',
    this.analyzeTimeout = const Duration(seconds: 60),
    this.resultTimeout = const Duration(seconds: 30),
    this.healthTimeout = const Duration(seconds: 5),
  });
  
  // Analyze CV with improved error handling and Arabic support
  Future<Map<String, dynamic>> analyzeCV(PlatformFile file, {String? jobDescription}) async {
    try {
      // Validate file
      if (file.bytes == null || file.bytes!.isEmpty) {
        throw Exception('File is empty or corrupted');
      }
      
      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/analyze'));
      
      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'cv',
          file.bytes!,
          filename: file.name,
        ),
      );
      
      // Add job description if provided
      if (jobDescription != null && jobDescription.isNotEmpty) {
        request.fields['job_description'] = jobDescription;
      }
      
      // Add language detection hint if filename contains Arabic characters
      if (_containsArabicCharacters(file.name)) {
        request.fields['language_hint'] = 'ar';
      }
      
      // Send request with timeout
      final streamedResponse = await request.send().timeout(analyzeTimeout);
      final response = await http.Response.fromStream(streamedResponse);
      
      // Handle response
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return _validateAndNormalizeResponse(responseData);
      } else {
        // Try to parse error message from response
        try {
          final errorData = json.decode(response.body);
          throw Exception(errorData['error'] ?? 'Failed to analyze CV: ${response.statusCode}');
        } catch (e) {
          // If parsing fails, return generic error with status code
          throw Exception('Failed to analyze CV: ${response.statusCode}');
        }
      }
    } on TimeoutException {
      throw Exception('Request timed out. The server is taking too long to respond.');
    } catch (e) {
      // Rethrow with more context if it's not already an Exception
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }
  
  // Get result by ID with improved error handling
  Future<Map<String, dynamic>> getResult(String resultId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/results/$resultId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(resultTimeout);
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return _validateAndNormalizeResponse(responseData);
      } else if (response.statusCode == 404) {
        throw Exception('Analysis result not found');
      } else {
        // Try to parse error message from response
        try {
          final errorData = json.decode(response.body);
          throw Exception(errorData['error'] ?? 'Failed to load analysis result: ${response.statusCode}');
        } catch (e) {
          throw Exception('Failed to load analysis result: ${response.statusCode}');
        }
      }
    } on TimeoutException {
      throw Exception('Request timed out. The server is taking too long to respond.');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }
  
  // Health check with improved error handling
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(healthTimeout);
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  // Helper method to check if text contains Arabic characters
  bool _containsArabicCharacters(String text) {
    // Arabic Unicode range
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    return arabicRegex.hasMatch(text);
  }
  
  // Helper method to validate and normalize API response
  Map<String, dynamic> _validateAndNormalizeResponse(Map<String, dynamic> response) {
    // Ensure all expected fields exist with default values if missing
    final normalizedResponse = {
      'id': response['id'] ?? '',
      'score': response['score'] ?? 0,
      'keywords': response['keywords'] ?? <String>[],
      'summary': response['summary'] ?? '',
      'analysis_date': response['analysis_date'] ?? DateTime.now().toIso8601String(),
      'skills_comparison': response['skills_comparison'] ?? {},
      'searchability_issues': response['searchability_issues'] ?? <String>[],
      'education_comparison': response['education_comparison'] ?? <String>[],
      'experience_comparison': response['experience_comparison'] ?? <String>[],
      'job_description': response['job_description'] ?? '',
      'recommendations': response['recommendations'] ?? <String>[],
      // Add language detection fields
      'language': response['language'] ?? 'en',
      'direction': response['direction'] ?? 'ltr',
    };
    
    // If language is not explicitly set, try to detect from content
    if (!response.containsKey('language')) {
      normalizedResponse['language'] = _detectLanguageFromContent(response);
      normalizedResponse['direction'] = normalizedResponse['language'] == 'ar' ? 'rtl' : 'ltr';
    }
    
    return normalizedResponse;
  }
  
  // Helper method to detect language from content
  String _detectLanguageFromContent(Map<String, dynamic> response) {
    // Check summary and keywords for Arabic characters
    final summary = response['summary'] as String? ?? '';
    final keywords = response['keywords'] ?? <String>[];
    
    String keywordsText = '';
    if (keywords is List) {
      keywordsText = keywords.join(' ');
    }
    
    final combinedText = summary + ' ' + keywordsText;
    
    return _containsArabicCharacters(combinedText) ? 'ar' : 'en';
  }
}