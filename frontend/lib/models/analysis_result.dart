import 'package:flutter/material.dart';
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

  // Added for detailed score breakdown
  @JsonKey(name: 'score_breakdown')
  final Map<String, dynamic>? scoreBreakdown;
  
  // Added for detailed component scores
  @JsonKey(name: 'keyword_match_score')
  final int keywordMatchScore;
  
  @JsonKey(name: 'formatting_score')
  final int formattingScore;
  
  @JsonKey(name: 'content_score')
  final int contentScore;
  
  @JsonKey(name: 'readability_score')
  final int readabilityScore;
  
  // Added for industry information
  @JsonKey(name: 'industry')
  final String industry;
  
  // Added for section identification
  @JsonKey(name: 'identified_sections')
  final List<String> identifiedSections;
  
  @JsonKey(name: 'missing_sections')
  final List<String> missingSections;
  
  // Added for version tracking
  @JsonKey(name: 'analysis_version')
  final String analysisVersion;

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
    required this.keywordMatchScore,
    required this.formattingScore,
    required this.contentScore,
    required this.readabilityScore,
    required this.industry,
    this.language = 'en',
    this.direction = 'ltr',
    this.scoreBreakdown = const {},
    this.identifiedSections = const [],
    this.missingSections = const [],
    this.analysisVersion = '1.0',
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    // Extract scores from score_breakdown if available
    Map<String, dynamic>? scoreBreakdown = json['score_breakdown'] as Map<String, dynamic>?;
    
    // Default score to use if no other source is available
    int defaultScore = (json['score'] as int?) ?? 70;
    
    // Extract keyword match score with fallbacks
    int keywordMatchScore = 0;
    if (scoreBreakdown != null && scoreBreakdown['keyword_score'] != null) {
      keywordMatchScore = scoreBreakdown['keyword_score'] as int;
    } else if (json['keyword_match_score'] != null) {
      keywordMatchScore = json['keyword_match_score'] as int;
    } else {
      // Fallback to a percentage of the overall score
      keywordMatchScore = (defaultScore * 0.8).round();
    }
    
    // Extract formatting score with fallbacks
    int formattingScore = 0;
    if (scoreBreakdown != null && scoreBreakdown['format_score'] != null) {
      formattingScore = scoreBreakdown['format_score'] as int;
    } else if (json['formatting_score'] != null) {
      formattingScore = json['formatting_score'] as int;
    } else {
      // Fallback to a percentage of the overall score
      formattingScore = (defaultScore * 0.85).round();
    }
    
    // Extract content score with fallbacks
    int contentScore = 0;
    if (scoreBreakdown != null && scoreBreakdown['content_score'] != null) {
      contentScore = scoreBreakdown['content_score'] as int;
    } else if (json['content_score'] != null) {
      contentScore = json['content_score'] as int;
    } else {
      // Fallback to a percentage of the overall score
      contentScore = (defaultScore * 0.75).round();
    }
    
    // Extract readability score with fallbacks
    int readabilityScore = 0;
    if (scoreBreakdown != null && scoreBreakdown['readability_score'] != null) {
      readabilityScore = scoreBreakdown['readability_score'] as int;
    } else if (json['readability_score'] != null) {
      readabilityScore = json['readability_score'] as int;
    } else {
      // Fallback to a percentage of the overall score
      readabilityScore = (defaultScore * 0.9).round();
    }
    
    // If overall score is 0 but component scores are not, calculate a weighted average
    int overallScore = json['score'] as int? ?? 0;
    if (overallScore == 0 && (keywordMatchScore > 0 || formattingScore > 0 || 
                             contentScore > 0 || readabilityScore > 0)) {
      overallScore = ((keywordMatchScore * 0.4) + 
                      (formattingScore * 0.2) + 
                      (contentScore * 0.3) + 
                      (readabilityScore * 0.1)).round();
    }
    
    return AnalysisResult(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      score: overallScore,
      keywords: _parseStringList(json['keywords']),
      summary: json['summary'] as String? ?? 'No summary available',
      analysisDate: json['analysis_date'] != null 
          ? DateTime.parse(json['analysis_date'] as String)
          : DateTime.now(),
      skillsComparison: _parseSkillsComparison(json['skills_comparison']),
      searchabilityIssues: _parseStringList(json['searchability_issues']),
      educationComparison: _parseStringList(json['education_comparison']),
      experienceComparison: _parseStringList(json['experience_comparison']),
      jobDescription: _parseJobDescription(json['job_description']),
      recommendations: _parseStringList(json['recommendations']),
      language: json['language'] as String? ?? _detectLanguage(json),
      direction: json['direction'] as String? ?? _detectDirection(json),
      scoreBreakdown: scoreBreakdown?.map(
        (k, e) => MapEntry(k, e),
      ) ?? const {},
      keywordMatchScore: keywordMatchScore,
      formattingScore: formattingScore,
      contentScore: contentScore,
      readabilityScore: readabilityScore,
      industry: json['industry'] as String? ?? 'General',
      identifiedSections: _parseStringList(json['identified_sections']),
      missingSections: _parseStringList(json['missing_sections']),
      analysisVersion: json['analysis_version'] as String? ?? '1.0',
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
    if (value == null) return {
      'matching_keywords': <String>[],
      'missing_keywords': <String>[],
      'match_percentage': 0.0
    };
    
    if (value is Map) {
      // Ensure the map has all required keys with default values
      Map<String, dynamic> result = Map<String, dynamic>.from(value);
      
      // Set defaults for missing keys
      if (!result.containsKey('matching_keywords')) {
        result['matching_keywords'] = <String>[];
      } else if (result['matching_keywords'] is! List) {
        result['matching_keywords'] = <String>[];
      }
      
      if (!result.containsKey('missing_keywords')) {
        result['missing_keywords'] = <String>[];
      } else if (result['missing_keywords'] is! List) {
        result['missing_keywords'] = <String>[];
      }
      
      if (!result.containsKey('match_percentage')) {
        result['match_percentage'] = 0.0;
      } else if (result['match_percentage'] is int) {
        result['match_percentage'] = (result['match_percentage'] as int).toDouble();
      }
      
      return result;
    } else if (value is String) {
      // If it's a string (unlikely but handling edge case)
      return {
        'message': value,
        'matching_keywords': <String>[],
        'missing_keywords': <String>[],
        'match_percentage': 0.0
      };
    }
    
    return {
      'matching_keywords': <String>[],
      'missing_keywords': <String>[],
      'match_percentage': 0.0
    };
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
      'score_breakdown': scoreBreakdown,
      'keyword_match_score': keywordMatchScore,
      'formatting_score': formattingScore,
      'content_score': contentScore,
      'readability_score': readabilityScore,
      'industry': industry,
      'identified_sections': identifiedSections,
      'missing_sections': missingSections,
      'analysis_version': analysisVersion,
    };
  }
  
  // Check if content is in Arabic
  bool get isArabic => language == 'ar';
  
  // Check if content should be displayed RTL
  bool get isRtl => direction == 'rtl';

  // Get score rating based on score value
  String getScoreRating(dynamic localizations) {
    if (score >= 80) {
      return localizations.excellent;
    } else if (score >= 60) {
      return localizations.good;
    } else {
      return localizations.needsImprovement;
    }
  }

  // Get score color based on score value
  Color getScoreColor() {
    if (score >= 80) {
      return Colors.green;
    } else if (score >= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  // Check if the result has detailed education comparison
  bool get hasEducationComparison => educationComparison.isNotEmpty;

  // Check if the result has detailed experience comparison
  bool get hasExperienceComparison => experienceComparison.isNotEmpty;

  // Check if the result has job description
  bool get hasJobDescription => jobDescription.isNotEmpty;

  // Check if the result has recommendations
  bool get hasRecommendations => recommendations.isNotEmpty;

  // Check if the result has searchability issues
  bool get hasSearchabilityIssues => searchabilityIssues.isNotEmpty;

  // Check if the result has skills comparison
  bool get hasSkillsComparison => 
    skillsComparison.isNotEmpty && 
    (skillsComparison['matching_keywords'] != null || 
     skillsComparison['missing_keywords'] != null);

  // Check if the result has identified sections
  bool get hasIdentifiedSections => identifiedSections.isNotEmpty;

  // Check if the result has missing sections
  bool get hasMissingSections => missingSections.isNotEmpty;

  // Get matching keywords safely
  List<String> get matchingKeywords {
    if (!hasSkillsComparison) return [];
    
    final keywords = skillsComparison['matching_keywords'];
    if (keywords == null) return [];
    
    if (keywords is List) {
      return keywords.map((item) => item.toString()).toList();
    }
    
    return [];
  }

  // Get missing keywords safely
  List<String> get missingKeywords {
    if (!hasSkillsComparison) return [];
    
    final keywords = skillsComparison['missing_keywords'];
    if (keywords == null) return [];
    
    if (keywords is List) {
      return keywords.map((item) => item.toString()).toList();
    }
    
    return [];
  }

  // Get match percentage safely
  double get matchPercentage {
    if (!hasSkillsComparison) return 0.0;
    
    final percentage = skillsComparison['match_percentage'];
    if (percentage == null) return 0.0;
    
    if (percentage is double) {
      return percentage;
    } else if (percentage is int) {
      return percentage.toDouble();
    }
    
    return 0.0;
  }

  // Get component scores as a map
  Map<String, int> get componentScores {
    return {
      'Keyword Match': keywordMatchScore,
      'Formatting': formattingScore,
      'Content': contentScore,
      'Readability': readabilityScore,
    };
  }

  // Calculate weighted score based on component scores
  int calculateWeightedScore({
    double keywordWeight = 0.4,
    double formattingWeight = 0.2,
    double contentWeight = 0.3,
    double readabilityWeight = 0.1,
  }) {
    return (
      keywordMatchScore * keywordWeight +
      formattingScore * formattingWeight +
      contentScore * contentWeight +
      readabilityScore * readabilityWeight
    ).round();
  }
  
  // Add the missing keywordMatches method
  bool keywordMatches(String keyword) {
    return matchingKeywords.contains(keyword);
  }
}