import 'package:flutter/material.dart';
import '../theme.dart';

class CustomButton extends StatelessWidget {
  final String? title;
  final String? text; // alias for title
  final VoidCallback onPressed;
  final bool isSecondary;
  final IconData? icon;

  const CustomButton({
    super.key,
    this.title,
    this.text,
    required this.onPressed,
    this.isSecondary = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = text ?? title ?? 'Submit';
    
    if (isSecondary) {
      return SizedBox(
        width: double.infinity,
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: theme.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: onPressed,
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: theme.brightness == Brightness.dark ? [] : [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: LinearGradient(
          colors: [
            theme.primaryColor, 
            Color.alphaBlend(Colors.black.withOpacity(0.1), theme.primaryColor)
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[Icon(icon!, color: Colors.white, size: 20), const SizedBox(width: 8)],
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
