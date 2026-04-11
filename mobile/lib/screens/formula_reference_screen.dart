import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme.dart';

class FormulaReferenceScreen extends StatelessWidget {
  const FormulaReferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Formula Reference', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16).copyWith(bottom: 40),
        children: [
          _buildIntroCard(),
          const SizedBox(height: 8),

          // ─── PRODUCTION PERFORMANCE ───────────────────────────────
          _buildSectionHeader(context, 'Daily Production Performance', LucideIcons.clipboardList, theme.primaryColor),
          _buildFormulaCard(
            context,
            name: 'Voluntary Feed Intake (VFI)',
            acronym: 'VFI',
            formula: 'VFI = Feed Given (g) − Feed Refusal (g)',
            description: 'The actual amount of feed voluntarily consumed by the birds after subtracting leftover (refused) feed.',
            unit: 'grams (g)',
            icon: LucideIcons.wheat,
            color: theme.primaryColor,
          ),
          _buildFormulaCard(
            context,
            name: 'Feed Conversion Ratio',
            acronym: 'FCR',
            formula: 'FCR = VFI ÷ Egg Mass (g)',
            description: 'The efficiency of converting feed into egg mass. A lower FCR indicates a more feed-efficient treatment group.',
            unit: 'unitless ratio',
            icon: LucideIcons.arrowLeftRight,
            color: theme.primaryColor.withOpacity(0.8),
          ),
          _buildFormulaCard(
            context,
            name: 'Hen-Day Egg Production',
            acronym: 'HDEP %',
            formula: 'HDEP = (Eggs Laid ÷ (Birds Alive × Days)) × 100',
            description: 'The percentage of birds that laid an egg on a given day. A daily snapshot of laying performance relative to the current flock size.',
            unit: 'percentage (%)',
            icon: LucideIcons.percent,
            color: const Color(0xFF10B981),
          ),

          const SizedBox(height: 8),

          // ─── EGG QUALITY ──────────────────────────────────────────
          _buildSectionHeader(context, 'Egg Quality Lab', LucideIcons.flaskConical, const Color(0xFF818CF8)),
          _buildFormulaCard(
            context,
            name: 'Haugh Unit',
            acronym: 'HU',
            formula: 'HU = 100 × log₁₀(H − 1.7W⁰·³⁷ + 7.6)',
            description: 'A measure of egg albumen (white) quality. A higher Haugh Unit score indicates firmer, higher-quality albumen.\n\nWhere:\n  H = Albumen height (mm)\n  W = Egg weight (g)',
            unit: 'Haugh Units',
            icon: LucideIcons.egg,
            color: const Color(0xFF818CF8),
          ),
          _buildFormulaCard(
            context,
            name: 'Shape Index',
            acronym: 'SI',
            formula: 'SI = (Average Width ÷ Average Length) × 100',
            description: 'Describes the shape of the egg, indicating how round or elongated it is. Ideal range is 72–76%.\n\nWidth and Length are each the average of 3 measurements (mm).',
            unit: 'percentage (%)',
            icon: LucideIcons.moveHorizontal,
            color: const Color(0xFFF59E0B),
          ),
          _buildFormulaCard(
            context,
            name: 'Yolk Percentage',
            acronym: 'Yolk %',
            formula: 'Yolk % = (Yolk Weight ÷ Egg Weight) × 100',
            description: 'The proportion of the total egg weight that is composed of yolk. Higher values may indicate better nutritional composition.',
            unit: 'percentage (%)',
            icon: LucideIcons.sun,
            color: const Color(0xFFF97316),
          ),

          const SizedBox(height: 8),

          // ─── ECONOMIC EFFICIENCY ──────────────────────────────────
          _buildSectionHeader(context, 'Economic Efficiency', LucideIcons.coins, const Color(0xFF10B981)),
          _buildFormulaCard(
            context,
            name: 'Feed Cost',
            acronym: 'Feed Cost',
            formula: 'Feed Cost = Total Feed (kg) × Price per kg (₱)',
            description: 'Total expenditure on feed for a given treatment across the entire study period.\n\nTotal Feed (kg) = Sum of all daily feedGiven values ÷ 1000',
            unit: 'Philippine Peso (₱)',
            icon: LucideIcons.wheat,
            color: const Color(0xFFEF4444),
          ),
          _buildFormulaCard(
            context,
            name: 'Gross Revenue',
            acronym: 'Revenue',
            formula: 'Gross Revenue = Total Eggs × Price per Egg (₱)',
            description: 'Total income generated from egg sales for a given treatment across the entire study period.',
            unit: 'Philippine Peso (₱)',
            icon: LucideIcons.shoppingCart,
            color: const Color(0xFF10B981),
          ),
          _buildFormulaCard(
            context,
            name: 'Income Over Feed Cost',
            acronym: 'IOFC',
            formula: 'IOFC = Gross Revenue − Total Feed Cost',
            description: 'The profitability of a treatment after accounting for the primary variable cost (feed). A positive IOFC means the treatment is generating profit over its feed expenditure.',
            unit: 'Philippine Peso (₱)',
            icon: LucideIcons.trendingUp,
            color: const Color(0xFF047857),
          ),

          const SizedBox(height: 16),
          _buildCitationCard(context),
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00459A), Color(0xFF00306A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.bookOpen, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Formula Reference',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'All scientific and economic formulas used to calculate metrics in CoturniSync.',
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: color.withOpacity(0.3), thickness: 1.5)),
        ],
      ),
    );
  }

  Widget _buildFormulaCard(
    BuildContext context, {
    required String name,
    required String acronym,
    required String formula,
    required String description,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: theme.brightness == Brightness.dark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          title: Text(
            name, 
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 15, 
              color: theme.textTheme.displaySmall?.color
            )
          ),
          subtitle: Text(acronym, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            // Formula Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                formula,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Description
            Text(description, style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color, height: 1.6)),
            const SizedBox(height: 10),
            // Unit badge
            Row(
              children: [
                Icon(LucideIcons.ruler, size: 14, color: theme.textTheme.bodySmall?.color),
                const SizedBox(width: 6),
                Text(
                  'Unit: $unit',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textTheme.bodySmall?.color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCitationCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.info, size: 16, color: theme.textTheme.bodySmall?.color),
              const SizedBox(width: 8),
              Text(
                'Reference Note', 
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 13, 
                  color: theme.textTheme.displaySmall?.color
                )
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Haugh Unit formula: Haugh, R.R. (1937). A method for measuring the quality of an egg.\n'
            'HDEP formula: Standard laying rate calculation (birds alive × period length).\n'
            'Shape Index: Standard poultry science morphometric index.\n'
            'IOFC: Standard animal production economic efficiency indicator.',
            style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color?.withOpacity(0.8), height: 1.6),
          ),
        ],
      ),
    );
  }
}
