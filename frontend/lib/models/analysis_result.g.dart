// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnalysisResult _$AnalysisResultFromJson(Map<String, dynamic> json) =>
    AnalysisResult(
      id: json['id'] as String,
      score: (json['score'] as num).toInt(),
      keywords:
          (json['keywords'] as List<dynamic>).map((e) => e as String).toList(),
      summary: json['summary'] as String,
      analysisDate: DateTime.parse(json['analysis_date'] as String),
      skillsComparison: json['skills_comparison'] as Map<String, dynamic>,
      searchabilityIssues: (json['searchability_issues'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      educationComparison: (json['educationComparison'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      experienceComparison: (json['experienceComparison'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      jobDescription: json['jobDescription'] as String,
      recommendations: (json['recommendations'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$AnalysisResultToJson(AnalysisResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'score': instance.score,
      'keywords': instance.keywords,
      'summary': instance.summary,
      'educationComparison': instance.educationComparison,
      'experienceComparison': instance.experienceComparison,
      'jobDescription': instance.jobDescription,
      'recommendations': instance.recommendations,
      'analysis_date': instance.analysisDate.toIso8601String(),
      'skills_comparison': instance.skillsComparison,
      'searchability_issues': instance.searchabilityIssues,
    };
