import 'package:flutter/material.dart';

class InputCard extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController controller;
  final String? unit;
  final TextInputType keyboardType;
  final TextInputAction action;
  final String? errorText;

  const InputCard({
    super.key,
    required this.label,
    required this.controller,
    this.placeholder = '',
    this.unit,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: true),
    this.action = TextInputAction.next,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor, // Background tonal fill
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: errorText != null 
            ? Colors.red.withValues(alpha: 0.5) 
            : theme.dividerColor.withValues(alpha: 0.1)
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label, 
            style: TextStyle(fontSize: 14, color: theme.textTheme.bodySmall?.color)
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  textInputAction: action,
                  style: TextStyle(
                    fontSize: 18, 
                    color: theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.bold
                  ),
                  decoration: InputDecoration(
                    hintText: placeholder,
                    hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (unit != null)
                Text(
                  unit!,
                  style: TextStyle(
                    fontSize: 16, 
                    color: theme.textTheme.bodySmall?.color, 
                    fontWeight: FontWeight.w500
                  ),
                ),
            ],
          ),
          if (errorText != null) ...[
            const SizedBox(height: 4),
            Text(
              errorText!,
              style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }
}
