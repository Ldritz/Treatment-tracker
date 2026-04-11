import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import 'formula_reference_screen.dart';
import '../widgets/sync_pairing_dialog.dart';
import '../services/sync_service.dart';

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

  void _showPairingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const SyncPairingDialog(),
    );
  }

  void _disconnectCloud(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Disconnect Cloud Sync?', style: TextStyle(color: AppTheme.textDark)),
        content: const Text('Your data will stay safe on this device, but it will no longer be backed up to the cloud. You can reconnect anytime.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () {
              context.read<StorageService>().clearSyncConfig();
              context.read<SyncService>().reinitialize();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cloud sync disabled.')),
              );
            },
            child: const Text('Disconnect', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: theme.brightness == Brightness.dark ? const Color(0xFF94A3B8) : theme.primaryColor.withOpacity(0.7),
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context),
              const SizedBox(height: 32),

              // Appearance Section
              _buildSectionHeader(context, 'Appearance'),
              const SizedBox(height: 12),
              _buildAppearanceCard(context),
              const SizedBox(height: 32),

              // Cloud Sync Section
              _buildSectionHeader(context, 'Cloud Sync & Server'),
              const SizedBox(height: 12),
              _buildCloudSyncCard(context),
              const SizedBox(height: 32),

              // Researcher Profile
              _buildSectionHeader(context, 'Researcher Profile'),
              const SizedBox(height: 12),
              Consumer<StorageService>(
                builder: (context, storage, _) => _buildProfileCard(context, storage),
              ),
              const SizedBox(height: 32),

              // Data Management
              _buildSectionHeader(context, 'Data Management'),
              const SizedBox(height: 12),
              _buildDataManagementCard(context),
              const SizedBox(height: 32),

              // App Info
              _buildSectionHeader(context, 'Information'),
              const SizedBox(height: 12),
              _buildInfoCard(context),
              
              const SizedBox(height: 48),
              
              // Footer
              Center(
                child: Text(
                  'QUAIL LOGGER v1.0.0',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.3),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(LucideIcons.settings, color: theme.primaryColor, size: 28),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  color: theme.textTheme.displayMedium?.color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Manage your app preferences and data',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceCard(BuildContext context) {
    final storage = context.watch<StorageService>();
    final isDark = storage.isDarkMode;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _buildActionItem(
            context,
            'Light Mode', 
            LucideIcons.sun, 
            () => storage.setDarkMode(false), 
            iconColor: !isDark ? theme.primaryColor : const Color(0xFF64748B), 
            leading: !isDark ? LucideIcons.checkCircle : LucideIcons.circle
          ),
          Divider(height: 1, color: theme.dividerColor.withOpacity(0.05)),
          _buildActionItem(
            context,
            'Dark Mode', 
            LucideIcons.moon, 
            () => storage.setDarkMode(true), 
            iconColor: isDark ? theme.primaryColor : const Color(0xFF64748B), 
            leading: isDark ? LucideIcons.checkCircle : LucideIcons.circle
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, StorageService storage) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: _buildActionItem(
        context,
        'Researcher: ${storage.researcherName.isEmpty ? "Not Set" : storage.researcherName}',
        LucideIcons.user,
        () => _updateName(context),
        iconColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildDataManagementCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _buildActionItem(context, 'Clear Daily Logs', LucideIcons.trash2, () => _clearLogs(context, true), iconColor: const Color(0xFFF43F5E)),
          Divider(height: 1, color: theme.dividerColor.withOpacity(0.05)),
          _buildActionItem(context, 'Clear Egg Lab Logs', LucideIcons.eraser, () => _clearLogs(context, false), iconColor: const Color(0xFFF43F5E)),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _buildActionItem(context, 'Formulas Reference', LucideIcons.calculator, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const FormulaReferenceScreen()));
          }, iconColor: Theme.of(context).primaryColor),
          Divider(height: 1, color: Colors.white.withOpacity(0.05)),
          _buildActionItem(context, 'About Quail Logger', LucideIcons.info, () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Version 1.0.0 - Built for Researcher Excellence')));
          }, iconColor: const Color(0xFF64748B)),
        ],
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, String title, IconData icon, VoidCallback onTap, {Color? iconColor, IconData? leading}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            if (leading != null) ...[
              Icon(leading, color: iconColor, size: 22),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(icon, color: leading == null ? iconColor : const Color(0xFF64748B), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCloudSyncCard(BuildContext context) {
    final storage = context.watch<StorageService>();
    final sync = context.watch<SyncService>();
    final isConnected = storage.hasSyncConfig;

    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          // Row 1: Connection Status
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isConnected ? LucideIcons.cloud : LucideIcons.cloudOff,
                    color: isConnected ? theme.primaryColor : const Color(0xFFF43F5E),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isConnected ? 'Cloud Connected' : 'Cloud Disconnected',
                        style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isConnected 
                          ? 'Store: ${storage.researcherName.isEmpty ? "OFFLINE-SYNC" : "QL-${storage.researcherName.split(' ')[0].toUpperCase()}"}' 
                          : 'Go to web dashboard to link',
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isConnected)
                  OutlinedButton(
                    onPressed: () => _disconnectCloud(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFF43F5E)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('Disconnect', style: TextStyle(color: Color(0xFFF43F5E))),
                  )
                else
                  ElevatedButton(
                    onPressed: () => _showPairingDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Connect'),
                  ),
              ],
            ),
          ),
          
          Divider(height: 1, color: Colors.white.withOpacity(0.05)),

          // Row 2: Server Info
          if (isConnected)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                   Icon(LucideIcons.server, color: theme.textTheme.bodySmall?.color, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Server URL',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          storage.syncUrl ?? 'N/A',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          if (isConnected)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => sync.triggerSync(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.scaffoldBackgroundColor,
                    foregroundColor: theme.textTheme.bodyLarge?.color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const Icon(LucideIcons.refreshCw, size: 18),
                  label: Text(sync.status == SyncState.syncing ? 'Syncing...' : 'Sync Now'),
                ),
              ),
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
        title: Text(isDaily ? 'Clear Daily Logs?' : 'Clear Egg Lab Logs?', style: const TextStyle(color: AppTheme.textDark)),
        content: const Text('This action cannot be undone. All local logs for this category will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () {
              final storage = context.read<StorageService>();
              if (isDaily) {
                storage.clearProductionLogs();
              } else {
                storage.clearEggLogs();
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isDaily ? 'Daily logs cleared.' : 'Egg lab logs cleared.')),
              );
            },
            child: const Text('Clear All', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
