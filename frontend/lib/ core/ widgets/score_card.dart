import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../theme/app_theme.dart' show AppTheme;


class ScoreCard extends StatelessWidget {
  final String title;
  final double score;
  final String description;
  final Color? color;
  final IconData? icon;

  const ScoreCard({
    super.key,
    required this.title,
    required this.score,
    required this.description,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreColor = color ?? _getScoreColor(score);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: scoreColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: scoreColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ).animate().fadeIn().slideX(begin: -0.2),
          
          const SizedBox(height: 20),
          
          // Score circle
          Center(
            child: CircularPercentIndicator(
              radius: 60.0,
              lineWidth: 8.0,
              animation: true,
              animationDuration: 1200,
              percent: score / 100,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${score.toInt()}',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                  Text(
                    'Score',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              circularStrokeCap: CircularStrokeCap.round,
              progressColor: scoreColor,
              backgroundColor: scoreColor.withOpacity(0.2),
            ),
          ).animate().scale(delay: 300.ms, duration: 600.ms),
          
          const SizedBox(height: 20),
          
          // Description
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 600.ms),
          
          const SizedBox(height: 16),
          
          // Score level indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: scoreColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _getScoreLevel(score),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scoreColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return AppTheme.successColor;
    if (score >= 60) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  String _getScoreLevel(double score) {
    if (score >= 90) return 'Excellent';
    if (score >= 80) return 'Good';
    if (score >= 70) return 'Fair';
    if (score >= 60) return 'Needs Work';
    return 'Poor';
  }
}

class OverallScoreCard extends StatelessWidget {
  final double overallScore;
  final Map<String, double> categoryScores;

  const OverallScoreCard({
    super.key,
    required this.overallScore,
    required this.categoryScores,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreColor = _getScoreColor(overallScore);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scoreColor.withOpacity(0.1),
            scoreColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scoreColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Title
          Text(
            'Overall ATS Score',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn().slideY(begin: -0.2),
          
          const SizedBox(height: 24),
          
          // Main score
          CircularPercentIndicator(
            radius: 80.0,
            lineWidth: 12.0,
            animation: true,
            animationDuration: 1500,
            percent: overallScore / 100,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${overallScore.toInt()}',
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
                Text(
                  'ATS Score',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: scoreColor,
            backgroundColor: scoreColor.withOpacity(0.2),
          ).animate().scale(delay: 300.ms, duration: 800.ms),
          
          const SizedBox(height: 24),
          
          // Category breakdown
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: categoryScores.entries.map((entry) {
              return _buildCategoryChip(context, entry.key, entry.value);
            }).toList(),
          ).animate().fadeIn(delay: 800.ms),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context, String category, double score) {
    final theme = Theme.of(context);
    final scoreColor = _getScoreColor(score);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scoreColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: scoreColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            category,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${score.toInt()}%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scoreColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return AppTheme.successColor;
    if (score >= 60) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }
}
