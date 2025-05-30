import 'package:flutter/material.dart';

class KeywordChip extends StatelessWidget {
  final String keyword;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isMatched;
  final VoidCallback? onTap;

  const KeywordChip({
    Key? key,
    required this.keyword,
    this.backgroundColor,
    this.textColor,
    this.isMatched = true,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultBackgroundColor = isMatched ? Colors.green[100] : Colors.red[50];
    final defaultTextColor = isMatched ? Colors.green[800] : Colors.red[800];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Chip(
        label: Text(
          keyword,
          style: TextStyle(
            color: textColor ?? defaultTextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: backgroundColor ?? defaultBackgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
}