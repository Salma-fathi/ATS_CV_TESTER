import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:frontend/utils/language_provider.dart/language_provider.dart';
import '../ services/api_service.dart';
import '../models/analysis_result.dart';
import '../l10n/app_localizations.dart';

class CvController extends ChangeNotifier {
  final ApiService apiService;
  final LanguageProvider languageProvider;
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
  CvController({required this.apiService , required this.languageProvider});
  
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
      
      // Pick file with proper configuration for all platforms
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'txt'],
        withData: true, // Important: Always get the bytes data for cross-platform compatibility
      );
      
      // Check if file was selected
      if (result == null || result.files.isEmpty) {
        // User canceled the picker
        return;
      }
      
      _selectedFile = result.files.first;
      
      // Verify bytes are available (required by the API)
      if (_selectedFile!.bytes == null || _selectedFile!.bytes!.isEmpty) {
        _error = 'File data could not be loaded. Please try again or select a different file.';
        notifyListeners();
        return;
      }
      
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
    
    // Verify bytes are available (required by the API)
    if (_selectedFile!.bytes == null || _selectedFile!.bytes!.isEmpty) {
      _error = 'File data could not be loaded. Please try again or select a different file.';
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Call API service - the ApiService already handles bytes-based uploads
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
  
  // Update language based on CV contents
    void updateLanguageBasedOnContent() {
    if (_currentResult != null) {
      // Now using the injected languageProvider instead of Provider.of
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
    } else if (_error!.contains('path') && _error!.contains('unavailable')) {
      return 'File upload error: Please try again or use a different browser';
    } else if (_error!.contains('File data could not be loaded')) {
      return 'File data could not be loaded. Please try again or select a different file.';
    } else if (_error!.contains('File is empty or corrupted')) {
      return 'The selected file appears to be empty or corrupted. Please select a different file.';
    }
    
    // Default error message
    return _error!; // Or a generic localized error: appLocalizations.errorUnknown;
  }
}
