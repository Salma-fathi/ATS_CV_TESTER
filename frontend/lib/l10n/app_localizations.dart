// lib/l10n/app_localizations.dart
import "package:flutter/material.dart";
import "l10n_en.dart" as l10n_en;
import "l10n_ar.dart" as l10n_ar;

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) 
        ?? AppLocalizations(const Locale("en", "")); // Default to English if not found
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    "en": l10n_en.translations,
    "ar": l10n_ar.translations,
  };

  String _getString(String key, String defaultValue) {
    return _localizedValues[locale.languageCode]?[key] ?? 
           _localizedValues["en"]?[key] ?? // Fallback to English if key not in current lang
           defaultValue; // Fallback to default if key not in English either
  }

  // General UI
  String get analysisResults => _getString("analysisResults", "Analysis Results");
  String get retry => _getString("retry", "Retry");
  String get export => _getString("export", "Export");
  String get loadingResults => _getString("loadingResults", "Loading results...");
  String get noResultsFound => _getString("noResultsFound", "No results found.");
  String get uploadToSeeResults => _getString("uploadToSeeResults", "Upload a CV to see the analysis results here.");
  String get version => _getString("version", "Analysis Date"); // Used for Analysis Date section title
  String get jobDescription => _getString("jobDescription", "Job Description");
  String get summary => _getString("summary", "Summary");
  String get keySkills => _getString("keySkills", "Key Skills");
  String get recommendations => _getString("recommendations", "Recommendations");
  String get searchabilityIssues => _getString("searchabilityIssues", "Searchability Issues");
  String get settings => _getString("settings", "Settings");
  String get language => _getString("language", "Language");
  String get selectLanguage => _getString("selectLanguage", "Select Language");
  String get english => _getString("english", "English");
  String get arabic => _getString("arabic", "Arabic");
  String get uploadCV => _getString("uploadCV", "Upload CV");
  String get changeFile => _getString("changeFile", "Change File");
  String get selectedFile => _getString("selectedFile", "Selected File");
  String get orDragAndDrop => _getString("orDragAndDrop", "or drag and drop here (PDF or DOCX)");
  String get analyze => _getString("analyze", "Analyze");
  String get addJobDescription => _getString("addJobDescription", "Add Job Description (Optional)");
  String get pasteJobDescription => _getString("pasteJobDescription", "Paste job description here...");
  String get clear => _getString("clear", "Clear");

  // Analysis Screen Specific
  String get match => _getString("match", "Match");
  String get educationComparison => _getString("educationComparison", "Education Comparison");
  String get experienceComparison => _getString("experienceComparison", "Experience Comparison");
  String get skillsComparison => _getString("skillsComparison", "Skills Comparison");
  String get matchingSkills => _getString("matchingSkills", "Matching Skills");
  String get noMatchingSkills => _getString("noMatchingSkills", "No matching skills found.");
  String get missingSkills => _getString("missingSkills", "Missing Skills");
  String get greatMatch => _getString("greatMatch", "Great match! No missing skills found.");
  String get atsCompatibilityScore => _getString("atsCompatibilityScore", "ATS Compatibility Score"); // Added
  String get noIssuesFound => _getString("noIssuesFound", "No issues found."); // Added
  
  // Score related
  String get excellent => _getString("excellent", "Excellent");
  String get good => _getString("good", "Good");
  String get needsImprovement => _getString("needsImprovement", "Needs Improvement");

  // Error messages
  String get errorTimeout => _getString("errorTimeout", "The request timed out. Please try again.");
  String get errorNoFile => _getString("errorNoFile", "No file selected. Please select a CV to analyze.");
  String get errorAnalysisFailed => _getString("errorAnalysisFailed", "Analysis failed. Please try again or check the file.");
  String get errorInvalidFile => _getString("errorInvalidFile", "Invalid file type. Please upload a PDF or DOCX file.");
  String get errorFileSize => _getString("errorFileSize", "File size exceeds the limit.");
  String get errorUnknown => _getString("errorUnknown", "An unknown error occurred.");
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ["en", "ar"].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
