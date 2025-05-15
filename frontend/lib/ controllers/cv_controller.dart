import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ services/api_service.dart';
import '../intl/language_provider.dart';
import '../models/analysis_result.dart';
import '../l10n/app_localizations.dart';

class CvController extends ChangeNotifier {
  final ApiService apiService;
  
  // State variables
  bool _isLoading = false;
  String? _error;
  PlatformFile? _selectedFile;
  AnalysisResult? _currentResult;
  String? _jobDescription;
  
  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  PlatformFile? get selectedFile => _selectedFile;
  AnalysisResult? get currentResult => _currentResult;
  String? get jobDescription => _jobDescription;
  
  // Constructor
  CvController({required this.apiService});
  
  // Set job description
  void setJobDescription(String? description) {
    _jobDescription = description;
    notifyListeners();
  }
  
  // Upload and analyze CV
  Future<void> uploadAndAnalyzeCV() async {
    try {
      // Reset error state
      _error = null;
      
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx'],
        withData: true,
      );
      
      // Check if file was selected
      if (result == null || result.files.isEmpty) {
        // User canceled the picker
        return;
      }
      
      _selectedFile = result.files.first;
      notifyListeners();
      
      // Analyze the CV
      await _analyzeCV();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // Retry analysis with current file
  Future<void> retryAnalysis() async {
    if (_selectedFile == null) {
      _error = 'No file selected'; // This should be localized if possible
      notifyListeners();
      return;
    }
    
    try {
      _error = null;
      await _analyzeCV();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // Private method to analyze CV
  Future<void> _analyzeCV() async {
    if (_selectedFile == null) {
      _error = 'No file selected'; // This should be localized
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Call API service
      final resultData = await apiService.analyzeCV(
        _selectedFile!,
        jobDescription: _jobDescription,
      );
      
      // Parse result
      _currentResult = AnalysisResult.fromJson(resultData);
      _error = null;
    } catch (e) {
      _error = e.toString();
      // Keep the current result if there is one
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Clear results and reset state
  void clearResults() {
    _currentResult = null;
    _error = null;
    notifyListeners();
  }
  
  // Update language based on CV content
  void updateLanguageBasedOnContent(BuildContext context) {
    if (_currentResult != null) {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      
      // Set language based on result language
      if (_currentResult!.isArabic && !languageProvider.isArabic) {
        languageProvider.setLocale(const Locale('ar', ''));
      } else if (!_currentResult!.isArabic && languageProvider.isArabic) {
        languageProvider.setLocale(const Locale('en', ''));
      }
    }
  }
  
  // Get localized error message
  String getLocalizedError(BuildContext context) {
    if (_error == null) return '';
    
    final appLocalizations = AppLocalizations.of(context);
    
    // Map common errors to localized messages
    if (_error!.contains('timed out')) {
      return appLocalizations.errorTimeout;
    } else if (_error!.contains('No file selected')) {
      return appLocalizations.errorNoFile;
    } else if (_error!.contains('Failed to analyze')) {
      return appLocalizations.errorAnalysisFailed;
    } else if (_error!.contains('Invalid file type')) {
      return appLocalizations.errorInvalidFile;
    } else if (_error!.contains('File size exceeds')) {
      return appLocalizations.errorFileSize;
    }
    
    // Default error message
    return _error!; // Or a generic localized error: appLocalizations.errorUnknown;
  }
}
