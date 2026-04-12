import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';
import '../widgets/custom_button.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _exportCSV() async {
    try {
      final storage = context.read<StorageService>();
      final isProd = _tabController.index == 0;
      
      final buffer = StringBuffer();
      String filename = '';

      if (isProd) {
        filename = 'Quail_Production_Logs.csv';
        buffer.writeln('ID,Date,Treatment,Block,Eggs,EggMass(g),QuailsAlive,Days,FeedGiven(g),FeedRefusal(g),VFI(g),FCR,HDEP(%)');
        for (var log in storage.productionLogs) {
          buffer.writeln('${log.id},${log.timestamp},${log.treatment},${log.block},${log.eggs},${log.eggMass},${log.quails},${log.days},${log.feedGiven},${log.feedRefusal},${log.vfi},${log.fcr},${log.hdep}');
        }
      } else {
        filename = 'Quail_Egg_Lab_Logs.csv';
        buffer.writeln('ID,Date,Treatment,Block,Weight(g),L1(mm),L2(mm),L3(mm),LengthAvg(mm),W1(mm),W2(mm),W3(mm),WidthAvg(mm),AlbumenHeight(mm),ShellWeight(g),YolkWeight(g),HaughUnit,ShapeIndex(%),YolkPct(%)');
        for (var log in storage.eggLogs) {
          buffer.writeln('${log.id},${log.timestamp},${log.treatment},${log.block},${log.weight},${log.l1},${log.l2},${log.l3},${log.length},${log.w1},${log.w2},${log.w3},${log.width},${log.albumenHeight},${log.shellWeight},${log.yolkWeight},${log.haughUnit},${log.shapeIndex},${log.yolkPct}');
        }
      }

      final csvString = buffer.toString();

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(csvString);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Here is the exported CSV file.',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to generate CSV.')));
    }
  }

  void _confirmDelete(String id, bool isProd) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to delete this log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final storage = context.read<StorageService>();
              if (isProd) {
                storage.deleteProductionLog(id);
              } else {
                storage.deleteEggLog(id);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(dynamic item, bool isProd) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        boxShadow: theme.brightness == Brightness.dark ? [] : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.treatment} | Block ${item.block}', 
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold, 
                        color: theme.textTheme.displaySmall?.color
                      )
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, yyyy - hh:mm a').format(DateTime.parse(item.timestamp).toLocal()), 
                      style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color)
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(LucideIcons.trash2, color: theme.colorScheme.error),
                onPressed: () => _confirmDelete(item.id, isProd),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
          const SizedBox(height: 12),
          if (isProd)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildGridMetric('VFI/FCR', '${item.vfi} / ${item.fcr}', subtext: '${item.quails} alive')),
                    Expanded(child: _buildGridMetric('Eggs', '${item.eggs}')),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildGridMetric('Mass', '${item.eggMass}g')),
                    Expanded(child: _buildGridMetric('HDEP', '${item.hdep}%')),
                  ],
                ),
              ],
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildGridMetric('Weight', '${item.weight}g')),
                    Expanded(child: _buildGridMetric('HU', '${item.haughUnit}')),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildGridMetric('L x W', '${item.length.toStringAsFixed(1)} x ${item.width.toStringAsFixed(1)}', subtext: 'mm')),
                    Expanded(child: _buildGridMetric('Shape Index', '${item.shapeIndex}%')),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildGridMetric(String label, String value, {String? subtext}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: TextStyle(
            fontSize: 12, 
            color: theme.textTheme.bodySmall?.color, 
            fontWeight: FontWeight.w600
          )
        ),
        const SizedBox(height: 4),
        Text(
          value, 
          style: TextStyle(
            fontSize: 16, 
            color: theme.textTheme.displaySmall?.color, 
            fontWeight: FontWeight.bold
          )
        ),
        if (subtext != null)
           Text(
             subtext, 
             style: TextStyle(fontSize: 10, color: theme.textTheme.bodySmall?.color)
           ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Data & Export', 
          style: TextStyle(color: theme.textTheme.displaySmall?.color, fontWeight: FontWeight.bold)
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(LucideIcons.refreshCw, color: theme.primaryColor),
            onPressed: () => context.read<SyncService>().triggerSync(),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.primaryColor,
          unselectedLabelColor: theme.textTheme.bodySmall?.color,
          indicatorColor: theme.primaryColor,
          tabs: const [
            Tab(text: 'Daily Logs'),
            Tab(text: 'Egg Lab'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(theme, storage.productionLogs, true),
          _buildList(theme, storage.eggLogs, false),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: CustomButton(
            text: 'Export CSV',
            isSecondary: false,
            onPressed: _exportCSV,
          ),
        ),
      ),
    );
  }

  Widget _buildList(ThemeData theme, List<dynamic> logs, bool isProd) {
    if (logs.isEmpty) {
      return Center(
        child: Text(
          'No logs found.', 
          style: TextStyle(color: theme.textTheme.bodySmall?.color)
        )
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (ctx, i) => _buildLogCard(logs[i], isProd),
    );
  }
}
