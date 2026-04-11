import 'package:flutter/material.dart';
import '../theme.dart';

class StatBox extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final Color? color;

  const StatBox({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? AppTheme.primary;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeColor == AppTheme.primary ? AppTheme.primaryFixed : themeColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppTheme.textDark, fontWeight: FontWeight.w500),
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
                if (unit != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    unit!,
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
