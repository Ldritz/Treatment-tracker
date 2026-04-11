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
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(bottom: 24, left: 20, right: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent, // Uses container color
            elevation: 0,
            selectedItemColor: theme.primaryColor,
            unselectedItemColor: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
            selectedFontSize: 12,
            unselectedFontSize: 12,
            showUnselectedLabels: true,
            onTap: (index) => setState(() => _currentIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(LucideIcons.clipboardList, size: 22),
                ),
                label: 'Daily Logs',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(LucideIcons.egg, size: 22),
                ),
                label: 'Egg Lab',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(LucideIcons.history, size: 22),
                ),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(LucideIcons.coins, size: 22),
                ),
                label: 'Economics',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(LucideIcons.settings, size: 22),
                ),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
