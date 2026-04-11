import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../helpers/download_stub.dart'
    if (dart.library.html) '../helpers/download_web.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';
import '../models/production_log.dart';
import '../models/egg_log.dart';
import '../theme.dart';

class WebDashboardScreen extends StatefulWidget {
  const WebDashboardScreen({super.key});

  @override
  State<WebDashboardScreen> createState() => _WebDashboardScreenState();
}

class _WebDashboardScreenState extends State<WebDashboardScreen> {
  bool _isAdmin = false;
  final TextEditingController _passController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Auto-pull from Supabase when the dashboard first opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SyncService>().triggerSync();
    });
  }

  void _showAdminLogin() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Admin Login', style: TextStyle(color: AppTheme.textDark)),
        content: TextField(
          controller: _passController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () {
              if (_passController.text == 'admin123') {
                setState(() => _isAdmin = true);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin edit mode unlocked!'), backgroundColor: AppTheme.secondary));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid password'), backgroundColor: AppTheme.error));
              }
              _passController.clear();
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  void _deleteProductionLog(ProductionLog log) {
    if (!_isAdmin) return;
    context.read<StorageService>().deleteProductionLog(log.id);
  }

  void _deleteEggLabLog(EggLog log) {
    if (!_isAdmin) return;
    context.read<StorageService>().deleteEggLog(log.id);
  }

  void _exportAllCsv(StorageService storage) {
    String csv = 'ID,Date,Treatment,Block,Eggs,EggMass(g),QuailsAlive,Days,FeedGiven(g),FeedRefusal(g),VFI(g),FCR,HDEP(%)\n';
    for (var log in storage.productionLogs) {
      csv += '${log.id},${log.timestamp},${log.treatment},${log.block},${log.eggs},${log.eggMass},${log.quails},${log.days},${log.feedGiven},${log.feedRefusal},${log.vfi},${log.fcr},${log.hdep}\n';
    }
    csv += '\nID,Date,Treatment,Block,Weight(g),Length(mm),Width(mm),AlbumenHt(mm),ShellWt(g),YolkWt(g),HaughUnit,ShapeIndex,YolkPct(%)\n';
    for (var log in storage.eggLogs) {
      csv += '${log.id},${log.timestamp},${log.treatment},${log.block},${log.weight},${log.length},${log.width},${log.albumenHeight},${log.shellWeight},${log.yolkWeight},${log.haughUnit},${log.shapeIndex},${log.yolkPct}\n';
    }
    downloadCsv(csv, 'CoturniSync_All_Data.csv');
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final sync = context.watch<SyncService>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/logo.png', width: 32, height: 32),
            const SizedBox(width: 12),
            const Text('CoturniSync Web Dashboard', style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: AppTheme.surface,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: AppTheme.primary),
            tooltip: 'Refresh Data',
            onPressed: () => sync.triggerSync(),
          ),
          const SizedBox(width: 8),
          Icon(
            sync.status == SyncState.online ? LucideIcons.cloudLightning : (sync.status == SyncState.syncing ? LucideIcons.refreshCw : LucideIcons.cloudOff),
            color: sync.status == SyncState.online ? const Color(0xFF10B981) : (sync.status == SyncState.syncing ? AppTheme.primary : AppTheme.error),
          ),
          const SizedBox(width: 8),
          Center(
            child: Text(
              sync.status == SyncState.online ? 'Online' : (sync.status == SyncState.syncing ? 'Syncing...' : 'Offline'),
              style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 24),
          if (!_isAdmin)
            TextButton.icon(
              icon: const Icon(LucideIcons.lock, color: AppTheme.textMuted),
              label: const Text('Read Only (Login)', style: TextStyle(color: AppTheme.textMuted)),
              onPressed: _showAdminLogin,
            )
          else
            TextButton.icon(
              icon: const Icon(LucideIcons.unlock, color: AppTheme.secondary),
              label: const Text('Admin Mode Active', style: TextStyle(color: AppTheme.secondary)),
              onPressed: () => setState(() => _isAdmin = false),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          _buildLiveAnalyticsBar(storage),
          Expanded(
            child: Row(
              children: [
                // Sidebar
                Container(
                  width: 280,
                  color: AppTheme.surfaceLow,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Overview', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 1.2)),
                      const SizedBox(height: 16),
                      _StatTile(title: 'Total Production Logs', value: storage.productionLogs.length.toString(), icon: LucideIcons.clipboardList),
                      const SizedBox(height: 12),
                      _StatTile(title: 'Total Egg Lab Logs', value: storage.eggLogs.length.toString(), icon: LucideIcons.egg),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(LucideIcons.download),
                        label: const Text('Export All CSV'),
                        onPressed: () => _exportAllCsv(storage),
                      ),
                    ],
                  ),
                ),
                // Main Content
                Expanded(
                  child: DefaultTabController(
                    length: 3,
                    child: Column(
                      children: [
                        Container(
                          color: AppTheme.surface,
                          child: const TabBar(
                            labelColor: AppTheme.primary,
                            unselectedLabelColor: AppTheme.textMuted,
                            indicatorColor: AppTheme.primary,
                            tabs: [
                              Tab(text: 'Daily Production Data'),
                              Tab(text: 'Egg Lab Quality Data'),
                              Tab(text: 'Economic Efficiency'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildProductionTable(storage.productionLogs),
                              _buildEggTable(storage.eggLogs),
                              _buildEconomicTab(context, storage),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveAnalyticsBar(StorageService storage) {
    double avgHdep = 0;
    if (storage.productionLogs.isNotEmpty) {
      avgHdep = storage.productionLogs.map((l) => l.hdep).reduce((a, b) => a + b) / storage.productionLogs.length;
    }

    double totalProfit = 0;
    for (var log in storage.productionLogs) {
      totalProfit += (log.eggs * storage.eggPrice) - ((log.feedGiven / 1000) * storage.feedPrice);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLowest,
        border: Border(bottom: BorderSide(color: AppTheme.border.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          _buildAnalyticsCard('Avg HDEP %', '${avgHdep.toStringAsFixed(1)}%', LucideIcons.trendingUp, avgHdep > 80 ? Colors.green : Colors.orange),
          const SizedBox(width: 20),
          _buildAnalyticsCard('Market Value (Total)', '₱${totalProfit.toStringAsFixed(2)}', LucideIcons.banknote, Colors.blue),
          const SizedBox(width: 20),
          _buildAnalyticsCard('Researchers active', '2', LucideIcons.users, Colors.deepPurple),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEconomicTab(BuildContext context, StorageService storage) {
    if (storage.productionLogs.isEmpty) {
      return const Center(child: Text('No production data available for economic analysis.'));
    }

    final fpCtrl = TextEditingController(text: storage.feedPrice > 0 ? storage.feedPrice.toString() : '');
    final epCtrl = TextEditingController(text: storage.eggPrice > 0 ? storage.eggPrice.toString() : '');

    final Map<String, List<ProductionLog>> groupedLogs = {};
    for (var log in storage.productionLogs) {
      if (!groupedLogs.containsKey(log.treatment)) {
        groupedLogs[log.treatment] = [];
      }
      groupedLogs[log.treatment]!.add(log);
    }
    final sortedTreatments = groupedLogs.keys.toList()..sort();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.surfaceLowest,
          child: Row(
            children: [
              const Text('Input Prices:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(width: 16),
              SizedBox(
                width: 150,
                child: TextField(
                  controller: fpCtrl,
                  decoration: const InputDecoration(labelText: 'Feed Price/kg (₱)', isDense: true),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 150,
                child: TextField(
                  controller: epCtrl,
                  decoration: const InputDecoration(labelText: 'Egg Price/ea (₱)', isDense: true),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  final fp = double.tryParse(fpCtrl.text) ?? 0.0;
                  final ep = double.tryParse(epCtrl.text) ?? 0.0;
                  storage.setFeedPrice(fp);
                  storage.setEggPrice(ep);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: const Text('Update Projections', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                columns: const [
                  DataColumn(label: Text('Treatment')),
                  DataColumn(label: Text('Logs Count')),
                  DataColumn(label: Text('Total Eggs')),
                  DataColumn(label: Text('Total Feed (kg)')),
                  DataColumn(label: Text('Gross Revenue (₱)', style: TextStyle(color: Color(0xFF10B981)))),
                  DataColumn(label: Text('Feed Cost (₱)', style: TextStyle(color: AppTheme.error))),
                  DataColumn(label: Text('IOFC (₱)', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: sortedTreatments.map((t) {
                  final logs = groupedLogs[t]!;
                  double totalEggs = 0;
                  double totalFeedGrams = 0;
                  for (var log in logs) {
                    totalEggs += log.eggs;
                    totalFeedGrams += log.feedGiven;
                  }
                  final totalFeedKg = totalFeedGrams / 1000;
                  final feedCost = totalFeedKg * storage.feedPrice;
                  final grossRevenue = totalEggs * storage.eggPrice;
                  final iofc = grossRevenue - feedCost;

                  return DataRow(
                    cells: [
                      DataCell(Text(t, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(logs.length.toString())),
                      DataCell(Text(totalEggs.toStringAsFixed(0))),
                      DataCell(Text(totalFeedKg.toStringAsFixed(2))),
                      DataCell(Text(grossRevenue.toStringAsFixed(2), style: const TextStyle(color: Color(0xFF10B981)))),
                      DataCell(Text(feedCost.toStringAsFixed(2), style: const TextStyle(color: AppTheme.error))),
                      DataCell(Text(iofc.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.bold, color: iofc >= 0 ? const Color(0xFF047857) : AppTheme.error))),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductionTable(List<ProductionLog> logs) {
    if (logs.isEmpty) {
      return const Center(child: Text('No daily production data synced yet.'));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
          dataRowMinHeight: 48,
          dataRowMaxHeight: 48,
          columns: [
            const DataColumn(label: Text('Date')),
            const DataColumn(label: Text('Treatment')),
            const DataColumn(label: Text('Block')),
            const DataColumn(label: Text('Birds Alive')),
            const DataColumn(label: Text('Eggs')),
            const DataColumn(label: Text('Egg Mass (g)')),
            const DataColumn(label: Text('Feed (g)')),
            const DataColumn(label: Text('Refusal (g)')),
            const DataColumn(label: Text('VFI')),
            const DataColumn(label: Text('FCR')),
            const DataColumn(label: Text('HDEP%')),
            const DataColumn(label: Text('Researcher')),
            if (_isAdmin) const DataColumn(label: Text('Actions')),
          ],
          rows: logs.map((log) {
            final date = DateTime.parse(log.timestamp).toLocal().toString().split(' ')[0];
            return DataRow(
              cells: [
                DataCell(Text(date)),
                DataCell(Text(log.treatment)),
                DataCell(Text(log.block)),
                DataCell(Text(log.quails.toStringAsFixed(0))),
                DataCell(Text(log.eggs.toStringAsFixed(0))),
                DataCell(Text(log.eggMass.toStringAsFixed(1))),
                DataCell(Text(log.feedGiven.toStringAsFixed(1))),
                DataCell(Text(log.feedRefusal.toStringAsFixed(1))),
                DataCell(Text(log.vfi.toStringAsFixed(1))),
                DataCell(Text(log.fcr.toStringAsFixed(2))),
                DataCell(Text(log.hdep.toStringAsFixed(1))),
                DataCell(Text(log.recordedby.isEmpty ? '-' : log.recordedby)),
                if (_isAdmin)
                  DataCell(
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, color: AppTheme.error, size: 18),
                      onPressed: () => _deleteProductionLog(log),
                    ),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEggTable(List<EggLog> logs) {
    if (logs.isEmpty) {
      return const Center(child: Text('No egg lab data synced yet.'));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
          dataRowMinHeight: 48,
          dataRowMaxHeight: 48,
          columns: [
            const DataColumn(label: Text('Date')),
            const DataColumn(label: Text('Treatment')),
            const DataColumn(label: Text('Block')),
            const DataColumn(label: Text('Egg Wt (g)')),
            const DataColumn(label: Text('Length (mm)')),
            const DataColumn(label: Text('Width (mm)')),
            const DataColumn(label: Text('Alb Ht (mm)')),
            const DataColumn(label: Text('Shell Wt (g)')),
            const DataColumn(label: Text('Yolk Wt (g)')),
            const DataColumn(label: Text('Haugh Unit')),
            const DataColumn(label: Text('Shape Index')),
            const DataColumn(label: Text('Yolk %')),
            const DataColumn(label: Text('Researcher')),
            if (_isAdmin) const DataColumn(label: Text('Actions')),
          ],
          rows: logs.map((log) {
            final date = DateTime.parse(log.timestamp).toLocal().toString().split(' ')[0];
            return DataRow(
              cells: [
                DataCell(Text(date)),
                DataCell(Text(log.treatment)),
                DataCell(Text(log.block)),
                DataCell(Text(log.weight.toStringAsFixed(2))),
                DataCell(Text(log.length.toStringAsFixed(2))),
                DataCell(Text(log.width.toStringAsFixed(2))),
                DataCell(Text(log.albumenHeight.toStringAsFixed(2))),
                DataCell(Text(log.shellWeight.toStringAsFixed(2))),
                DataCell(Text(log.yolkWeight.toStringAsFixed(2))),
                DataCell(Text(log.haughUnit.toStringAsFixed(2))),
                DataCell(Text(log.shapeIndex.toStringAsFixed(2))),
                DataCell(Text(log.yolkPct.toStringAsFixed(2))),
                DataCell(Text(log.recordedby.isEmpty ? '-' : log.recordedby)),
                 if (_isAdmin)
                  DataCell(
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, color: AppTheme.error, size: 18),
                      onPressed: () => _deleteEggLabLog(log),
                    ),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatTile({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.surfaceHighest),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
