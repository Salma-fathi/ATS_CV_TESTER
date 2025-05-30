// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnalysisResult _$AnalysisResultFromJson(Map<String, dynamic> json) =>
    AnalysisResult(
      id: json['id'] as String,
      score: json['score'] as int,
      keywords: (json['keywords'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      summary: json['summary'] as String,
      analysisDate: DateTime.parse(json['analysis_date'] as String),
      skillsComparison: json['skills_comparison'] as Map<String, dynamic>,
      searchabilityIssues: (json['searchability_issues'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      educationComparison: (json['education_comparison'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      experienceComparison: (json['experience_comparison'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      jobDescription: json['job_description'] as String,
      recommendations: (json['recommendations'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      keywordMatchScore: json['keyword_match_score'] as int,
      formattingScore: json['formatting_score'] as int,
      contentScore: json['content_score'] as int,
      readabilityScore: json['readability_score'] as int,
      industry: json['industry'] as String,
      language: json['language'] as String? ?? 'en',
      direction: json['direction'] as String? ?? 'ltr',
      scoreBreakdown: (json['score_breakdown'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e),
          ) ??
          const {},
      identifiedSections: (json['identified_sections'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      missingSections: (json['missing_sections'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      analysisVersion: json['analysis_version'] as String? ?? '1.0',
    );

Map<String, dynamic> _$AnalysisResultToJson(AnalysisResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'score': instance.score,
      'keywords': instance.keywords,
      'summary': instance.summary,
      'education_comparison': instance.educationComparison,
      'experience_comparison': instance.experienceComparison,
      'job_description': instance.jobDescription,
      'recommendations': instance.recommendations,
      'analysis_date': instance.analysisDate.toIso8601String(),
      'skills_comparison': instance.skillsComparison,
      'searchability_issues': instance.searchabilityIssues,
      'language': instance.language,
      'direction': instance.direction,
      'score_breakdown': instance.scoreBreakdown,
      'keyword_match_score': instance.keywordMatchScore,
      'formatting_score': instance.formattingScore,
      'content_score': instance.contentScore,
      'readability_score': instance.readabilityScore,
      'industry': instance.industry,
      'identified_sections': instance.identifiedSections,
      'missing_sections': instance.missingSections,
      'analysis_version': instance.analysisVersion,
    };
    