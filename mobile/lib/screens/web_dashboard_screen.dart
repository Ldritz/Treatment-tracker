import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../helpers/download_stub.dart'
    if (dart.library.html) '../helpers/download_web.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';
import '../models/production_log.dart';
import '../models/egg_log.dart';

import 'package:qr_flutter/qr_flutter.dart';

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

  void _showPairingQR() {
    final theme = Theme.of(context);
    // Detect the current base URL if on web, otherwise fallback
    final baseUrl = kIsWeb ? Uri.base.origin : 'https://quail-logger.vercel.app';
    const sUrl = 'https://lpyxwxfmshuwwogalkfd.supabase.co';
    const sKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxweXh3eGZtc2h1d3dvZ2Fsa2ZkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU4MDEzNDAsImV4cCI6MjA5MTM3NzM0MH0.pWDpmmWQDugls7-SDNI5gWUk-ImkdE6ksYxxrS7dwfU';
    
    final pairingLink = '$baseUrl/connect?u=$sUrl&k=$sKey';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text('Connect Mobile Device', style: TextStyle(color: theme.textTheme.displaySmall?.color)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Scan this QR code with the Quail Logger mobile app to enable cloud synchronization.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, // Keep white for QR scanner contrast
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: QrImageView(
                data: pairingLink,
                version: QrVersions.auto,
                size: 200.0,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
              ),
            ),
            const SizedBox(height: 16),
            SelectableText(
              pairingLink,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: theme.textTheme.bodySmall?.color),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: TextStyle(color: theme.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showAdminLogin() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text('Admin Login', style: TextStyle(color: theme.textTheme.displaySmall?.color)),
        content: TextField(
          controller: _passController,
          obscureText: true,
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            labelText: 'Password',
            labelStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (_passController.text == 'admin123') {
                setState(() => _isAdmin = true);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text('Admin edit mode unlocked!'), backgroundColor: theme.colorScheme.secondary)
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text('Invalid password'), backgroundColor: theme.colorScheme.error)
                );
              }
              _passController.clear();
            },
            child: const Text('Login', style: TextStyle(color: Colors.white)),
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
    final theme = Theme.of(context);
    final storage = context.watch<StorageService>();
    final sync = context.watch<SyncService>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/logo.png', width: 32, height: 32),
            const SizedBox(width: 12),
            Text(
              'CoturniSync Web Dashboard', 
              style: TextStyle(color: theme.textTheme.displaySmall?.color, fontWeight: FontWeight.bold)
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(LucideIcons.refreshCw, color: theme.primaryColor),
            tooltip: 'Refresh Data',
            onPressed: () => sync.triggerSync(),
          ),
          const SizedBox(width: 8),
          Icon(
            sync.status == SyncState.online ? LucideIcons.cloudLightning : (sync.status == SyncState.syncing ? LucideIcons.refreshCw : LucideIcons.cloudOff),
            color: sync.status == SyncState.online ? const Color(0xFF10B981) : (sync.status == SyncState.syncing ? theme.primaryColor : theme.colorScheme.error),
          ),
          const SizedBox(width: 8),
          Center(
            child: Text(
              sync.status == SyncState.online ? 'Online' : (sync.status == SyncState.syncing ? 'Syncing...' : 'Offline'),
              style: TextStyle(color: theme.textTheme.displaySmall?.color, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 24),
          if (!_isAdmin)
            TextButton.icon(
              icon: Icon(LucideIcons.lock, color: theme.textTheme.bodySmall?.color),
              label: Text('Read Only (Login)', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
              onPressed: _showAdminLogin,
            )
          else
            TextButton.icon(
              icon: Icon(LucideIcons.unlock, color: theme.colorScheme.secondary),
              label: Text('Admin Mode Active', style: TextStyle(color: theme.colorScheme.secondary)),
              onPressed: () => setState(() => _isAdmin = false),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          _buildLiveAnalyticsBar(context, storage),
          Expanded(
            child: Row(
              children: [
                // Sidebar
                Container(
                  width: 280,
                  color: theme.colorScheme.surface,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overview', 
                        style: TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.bold, 
                          color: theme.textTheme.bodySmall?.color, 
                          letterSpacing: 1.2
                        )
                      ),
                      const SizedBox(height: 16),
                      _StatTile(title: 'Total Production Logs', value: storage.productionLogs.length.toString(), icon: LucideIcons.clipboardList),
                      const SizedBox(height: 12),
                      _StatTile(title: 'Total Egg Lab Logs', value: storage.eggLogs.length.toString(), icon: LucideIcons.egg),
                      const SizedBox(height: 24),
                      Text(
                        'Device Pairing', 
                        style: TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.bold, 
                          color: theme.textTheme.bodySmall?.color, 
                          letterSpacing: 1.2
                        )
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(LucideIcons.smartphone),
                        label: const Text('Connect Mobile App'),
                        onPressed: _showPairingQR,
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          color: theme.colorScheme.surface,
                          child: TabBar(
                            labelColor: theme.primaryColor,
                            unselectedLabelColor: theme.textTheme.bodySmall?.color,
                            indicatorColor: theme.primaryColor,
                            tabs: const [
                              Tab(text: 'Daily Production Data'),
                              Tab(text: 'Egg Lab Quality Data'),
                              Tab(text: 'Economic Efficiency'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildProductionTable(context, storage.productionLogs),
                              _buildEggTable(context, storage.eggLogs),
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

  Widget _buildLiveAnalyticsBar(BuildContext context, StorageService storage) {
    final theme = Theme.of(context);
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
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          _buildAnalyticsCard(context, 'Avg HDEP %', '${avgHdep.toStringAsFixed(1)}%', LucideIcons.trendingUp, avgHdep > 80 ? Colors.green : Colors.orange),
          const SizedBox(width: 20),
          _buildAnalyticsCard(context, 'Market Value (Total)', '₱${totalProfit.toStringAsFixed(2)}', LucideIcons.banknote, Colors.blue),
          const SizedBox(width: 20),
          _buildAnalyticsCard(context, 'Researchers active', '2', LucideIcons.users, Colors.deepPurple),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label, 
                style: TextStyle(
                  fontSize: 10, 
                  fontWeight: FontWeight.bold, 
                  color: theme.textTheme.bodySmall?.color, 
                  letterSpacing: 0.5
                )
              ),
              const SizedBox(height: 4),
              Text(
                value, 
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.w900, 
                  color: theme.textTheme.displaySmall?.color
                )
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEconomicTab(BuildContext context, StorageService storage) {
    final theme = Theme.of(context);
    if (storage.productionLogs.isEmpty) {
      return Center(
        child: Text(
          'No production data available for economic analysis.',
          style: TextStyle(color: theme.textTheme.bodySmall?.color),
        )
      );
    }

    final fpCtrl = TextEditingController(text: storage.feedPrice > 0 ? storage.feedPrice.toString() : '');
    final epCtrl = TextEditingController(text: storage.eggPrice > 0 ? storage.eggPrice.toString() : '');

    final summaries = storage.treatmentSummaries;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: theme.colorScheme.surface,
          child: Row(
            children: [
              Text(
                'Input Prices:', 
                style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.displaySmall?.color)
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 150,
                child: TextField(
                  controller: fpCtrl,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: 'Feed Price/kg (₱)', 
                    isDense: true,
                    labelStyle: TextStyle(color: theme.textTheme.bodySmall?.color)
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 150,
                child: TextField(
                  controller: epCtrl,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: 'Egg Price/ea (₱)', 
                    isDense: true,
                    labelStyle: TextStyle(color: theme.textTheme.bodySmall?.color)
                  ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                ),
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
                headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.displaySmall?.color),
                dataTextStyle: TextStyle(color: theme.textTheme.bodyLarge?.color),
                columns: const [
                  DataColumn(label: Text('Treatment')),
                  DataColumn(label: Text('Logs Count')),
                  DataColumn(label: Text('Total Eggs')),
                  DataColumn(label: Text('Total Feed (kg)')),
                  DataColumn(label: Text('Gross Revenue (₱)', style: TextStyle(color: Color(0xFF10B981)))),
                  DataColumn(label: Text('Feed Cost (₱)', style: TextStyle(color: Colors.red))),
                  DataColumn(label: Text('IOFC (₱)', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: summaries.map((s) {
                  return DataRow(
                    cells: [
                      DataCell(Text(s.treatment, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(s.logCount.toString())),
                      DataCell(Text(s.totalEggs.toStringAsFixed(0))),
                      DataCell(Text(s.totalFeedKg.toStringAsFixed(2))),
                      DataCell(Text(s.grossRevenue.toStringAsFixed(2), style: const TextStyle(color: Color(0xFF10B981)))),
                      DataCell(Text(s.feedCost.toStringAsFixed(2), style: const TextStyle(color: Colors.red))),
                      DataCell(Text(s.iofc.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.bold, color: s.iofc >= 0 ? const Color(0xFF047857) : Colors.red))),
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

  Widget _buildProductionTable(BuildContext context, List<ProductionLog> logs) {
    final theme = Theme.of(context);
    if (logs.isEmpty) {
      return Center(child: Text('No daily production data synced yet.', style: TextStyle(color: theme.textTheme.bodySmall?.color)));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.displaySmall?.color),
          dataTextStyle: TextStyle(color: theme.textTheme.bodyLarge?.color),
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
            final date = log.timestamp.split('T').first;
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
                      icon: Icon(LucideIcons.trash2, color: theme.colorScheme.error, size: 18),
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

  Widget _buildEggTable(BuildContext context, List<EggLog> logs) {
    final theme = Theme.of(context);
    if (logs.isEmpty) {
      return Center(child: Text('No egg lab data synced yet.', style: TextStyle(color: theme.textTheme.bodySmall?.color)));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.displaySmall?.color),
          dataTextStyle: TextStyle(color: theme.textTheme.bodyLarge?.color),
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
            final date = log.timestamp.split('T').first;
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
                      icon: Icon(LucideIcons.trash2, color: theme.colorScheme.error, size: 18),
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: theme.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value, 
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold, 
                    color: theme.textTheme.displaySmall?.color
                  )
                ),
                Text(title, style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
