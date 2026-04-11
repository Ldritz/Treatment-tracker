import 'package:flutter/material.dart';
import '../theme.dart';

class InputCard extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController controller;
  final String? unit;
  final TextInputType keyboardType;

  const InputCard({
    super.key,
    required this.label,
    required this.controller,
    this.placeholder = '',
    this.unit,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: true),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHighest, // Tonal fill instead of white box
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textMuted)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(fontSize: 18, color: AppTheme.text),
                  decoration: InputDecoration(
                    hintText: placeholder,
                    hintStyle: const TextStyle(color: AppTheme.textMuted),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (unit != null)
                Text(
                  unit!,
                  style: const TextStyle(fontSize: 16, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
