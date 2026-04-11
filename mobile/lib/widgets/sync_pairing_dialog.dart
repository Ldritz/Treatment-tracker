import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';
import '../theme.dart';

class SyncPairingDialog extends StatefulWidget {
  const SyncPairingDialog({super.key});

  @override
  State<SyncPairingDialog> createState() => _SyncPairingDialogState();
}

class _SyncPairingDialogState extends State<SyncPairingDialog> {
  final TextEditingController _linkController = TextEditingController();
  bool _isScanning = false;

  void _processLink(String link) {
    try {
      final uri = Uri.parse(link.trim());
      String? url;
      String? key;

      if (uri.queryParameters.containsKey('u') && uri.queryParameters.containsKey('k')) {
        url = uri.queryParameters['u'];
        key = uri.queryParameters['k'];
      } else if (link.contains('supabase.co')) {
        // Fallback or direct paste of a supabase-like URL might need more complex parsing
        // For now, let's stick to the structured connect link
      }

      if (url != null && key != null) {
        _applyConfig(url, key);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Invalid pairing link format.'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Error parsing link.'), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  void _applyConfig(String url, String key) async {
    final storage = context.read<StorageService>();
    final sync = context.read<SyncService>();

    await storage.setSyncConfig(url, key);
    await sync.reinitialize();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully linked to cloud! Syncing data...'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Link to Website',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.displaySmall?.color),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan the QR code on your dashboard or paste the pairing link below.',
              style: TextStyle(color: theme.textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 24),
            if (_isScanning)
              Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: MobileScanner(
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty) {
                        final String? code = barcodes.first.rawValue;
                        if (code != null) {
                          setState(() => _isScanning = false);
                          _processLink(code);
                        }
                      }
                    },
                  ),
                ),
              )
            else
              Column(
                children: [
                   TextField(
                    controller: _linkController,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      labelText: 'Pairing Link',
                      hintText: 'https://.../connect?u=...&k=...',
                      prefixIcon: const Icon(Icons.link),
                      labelStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
                      hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.5)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _isScanning = true),
                    icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                    label: const Text('Scan QR Code', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                ),
                const SizedBox(width: 8),
                if (!_isScanning)
                  ElevatedButton(
                    onPressed: () => _processLink(_linkController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Link Now'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
