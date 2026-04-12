import 'package:flutter/material.dart';

class StatBox extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final String? suffix; // alias for unit
  final Color? color;

  const StatBox({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.suffix,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeColor = color ?? theme.primaryColor;
    final displayUnit = unit ?? suffix;
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark 
              ? themeColor.withValues(alpha: 0.1) 
              : (themeColor == theme.primaryColor ? theme.primaryColor.withValues(alpha: 0.1) : themeColor.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: themeColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14, 
                color: theme.textTheme.displaySmall?.color?.withValues(alpha: 0.7), 
                fontWeight: FontWeight.w500
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: themeColor),
                ),
                if (displayUnit != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    displayUnit,
                    style: TextStyle(fontSize: 14, color: themeColor),
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
}
