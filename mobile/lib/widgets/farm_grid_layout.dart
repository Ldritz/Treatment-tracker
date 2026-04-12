import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../theme.dart';

class FarmGridLayout extends StatelessWidget {
  final String? indicatorContext;

  const FarmGridLayout({super.key, this.indicatorContext});

  static const Map<String, List<List<String>>> blockLayouts = {
    '1': [
      ['T1', 'T4', 'T9'],
      ['T6', 'T7', 'T8'],
      ['T2', 'T5', 'T3'],
    ],
    '2': [
      ['T6', 'T3', 'T5'],
      ['T8', 'T9', 'T4'],
      ['T2', 'T7', 'T1'],
    ],
    '3': [
      ['T2', 'T7', 'T4'],
      ['T3', 'T6', 'T5'],
      ['T8', 'T9', 'T1'],
    ],
  };

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final theme = Theme.of(context);
    final currentBlock = storage.block;
    final currentTreatment = storage.treatment;
    final nowIso = DateTime.now().toIso8601String().split('T').first;

    final layout = blockLayouts[currentBlock] ?? blockLayouts['1']!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              color: theme.primaryColor,
              onPressed: () {
                int b = int.tryParse(currentBlock) ?? 1;
                b = b > 1 ? b - 1 : 3;
                storage.setBlock(b.toString());
              },
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Block $currentBlock',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 20),
              color: theme.primaryColor,
              onPressed: () {
                int b = int.tryParse(currentBlock) ?? 1;
                b = b < 3 ? b + 1 : 1;
                storage.setBlock(b.toString());
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
          ),
          child: Column(
            children: layout.asMap().entries.map((entry) {
              final rowIndex = entry.key;
              final row = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: rowIndex == layout.length - 1 ? 0 : 8.0),
                child: Row(
                  children: row.map((treatment) {
                    final isSelected = treatment == currentTreatment;
                    
                    bool isFilled = false;
                    if (indicatorContext == 'daily') {
                       isFilled = storage.productionLogs.any((log) => log.block == currentBlock && log.treatment == treatment && log.timestamp.startsWith(nowIso));
                    } else if (indicatorContext == 'egg') {
                       isFilled = storage.eggLogs.any((log) => log.block == currentBlock && log.treatment == treatment && log.timestamp.startsWith(nowIso));
                    }

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => storage.setTreatment(treatment),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 60,
                          decoration: BoxDecoration(
                            color: isSelected ? theme.colorScheme.secondary : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected 
                                  ? (isFilled ? const Color(0xFF10B981) : theme.colorScheme.secondary) 
                                  : (isFilled ? const Color(0xFF10B981) : theme.dividerColor.withOpacity(0.2)),
                              width: (isSelected || isFilled) ? 2.5 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: theme.colorScheme.secondary.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : (isFilled ? [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    )
                                  ] : []),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            treatment,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? Colors.white : theme.textTheme.displaySmall?.color,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
