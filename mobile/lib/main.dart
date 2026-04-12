import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'theme.dart';
import 'services/storage_service.dart';
import 'screens/splash_screen.dart';
import 'screens/daily_log_screen.dart';
import 'screens/egg_lab_screen.dart';
import 'screens/history_screen.dart';
import 'screens/economics_screen.dart';
import 'screens/settings_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/sync_service.dart';
import 'widgets/floating_dock.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storageService = StorageService();
  await storageService.init();

  final syncService = SyncService(storageService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: storageService),
        ChangeNotifierProvider.value(value: syncService),
      ],
      child: const QuailLoggerApp(),
    ),
  );
}

class QuailLoggerApp extends StatelessWidget {
  const QuailLoggerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    
    return MaterialApp(
      title: 'CoturniSync',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: storage.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}

class MainTabContainer extends StatefulWidget {
  const MainTabContainer({super.key});

  @override
  State<MainTabContainer> createState() => _MainTabContainerState();
}

class _MainTabContainerState extends State<MainTabContainer> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DailyLogScreen(),
    const EggLabScreen(),
    const HistoryScreen(),
    const EconomicsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('CoturniSync', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          Consumer<SyncService>(
            builder: (context, sync, child) {
              IconData icon;
              Color color;
              if (sync.status == SyncState.online) {
                icon = LucideIcons.cloudLightning;
                color = const Color(0xFF10B981); // Emerald
              } else if (sync.status == SyncState.syncing) {
                icon = LucideIcons.refreshCw;
                color = theme.primaryColor;
              } else if (sync.status == SyncState.disabled) {
                icon = LucideIcons.cloudOff;
                color = theme.textTheme.bodySmall?.color ?? Colors.grey;
              } else {
                icon = LucideIcons.cloudOff;
                color = theme.colorScheme.error;
              }
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Icon(icon, color: color, size: 24),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: FloatingDock(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          FloatingDockItem(icon: LucideIcons.clipboardList, label: 'Daily'),
          FloatingDockItem(icon: LucideIcons.egg, label: 'Egg Lab'),
          FloatingDockItem(icon: LucideIcons.history, label: 'History'),
          FloatingDockItem(icon: LucideIcons.coins, label: 'Economics'),
          FloatingDockItem(icon: LucideIcons.settings, label: 'Settings'),
        ],
      ),
    );
  }
}
