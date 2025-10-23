import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../theme/app_theme.dart' show AppTheme;

enum AnalysisStep {
  uploading,
  parsing,
  analyzing,
  generating,
  completed,
}

class AnalysisProgress extends StatelessWidget {
  final AnalysisStep currentStep;
  final double progress;
  final String? currentMessage;

  const AnalysisProgress({
    super.key,
    required this.currentStep,
    required this.progress,
    this.currentMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Analyzing Your CV',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn().slideX(begin: -0.2),
          
          const SizedBox(height: 24),
          
          // Progress bar
          LinearPercentIndicator(
            width: MediaQuery.of(context).size.width - 96,
            lineHeight: 8.0,
            percent: progress,
            backgroundColor: theme.colorScheme.outline.withOpacity(0.3),
            progressColor: AppTheme.primaryColor,
            barRadius: const Radius.circular(4),
            animation: true,
            animationDuration: 500,
          ).animate().fadeIn(delay: 200.ms),
          
          const SizedBox(height: 8),
          
          // Progress percentage
          Text(
            '${(progress * 100).toInt()}%',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ).animate().fadeIn(delay: 300.ms),
          
          const SizedBox(height: 24),
          
          // Steps
          Column(
            children: AnalysisStep.values.map((step) {
              final isCompleted = step.index < currentStep.index;
              final isCurrent = step == currentStep;
              final isUpcoming = step.index > currentStep.index;
              
              return _buildStepItem(
                context,
                step,
                isCompleted: isCompleted,
                isCurrent: isCurrent,
                isUpcoming: isUpcoming,
              );
            }).toList(),
          ),
          
          // Current message
          if (currentMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      currentMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
          ],
        ],
      ),
    );
  }

  Widget _buildStepItem(
    BuildContext context,
    AnalysisStep step, {
    required bool isCompleted,
    required bool isCurrent,
    required bool isUpcoming,
  }) {
    final theme = Theme.of(context);
    final stepInfo = _getStepInfo(step);
    
    Color iconColor;
    Color textColor;
    IconData icon;
    
    if (isCompleted) {
      iconColor = AppTheme.successColor;
      textColor = theme.colorScheme.onSurface;
      icon = Icons.check_circle;
    } else if (isCurrent) {
      iconColor = AppTheme.primaryColor;
      textColor = theme.colorScheme.onSurface;
      icon = stepInfo.icon;
    } else {
      iconColor = theme.colorScheme.outline;
      textColor = theme.colorScheme.onSurface.withOpacity(0.5);
      icon = stepInfo.icon;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: iconColor,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stepInfo.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                Text(
                  stepInfo.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          
          // Loading indicator for current step
          if (isCurrent)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: (step.index * 100).ms).slideX(begin: -0.1);
  }

  _StepInfo _getStepInfo(AnalysisStep step) {
    switch (step) {
      case AnalysisStep.uploading:
        return _StepInfo(
          title: 'Uploading File',
          description: 'Securely uploading your CV to our servers',
          icon: Icons.cloud_upload,
        );
      case AnalysisStep.parsing:
        return _StepInfo(
          title: 'Parsing Content',
          description: 'Extracting text and structure from your CV',
          icon: Icons.description,
        );
      case AnalysisStep.analyzing:
        return _StepInfo(
          title: 'AI Analysis',
          description: 'Analyzing content against ATS requirements',
          icon: Icons.psychology,
        );
      case AnalysisStep.generating:
        return _StepInfo(
          title: 'Generating Report',
          description: 'Creating detailed analysis and recommendations',
          icon: Icons.assessment,
        );
      case AnalysisStep.completed:
        return _StepInfo(
          title: 'Analysis Complete',
          description: 'Your CV analysis is ready for review',
          icon: Icons.check_circle,
        );
    }
  }
}

class _StepInfo {
  final String title;
  final String description;
  final IconData icon;

  _StepInfo({
    required this.title,
    required this.description,
    required this.icon,
  });
}
