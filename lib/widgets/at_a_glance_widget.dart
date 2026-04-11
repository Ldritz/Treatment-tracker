import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/storage_service.dart';
import '../theme.dart';

class AtAGlanceWidget extends StatelessWidget {
  final bool isDailyMode;

  const AtAGlanceWidget({
    super.key,
    this.isDailyMode = true,
  });

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final now = DateTime.now();
    final todayStr = DateFormat('EEEE, MMMM d').format(now);
    final todayIso = now.toIso8601String().split('T').first;

    // Calculate Week
    int week = 1;
    if (storage.productionLogs.isNotEmpty) {
      DateTime oldest = now;
      for (var log in storage.productionLogs) {
        final logDate = DateTime.tryParse(log.timestamp);
        if (logDate != null && logDate.isBefore(oldest)) {
          oldest = logDate;
        }
      }
      week = (now.difference(oldest).inDays ~/ 7) + 1;
    }

    // Calculate Progress (per block)
    Set<String> block1Treatments = {};
    Set<String> block2Treatments = {};
    Set<String> block3Treatments = {};

    if (isDailyMode) {
      for (var log in storage.productionLogs) {
        if (log.timestamp.startsWith(todayIso)) {
          if (log.block == '1') {
            block1Treatments.add(log.treatment);
          } else if (log.block == '2') {
            block2Treatments.add(log.treatment);
          } else if (log.block == '3') {
            block3Treatments.add(log.treatment);
          }
        }
      }
    } else {
      for (var log in storage.eggLogs) {
        if (log.timestamp.startsWith(todayIso)) {
          if (log.block == '1') {
            block1Treatments.add(log.treatment);
          } else if (log.block == '2') {
            block2Treatments.add(log.treatment);
          } else if (log.block == '3') {
            block3Treatments.add(log.treatment);
          }
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F181C20),
            blurRadius: 32,
            offset: Offset(0, 12),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${storage.researcherName}!',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    todayStr,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Experiment Week $week',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDailyMode ? LucideIcons.clipboardCheck : LucideIcons.flaskConical,
                  color: AppTheme.primary,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Today\'s Progress',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildBlockProgress('Block 1', block1Treatments.length)),
              const SizedBox(width: 12),
              Expanded(child: _buildBlockProgress('Block 2', block2Treatments.length)),
              const SizedBox(width: 12),
              Expanded(child: _buildBlockProgress('Block 3', block3Treatments.length)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBlockProgress(String label, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            Text('$count/9', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: count / 9.0,
            minHeight: 6,
            backgroundColor: AppTheme.border,
            valueColor: AlwaysStoppedAnimation<Color>(
              count == 9 ? const Color(0xFF10B981) : AppTheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
