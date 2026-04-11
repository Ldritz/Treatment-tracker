import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../models/production_log.dart';

class EconomicsScreen extends StatefulWidget {
  const EconomicsScreen({super.key});

  @override
  State<EconomicsScreen> createState() => _EconomicsScreenState();
}

class _EconomicsScreenState extends State<EconomicsScreen> {
  final _feedPriceCtrl = TextEditingController();
  final _eggPriceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final storage = context.read<StorageService>();
    _feedPriceCtrl.text = storage.feedPrice > 0 ? storage.feedPrice.toString() : '';
    _eggPriceCtrl.text = storage.eggPrice > 0 ? storage.eggPrice.toString() : '';
  }

  @override
  void dispose() {
    _feedPriceCtrl.dispose();
    _eggPriceCtrl.dispose();
    super.dispose();
  }

  void _savePrices() {
    final storage = context.read<StorageService>();
    final fp = double.tryParse(_feedPriceCtrl.text) ?? 0.0;
    final ep = double.tryParse(_eggPriceCtrl.text) ?? 0.0;
    storage.setFeedPrice(fp);
    storage.setEggPrice(ep);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Market prices updated!'), backgroundColor: AppTheme.secondary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final logs = storage.productionLogs;
    
    // Group logs by treatment
    final Map<String, List<ProductionLog>> groupedLogs = {};
    for (var log in logs) {
      if (!groupedLogs.containsKey(log.treatment)) {
        groupedLogs[log.treatment] = [];
      }
      groupedLogs[log.treatment]!.add(log);
    }
    
    // Sort treatments to maintain order (T1, T2, T3)
    final sortedTreatments = groupedLogs.keys.toList()..sort();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16).copyWith(top: 40, bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Economic Efficiency',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter current market prices to analyze profitability per treatment group.',
              style: TextStyle(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildPriceInput(
                          label: 'Feed Price/kg',
                          controller: _feedPriceCtrl,
                          icon: LucideIcons.wheat,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildPriceInput(
                          label: 'Egg Price/ea',
                          controller: _eggPriceCtrl,
                          icon: LucideIcons.egg,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _savePrices,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Update Projections', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (logs.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No production logs recorded yet.', style: TextStyle(color: AppTheme.textMuted)),
                ),
              )
            else
              ...sortedTreatments.map((t) => _buildTreatmentCard(t, groupedLogs[t]!, storage.feedPrice, storage.eggPrice)),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceInput({required String label, required TextEditingController controller, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: AppTheme.primary),
            prefixText: '\$ ',
            filled: true,
            fillColor: AppTheme.surfaceLowest,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildTreatmentCard(String treatment, List<ProductionLog> logs, double feedPrice, double eggPrice) {
    double totalEggs = 0;
    double totalFeedGrams = 0;

    for (var log in logs) {
      totalEggs += log.eggs;
      totalFeedGrams += log.feedGiven;
    }

    final double totalFeedKg = totalFeedGrams / 1000;
    final double feedCost = totalFeedKg * feedPrice;
    final double grossRevenue = totalEggs * eggPrice;
    final double iofc = grossRevenue - feedCost;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceHighest),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Treatment $treatment',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
              ),
              const Spacer(),
              Text(
                '${logs.length} Logs',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatMetric('Feed Consumed', '${totalFeedKg.toStringAsFixed(2)} kg'),
              _buildStatMetric('Eggs Produced', '${totalEggs.toStringAsFixed(0)} pcs'),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: AppTheme.surfaceHighest),
          ),
          _buildMoneyRow('Gross Revenue', grossRevenue, isPositive: true),
          const SizedBox(height: 8),
          _buildMoneyRow('Feed Cost', -feedCost, isPositive: false),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iofc >= 0 ? const Color(0xFF10B981).withOpacity(0.1) : AppTheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'IOFC',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: iofc >= 0 ? const Color(0xFF047857) : AppTheme.error,
                  ),
                ),
                Text(
                  '\$${iofc.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: iofc >= 0 ? const Color(0xFF047857) : AppTheme.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
      ],
    );
  }

  Widget _buildMoneyRow(String label, double amount, {required bool isPositive}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textDark)),
        Text(
          '${amount < 0 ? '-' : ''}\$${amount.abs().toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isPositive ? const Color(0xFF10B981) : AppTheme.error,
          ),
        ),
      ],
    );
  }
}
