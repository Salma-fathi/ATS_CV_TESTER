import 'dart:ui';

import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ?? AppLocalizations(const Locale('en', ''));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'analysisResults': 'Analysis Results',
      'retry': 'Retry',
      'export': 'Export',
      'loadingResults': 'Loading results...',
      'noResultsFound': 'No results found',
      'uploadToSeeResults': 'Upload a CV to see analysis results',
      'summary': 'Summary',
      'version': 'Analysis Date',
      'jobDescription': 'Job Description',
      'skillsComparison': 'Skills Comparison',
      'educationComparison': 'Education Comparison',
      'experienceComparison': 'Experience Comparison',
      'recommendations': 'Recommendations',
      'searchabilityIssues': 'Searchability Issues',
      'keySkills': 'Key Skills',
      'atsCompatibilityScore': 'ATS Compatibility Score',
      'match': 'Match',
      'matchingSkills': 'Matching Skills',
      'missingSkills': 'Missing Skills',
      'noMatchingSkills': 'No matching skills found',
      'greatMatch': 'Great match! No missing skills detected',
      'noIssuesFound': 'No issues found',
      'excellent': 'Excellent',
      'good': 'Good',
      'needsImprovement': 'Needs Improvement',
      'exportSuccess': 'Results exported successfully',
      'scoreBreakdown': 'Score Breakdown',
      'errorTimeout': 'The request timed out. Please try again.',
      'errorNoFile': 'No file selected. Please select a file to upload.',
      'errorAnalysisFailed': 'Analysis failed. Please try again later.',
      'errorInvalidFile': 'Invalid file type. Please upload a valid CV file.',
      'errorFileSize': 'File size exceeds the limit. Please upload a smaller file.',
      'errorFileUpload': 'File upload error: Please try again or use a different browser',
      'errorFileData': 'File data could not be loaded. Please try again or select a different file.',
      'errorFileCorrupted': 'The selected file appears to be empty or corrupted. Please select a different file.',
      'errorFilePath': 'File path is unavailable. Please check your file and try again.',
      'errorFileEmpty': 'The selected file is empty. Please select a different file.',
      'erroranalysisFailed': 'The analysis failed. Please try again later.',
      'errorFileNotFound': 'The selected file was not found. Please select a different file.',
    },
    'ar': {
      'analysisResults': 'نتائج التحليل',
      'retry': 'إعادة المحاولة',
      'export': 'تصدير',
      'loadingResults': 'جاري تحميل النتائج...',
      'noResultsFound': 'لم يتم العثور على نتائج',
      'uploadToSeeResults': 'قم بتحميل سيرة ذاتية لرؤية نتائج التحليل',
      'summary': 'ملخص',
      'version': 'تاريخ التحليل',
      'jobDescription': 'وصف الوظيفة',
      'skillsComparison': 'مقارنة المهارات',
      'educationComparison': 'مقارنة التعليم',
      'experienceComparison': 'مقارنة الخبرة',
      'recommendations': 'التوصيات',
      'searchabilityIssues': 'مشاكل قابلية البحث',
      'keySkills': 'المهارات الرئيسية',
      'atsCompatibilityScore': 'درجة التوافق مع نظام تتبع المتقدمين',
      'match': 'تطابق',
      'matchingSkills': 'المهارات المتطابقة',
      'missingSkills': 'المهارات المفقودة',
      'noMatchingSkills': 'لم يتم العثور على مهارات متطابقة',
      'greatMatch': 'تطابق رائع! لم يتم اكتشاف مهارات مفقودة',
      'noIssuesFound': 'لم يتم العثور على مشاكل',
      'excellent': 'ممتاز',
      'good': 'جيد',
      'needsImprovement': 'يحتاج إلى تحسين',
      'exportSuccess': 'تم تصدير النتائج بنجاح',
      'scoreBreakdown': 'تفصيل الدرجات',
    },
  };

  String get analysisResults => _localizedValues[locale.languageCode]?['analysisResults'] ?? 'Analysis Results';
  String get retry => _localizedValues[locale.languageCode]?['retry'] ?? 'Retry';
  String get export => _localizedValues[locale.languageCode]?['export'] ?? 'Export';
  String get loadingResults => _localizedValues[locale.languageCode]?['loadingResults'] ?? 'Loading results...';
  String get noResultsFound => _localizedValues[locale.languageCode]?['noResultsFound'] ?? 'No results found';
  String get uploadToSeeResults => _localizedValues[locale.languageCode]?['uploadToSeeResults'] ?? 'Upload a CV to see analysis results';
  String get summary => _localizedValues[locale.languageCode]?['summary'] ?? 'Summary';
  String get version => _localizedValues[locale.languageCode]?['version'] ?? 'Analysis Date';
  String get jobDescription => _localizedValues[locale.languageCode]?['jobDescription'] ?? 'Job Description';
  String get skillsComparison => _localizedValues[locale.languageCode]?['skillsComparison'] ?? 'Skills Comparison';
  String get educationComparison => _localizedValues[locale.languageCode]?['educationComparison'] ?? 'Education Comparison';
  String get experienceComparison => _localizedValues[locale.languageCode]?['experienceComparison'] ?? 'Experience Comparison';
  String get recommendations => _localizedValues[locale.languageCode]?['recommendations'] ?? 'Recommendations';
  String get searchabilityIssues => _localizedValues[locale.languageCode]?['searchabilityIssues'] ?? 'Searchability Issues';
  String get keySkills => _localizedValues[locale.languageCode]?['keySkills'] ?? 'Key Skills';
  String get atsCompatibilityScore => _localizedValues[locale.languageCode]?['atsCompatibilityScore'] ?? 'ATS Compatibility Score';
  String get match => _localizedValues[locale.languageCode]?['match'] ?? 'Match';
  String get matchingSkills => _localizedValues[locale.languageCode]?['matchingSkills'] ?? 'Matching Skills';
  String get missingSkills => _localizedValues[locale.languageCode]?['missingSkills'] ?? 'Missing Skills';
  String get noMatchingSkills => _localizedValues[locale.languageCode]?['noMatchingSkills'] ?? 'No matching skills found';
  String get greatMatch => _localizedValues[locale.languageCode]?['greatMatch'] ?? 'Great match! No missing skills detected';
  String get noIssuesFound => _localizedValues[locale.languageCode]?['noIssuesFound'] ?? 'No issues found';
  String get excellent => _localizedValues[locale.languageCode]?['excellent'] ?? 'Excellent';
  String get good => _localizedValues[locale.languageCode]?['good'] ?? 'Good';
  String get needsImprovement => _localizedValues[locale.languageCode]?['needsImprovement'] ?? 'Needs Improvement';
  String get exportSuccess => _localizedValues[locale.languageCode]?['exportSuccess'] ?? 'Results exported successfully';
  String get scoreBreakdown => _localizedValues[locale.languageCode]?['scoreBreakdown'] ?? 'Score Breakdown';
  String get errorTimeout => _localizedValues[locale.languageCode]?['errorTimeout'] ?? 'The request timed out. Please try again.';
  String get errorNoFile => _localizedValues[locale.languageCode]?['errorNoFile'] ?? 'No file selected. Please select a file to upload.';
  String get errorAnalysisFailed => _localizedValues[locale.languageCode]?['errorAnalysisFailed'] ?? 'Analysis failed. Please try again later.';
  String get errorInvalidFile => _localizedValues[locale.languageCode]?['errorInvalidFile'] ?? 'Invalid file type. Please upload a valid CV file.';
  String get errorFileSize => _localizedValues[locale.languageCode]?['errorFileSize'] ?? 'File size exceeds the limit. Please upload a smaller file.';
  String get errorFileUpload => _localizedValues[locale.languageCode]?['errorFileUpload'] ?? 'File upload error: Please try again or use a different browser';
  String get errorFileData => _localizedValues[locale.languageCode]?['errorFileData'] ?? 'File data could not be loaded. Please try again or select a different file.';
  String get errorFileCorrupted => _localizedValues[locale.languageCode]?['errorFileCorrupted'] ?? 'The selected file appears to be empty or corrupted. Please select a different file.';
  String get errorFilePath => _localizedValues[locale.languageCode]?['errorFilePath'] ?? 'File path is unavailable. Please check your file and try again.';
  String get errorFileEmpty => _localizedValues[locale.languageCode]?['errorFileEmpty'] ?? 'The selected file is empty. Please select a different file.';
  String get errorFileNotFound => _localizedValues[locale.languageCode]?['errorFileNotFound'] ?? 'The selected file was not found. Please select a different file.';
  String get erroranalysisFailed => _localizedValues[locale.languageCode]?['erroranalysisFailed'] ?? 'The analysis failed. Please try again later.';
  
  }

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}