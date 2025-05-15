import 'package:json_annotation/json_annotation.dart';

part 'analysis_result.g.dart';

@JsonSerializable(explicitToJson: true)
class AnalysisResult {
  final String id;
  final int score;
  final List<String> keywords;
  final String summary;
  
  @JsonKey(name: 'education_comparison')
  final List<String> educationComparison;
  
  @JsonKey(name: 'experience_comparison')
  final List<String> experienceComparison;
  
  @JsonKey(name: 'job_description')
  final String jobDescription;
  
  final List<String> recommendations;

  @JsonKey(name: 'analysis_date')
  final DateTime analysisDate;
  
  @JsonKey(name: 'skills_comparison')
  final Map<String, dynamic> skillsComparison;

  @JsonKey(name: 'searchability_issues')
  final List<String> searchabilityIssues;
  
  // Added for language support
  @JsonKey(name: 'language')
  final String language;
  
  @JsonKey(name: 'direction')
  final String direction;

  AnalysisResult({
    required this.id,
    required this.score,
    required this.keywords,
    required this.summary,
    required this.analysisDate,
    required this.skillsComparison,
    required this.searchabilityIssues,
    required this.educationComparison,
    required this.experienceComparison,
    required this.jobDescription,
    required this.recommendations,
    this.language = 'en',
    this.direction = 'ltr',
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      id: json['id'] as String,
      score: json['score'] as int,
      keywords: _parseStringList(json['keywords']),
      summary: json['summary'] as String? ?? 'No summary available',
      analysisDate: DateTime.parse(json['analysis_date'] as String),
      skillsComparison: _parseSkillsComparison(json['skills_comparison']),
      searchabilityIssues: _parseStringList(json['searchability_issues']),
      educationComparison: _parseStringList(json['education_comparison']),
      experienceComparison: _parseStringList(json['experience_comparison']),
      jobDescription: _parseJobDescription(json['job_description']),
      recommendations: _parseStringList(json['recommendations']),
      language: json['language'] as String? ?? _detectLanguage(json),
      direction: json['direction'] as String? ?? _detectDirection(json),
    );
  }

  // Helper method to safely parse string lists
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    } else if (value is String) {
      // If it's a single string, return as a one-item list
      return [value];
    }
    
    return [];
  }

  // Helper method to safely parse skills comparison
  static Map<String, dynamic> _parseSkillsComparison(dynamic value) {
    if (value == null) return {};
    
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    } else if (value is String) {
      // If it's a string (unlikely but handling edge case)
      try {
        // This is a simplification - in real code you might use json.decode
        return {'message': value};
      } catch (e) {
        return {'message': value};
      }
    }
    
    return {};
  }

  // Helper method to parse job description
  static String _parseJobDescription(dynamic value) {
    if (value == null) return '';
    
    if (value is String) {
      return value;
    } else if (value is Map) {
      // If it's a map with a message field (as in the backend code)
      return value['message'] as String? ?? '';
    }
    
    return '';
  }
  
  // Detect language based on content
  static String _detectLanguage(Map<String, dynamic> json) {
    // Simple detection based on summary and keywords
    final summary = json['summary'] as String? ?? '';
    final keywords = json['keywords'] ?? [];
    
    String keywordsText = '';
    if (keywords is List) {
      keywordsText = keywords.join(' ');
    } else if (keywords is String) {
      keywordsText = keywords;
    }
    
    final combinedText = summary + ' ' + keywordsText;
    
    // Check for Arabic characters
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    final latinRegex = RegExp(r'[a-zA-Z]');
    
    final arabicMatches = arabicRegex.allMatches(combinedText).length;
    final latinMatches = latinRegex.allMatches(combinedText).length;
    
    return arabicMatches > latinMatches ? 'ar' : 'en';
  }
  
  // Detect text direction based on language
  static String _detectDirection(Map<String, dynamic> json) {
    final language = json['language'] as String? ?? _detectLanguage(json);
    return language == 'ar' ? 'rtl' : 'ltr';
  }

  // Add a method to convert to a map for export
  Map<String, dynamic> toExportMap() {
    return {
      'id': id,
      'score': score,
      'summary': summary,
      'keywords': keywords,
      'skills_comparison': skillsComparison,
      'education_comparison': educationComparison,
      'experience_comparison': experienceComparison,
      'recommendations': recommendations,
      'searchability_issues': searchabilityIssues,
      'analysis_date': analysisDate.toIso8601String(),
      'language': language,
      'direction': direction,
    };
  }
  
  // Check if content is in Arabic
  bool get isArabic => language == 'ar';
  
  // Check if content should be displayed RTL
  bool get isRtl => direction == 'rtl';
}