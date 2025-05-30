import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class ScoreIndicator extends StatelessWidget {
  final double score;
  final double size;
  final bool showLabel;
  final double strokeWidth;
  final TextStyle? textStyle;
  final TextStyle? labelStyle;
  final String? label;

  const ScoreIndicator({
    Key? key,
    required this.score,
    this.size = 120,
    this.showLabel = true,
    this.strokeWidth = 10,
    this.textStyle,
    this.labelStyle,
    this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    
    // Determine score category and color
    String scoreText;
    Color scoreColor;
    
    if (score >= 85) {
      scoreText = label ?? appLocalizations.excellent;
      scoreColor = Colors.green;
    } else if (score >= 70) {
      scoreText = label ?? appLocalizations.good;
      scoreColor = Colors.orange;
    } else {
      scoreText = label ?? appLocalizations.needsImprovement;
      scoreColor = Colors.red;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Circular progress indicator
              CircularProgressIndicator(
                value: score / 100,
                strokeWidth: strokeWidth,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              ),
              // Score text
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${score.toInt()}%',
                    style: textStyle ?? TextStyle(
                      fontSize: size / 4,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 8),
          Text(
            scoreText,
            style: labelStyle ?? TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: scoreColor,
            ),
          ),
        ],
      ],
    );
  }
  
  // Helper method to get score color
  Color getScoreColor() {
    if (score >= 85) {
      return Colors.green;
    } else if (score >= 70) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}