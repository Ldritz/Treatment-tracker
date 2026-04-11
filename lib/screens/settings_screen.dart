import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/storage_service.dart';
import '../theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _updateName(BuildContext context) {
    final storage = context.read<StorageService>();
    final controller = TextEditingController(text: storage.researcherName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Edit Researcher Name', style: TextStyle(color: AppTheme.textDark)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            hintText: 'Enter your name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                storage.setResearcherName(controller.text.trim());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Researcher name updated.')),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _clearLogs(BuildContext context, bool isDaily) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Clear Data', style: TextStyle(color: AppTheme.textDark)),
        content: Text('Are you sure you want to permanently delete all ${isDaily ? 'Daily Production' : 'Egg Lab'} logs? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () {
              final storage = context.read<StorageService>();
              isDaily ? storage.clearProductionLogs() : storage.clearEggLogs();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${isDaily ? 'Daily' : 'Egg'} logs cleared.'), backgroundColor: AppTheme.error),
              );
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.textMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildListTile(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap, bool isDestructive = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: AppTheme.surfaceLowest,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            Icon(icon, color: isDestructive ? AppTheme.error : AppTheme.primary, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDestructive ? AppTheme.error : AppTheme.textDark,
                ),
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: AppTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildListGroup(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F181C20),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 16.0, bottom: 64.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Researcher Profile'),
            _buildListGroup([
              Consumer<StorageService>(
                builder: (context, storage, _) => _buildListTile(
                  context,
                  title: 'Name: ${storage.researcherName}',
                  icon: LucideIcons.user,
                  onTap: () => _updateName(context),
                ),
              ),
            ]),
            const SizedBox(height: 32),
            _buildSectionHeader('Data Management'),
            _buildListGroup([
              _buildListTile(
                context,
                title: 'Clear Daily Logs',
                icon: LucideIcons.trash2,
                isDestructive: true,
                onTap: () => _clearLogs(context, true),
              ),
              const Divider(height: 1, color: AppTheme.surfaceHighest),
              _buildListTile(
                context,
                title: 'Clear Egg Lab Logs',
                icon: LucideIcons.eraser,
                isDestructive: true,
                onTap: () => _clearLogs(context, false),
              ),
            ]),
            const SizedBox(height: 32),
            _buildSectionHeader('App Info'),
            _buildListGroup([
              _buildListTile(
                context,
                title: 'Version',
                icon: LucideIcons.info,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Quail Logger v1.0.0')),
                  );
                },
              ),
              const Divider(height: 1, color: AppTheme.surfaceHighest),
              _buildListTile(
                context,
                title: 'Formulas Overview',
                icon: LucideIcons.calculator,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppTheme.surface,
                      title: const Text('Official Formulas', style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)),
                      content: const SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('HDEP%', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                            Text('(Number of eggs / (Number of birds alive * Days)) * 100\n'),
                            Text('VFI (Voluntary Feed Intake)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                            Text('Feed Given - Feed Refusal\n'),
                            Text('FCR (Feed Conversion Ratio)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                            Text('VFI / Total Egg Mass\n'),
                            Text('Haugh Unit (HU)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                            Text('100 * log10(H - 1.7 * W^0.37 + 7.6)\n*(H = Albumen height in mm, W = Egg weight in g)*'),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Close', style: TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
