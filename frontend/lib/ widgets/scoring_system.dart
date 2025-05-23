import 'dart:math';

/// A more realistic scoring system for ATS CV analysis
class ImprovedScoringSystem {
  // Score category thresholds
  static const double _needsImprovementThreshold = 60.0;
  static const double _goodThreshold = 80.0;
  static const double _excellentThreshold = 95.0; // Max realistic score is 95%

  // Score category labels
  static const String _needsImprovementLabel = 'Needs Improvement';
  static const String _goodLabel = 'Good';
  static const String _excellentLabel = 'Excellent';

  // Score category colors (hex codes)
  static const String _needsImprovementColor = '#E74C3C'; // Red
  static const String _goodColor = '#F39C12'; // Orange/Yellow
  static const String _excellentColor = '#2ECC71'; // Green

  /// Calculate a more realistic overall score based on component scores
  /// This ensures even good CVs have room for improvement
  static double calculateRealisticScore({
    required double keywordMatchScore,
    required double formattingScore,
    required double contentScore,
    required double readabilityScore,
    double industryDifficulty = 0.5, // 0.0 (easy) to 1.0 (hard)
  }) {
    // Base calculation - weighted average of component scores
    double baseScore = (
      keywordMatchScore * 0.4 +
      formattingScore * 0.2 +
      contentScore * 0.25 +
      readabilityScore * 0.15
    );
    
    // Apply industry difficulty factor (harder industries get lower scores)
    double adjustedScore = baseScore * (1.0 - (industryDifficulty * 0.15));
    
    // Apply realistic ceiling - even perfect CVs rarely get 100%
    double realisticCeiling = 95.0 - (industryDifficulty * 5.0);
    adjustedScore = min(adjustedScore, realisticCeiling);
    
    // Add small random variation for more natural results
    final random = Random();
    double variation = random.nextDouble() * 3.0 - 1.5; // -1.5 to +1.5
    adjustedScore = max(0.0, min(realisticCeiling, adjustedScore + variation));
    
    return double.parse(adjustedScore.toStringAsFixed(1));
  }

  /// Get the appropriate label for a score
  static String getLabelForScore(double score) {
    if (score < _needsImprovementThreshold) {
      return _needsImprovementLabel;
    } else if (score < _goodThreshold) {
      return _goodLabel;
    } else {
      return _excellentLabel;
    }
  }

  /// Get the appropriate color for a score
  static String getColorForScore(double score) {
    if (score < _needsImprovementThreshold) {
      return _needsImprovementColor;
    } else if (score < _goodThreshold) {
      return _goodColor;
    } else {
      return _excellentColor;
    }
  }

  /// Generate realistic component scores based on CV quality
  /// quality: 0.0 (poor) to 1.0 (excellent)
  static Map<String, double> generateComponentScores(double quality) {
    final random = Random();
    
    // Base scores influenced by quality
    double baseKeywordMatch = 40.0 + (quality * 55.0);
    double baseFormatting = 50.0 + (quality * 45.0);
    double baseContent = 45.0 + (quality * 50.0);
    double baseReadability = 55.0 + (quality * 40.0);
    
    // Add variation for more natural results
    double keywordVariation = random.nextDouble() * 10.0 - 5.0;
    double formattingVariation = random.nextDouble() * 8.0 - 4.0;
    double contentVariation = random.nextDouble() * 12.0 - 6.0;
    double readabilityVariation = random.nextDouble() * 10.0 - 5.0;
    
    // Calculate final scores with constraints
    double keywordMatchScore = _constrainScore(baseKeywordMatch + keywordVariation);
    double formattingScore = _constrainScore(baseFormatting + formattingVariation);
    double contentScore = _constrainScore(baseContent + contentVariation);
    double readabilityScore = _constrainScore(baseReadability + readabilityVariation);
    
    return {
      'keywordMatchScore': keywordMatchScore,
      'formattingScore': formattingScore,
      'contentScore': contentScore,
      'readabilityScore': readabilityScore,
    };
  }
  
  /// Constrain a score to be between 0 and 100
  static double _constrainScore(double score) {
    return max(0.0, min(100.0, double.parse(score.toStringAsFixed(1))));
  }
  
  /// Generate improvement suggestions based on scores
  static List<Map<String, String>> generateSuggestions({
    required double keywordMatchScore,
    required double formattingScore,
    required double contentScore,
    required double readabilityScore,
    required String industry,
  }) {
    List<Map<String, String>> suggestions = [];
    
    // Always provide at least one suggestion, even for high scores
    
    // Keyword suggestions
    if (keywordMatchScore < 85) {
      suggestions.add({
        'category': 'Keywords',
        'title': 'Enhance Industry-Specific Keywords',
        'description': 'Add more $industry-related terms and skills to increase ATS compatibility.',
        'priority': keywordMatchScore < 60 ? 'High' : 'Medium',
      });
    } else {
      suggestions.add({
        'category': 'Keywords',
        'title': 'Optimize Keyword Placement',
        'description': 'While your keyword match is strong, consider strategic placement in section headers and bullet points for even better results.',
        'priority': 'Low',
      });
    }
    
    // Formatting suggestions
    if (formattingScore < 80) {
      suggestions.add({
        'category': 'Formatting',
        'title': 'Improve Document Structure',
        'description': 'Use a cleaner layout with consistent headings and bullet points for better ATS parsing.',
        'priority': formattingScore < 60 ? 'High' : 'Medium',
      });
    } else {
      suggestions.add({
        'category': 'Formatting',
        'title': 'Optimize Section Order',
        'description': 'Consider placing your strongest qualifications higher in your CV for immediate impact.',
        'priority': 'Low',
      });
    }
    
    // Content suggestions
    if (contentScore < 75) {
      suggestions.add({
        'category': 'Content',
        'title': 'Strengthen Achievement Descriptions',
        'description': 'Add more quantifiable achievements and metrics to demonstrate your impact.',
        'priority': contentScore < 60 ? 'High' : 'Medium',
      });
    } else {
      suggestions.add({
        'category': 'Content',
        'title': 'Tailor Experience to Job Requirements',
        'description': 'Further customize your experience descriptions to align with specific job requirements.',
        'priority': 'Low',
      });
    }
    
    // Readability suggestions
    if (readabilityScore < 70) {
      suggestions.add({
        'category': 'Readability',
        'title': 'Improve Sentence Structure',
        'description': 'Use shorter, more direct sentences and avoid complex jargon to improve readability.',
        'priority': readabilityScore < 60 ? 'High' : 'Medium',
      });
    } else {
      suggestions.add({
        'category': 'Readability',
        'title': 'Enhance Scannability',
        'description': 'Consider using more white space and strategic bold text to make key information stand out.',
        'priority': 'Low',
      });
    }
    
    return suggestions;
  }
}