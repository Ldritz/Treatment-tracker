import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'storage_service.dart';
import '../models/production_log.dart';
import '../models/egg_log.dart';

enum SyncState { online, syncing, offline, disabled }

class SyncService with ChangeNotifier {
  final StorageService storageService;
  SupabaseClient? _supabase;
  
  SyncState _status = SyncState.offline;
  SyncState get status => _status;
  
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  SyncService(this.storageService) {
    _init();
    
    // Listen to local storage changes so we trigger a sync when new logs are added
    storageService.addListener(() {
      if (_status != SyncState.disabled) {
        _syncData();
      }
    });
  }

  void _init() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (storageService.hasSyncConfig) {
        if (results.contains(ConnectivityResult.none)) {
          _setStatus(SyncState.offline);
        } else {
          _syncData();
        }
      } else {
        _setStatus(SyncState.disabled);
      }
    });

    _syncData();
  }

  Future<bool> _ensureInitialized() async {
    if (!storageService.hasSyncConfig) {
      if (kIsWeb) {
        // Fallback to default project for web dashboard
        _supabase = SupabaseClient(
          'https://lpyxwxfmshuwwogalkfd.supabase.co',
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxweXh3eGZtc2h1d3dvZ2Fsa2ZkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU4MDEzNDAsImV4cCI6MjA5MTM3NzM0MH0.pWDpmmWQDugls7-SDNI5gWUk-ImkdE6ksYxxrS7dwfU',
        );
        return true;
      }
      _setStatus(SyncState.disabled);
      _supabase = null;
      return false;
    }

    // If already initialized with the correct URL, return
    if (_supabase != null && storageService.syncUrl == _supabase!.rest.url.toString().replaceFirst('/rest/v1', '')) {
      return true;
    }

    try {
      _supabase = SupabaseClient(
        storageService.syncUrl!,
        storageService.syncKey!,
      );
      return true;
    } catch (e) {
      debugPrint('Supabase init error: $e');
      _supabase = null;
      return false;
    }
  }

  void _setStatus(SyncState newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      notifyListeners();
    }
  }

  Future<void> _syncData() async {
    if (!storageService.hasSyncConfig) {
      _setStatus(SyncState.disabled);
      return;
    }

    final initialized = await _ensureInitialized();
    if (!initialized) return;

    // On web, connectivity_plus is unreliable — skip the check and attempt directly.
    if (!kIsWeb) {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        _setStatus(SyncState.offline);
        return;
      }
    }

    _setStatus(SyncState.syncing);
    
    try {
      // 1. PULL: Fetch from Supabase
      final prodResponse = await _supabase!.from('production_logs').select();
      final List<dynamic> prodList = prodResponse as List<dynamic>;
      final List<ProductionLog> cloudProds = prodList.map((e) => ProductionLog.fromJson(e)).toList();
      await storageService.mergeProductionLogs(cloudProds);

      final eggResponse = await _supabase!.from('egg_logs').select();
      final List<dynamic> eggList = eggResponse as List<dynamic>;
      final List<EggLog> cloudEggs = eggList.map((e) => EggLog.fromJson(e)).toList();
      await storageService.mergeEggLogs(cloudEggs);

      // 2. PUSH: Local unsynced changes to Supabase
      final unsyncedProdLogs = storageService.allProductionLogs.where((l) => !l.isSynced).toList();
      final unsyncedEggLogs = storageService.allEggLogs.where((l) => !l.isSynced).toList();

      if (unsyncedProdLogs.isNotEmpty) {
        final prodData = unsyncedProdLogs.map((l) {
          final json = l.toJson();
          json.remove('issynced');
          json.remove('is_synced');
          json.remove('isSynced');
          return json;
        }).toList();
        await _supabase!.from('production_logs').upsert(prodData);
        for (var log in unsyncedProdLogs) {
          await storageService.markProductionLogSynced(log.id);
        }
      }

      if (unsyncedEggLogs.isNotEmpty) {
        final eggData = unsyncedEggLogs.map((l) {
          final json = l.toJson();
          json.remove('issynced');
          json.remove('is_synced');
          json.remove('isSynced');
          return json;
        }).toList();
        await _supabase!.from('egg_logs').upsert(eggData);
        for (var log in unsyncedEggLogs) {
          await storageService.markEggLogSynced(log.id);
        }
      }
      
      _setStatus(SyncState.online);
    } catch (e) {
      debugPrint('Sync error: $e');
      _setStatus(SyncState.offline);
    }
  }

  /// Manually force a re-initialization (e.g. after changing config)
  Future<void> reinitialize() async {
    _supabase = null; // Clear local reference
    _setStatus(SyncState.offline);
    await _syncData();
  }

  // Allow manual sync triggers
  Future<void> triggerSync() async {
    await _syncData();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}
