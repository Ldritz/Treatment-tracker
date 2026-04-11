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

    // Calculate overall percentage (Assuming 27 total treatments: 3 blocks * 9 treatments)
    final int totalRequired = 27;
    final int completedCount = block1Treatments.length + block2Treatments.length + block3Treatments.length;
    final double overallProgress = completedCount / totalRequired.toDouble();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor,
            Color.alphaBlend(Colors.black.withOpacity(0.3), theme.primaryColor), 
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    todayStr,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Experiment Week $week'.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
              // Progress Ring
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: CircularProgressIndicator(
                      value: overallProgress,
                      strokeWidth: 6,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  Text(
                    '${(overallProgress * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              const Icon(LucideIcons.activity, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                'Today\'s Progress'.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white70,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildBlockProgress('Block 1', block1Treatments.length)),
              const SizedBox(width: 16),
              Expanded(child: _buildBlockProgress('Block 2', block2Treatments.length)),
              const SizedBox(width: 16),
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
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('$count/9', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.7))),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: count / 9.0,
            minHeight: 4,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              count == 9 ? const Color(0xFF10B981) : Colors.white.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }
}
