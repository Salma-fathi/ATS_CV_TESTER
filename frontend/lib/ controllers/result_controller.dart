import 'package:flutter/material.dart';
import '../ services/api_service.dart';
import '../models/analysis_result.dart';

class ResultController extends ChangeNotifier {
  final ApiService apiService;
  
  // State variables
  bool _isLoading = false;
  String? _error;
  AnalysisResult? _result;
  
  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  AnalysisResult? get result => _result;
  
  // Constructor
  ResultController({required this.apiService});
  
  // Load result by ID
  Future<void> loadResult(String resultId) async {
    if (resultId.isEmpty) {
      _error = 'Invalid result ID';
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final resultData = await apiService.getResult(resultId);
      _result = AnalysisResult.fromJson(resultData);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Clear result
  void clearResult() {
    _result = null;
    _error = null;
    notifyListeners();
  }
  
  // Export results to JSON
  Future<Map<String, dynamic>?> exportResults() async {
    if (_result == null) {
      throw Exception('No result to export');
    }
    
    try {
      // In a real app, this would call an API or save to a file
      // For now, we'll just return the data
      return _result!.toExportMap();
    } catch (e) {
      throw Exception('Failed to export results: ${e.toString()}');
    }
  }
}