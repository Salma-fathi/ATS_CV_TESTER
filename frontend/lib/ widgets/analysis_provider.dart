import 'package:flutter/material.dart';
import '../models/analysis_result.dart';

class AnalysisProvider with ChangeNotifier {
  AnalysisResult? _currentResult;
  String? _analysisError;

  AnalysisResult? get currentResult => _currentResult;
  String? get error => _analysisError;

  void setResult(AnalysisResult result) {
    _currentResult = result;
    _analysisError = null;
    notifyListeners();
  }

  void setError(String error) {
    _currentResult = null;
    _analysisError = error;
    notifyListeners();
  }

  void clear() {
    _currentResult = null;
    _analysisError = null;
    notifyListeners();
  }
}