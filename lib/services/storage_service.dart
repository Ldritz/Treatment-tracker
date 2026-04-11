import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/production_log.dart';
import '../models/egg_log.dart';

class StorageService extends ChangeNotifier {
  static const String _prodLogsKey = 'production_logs';
  static const String _eggLogsKey = 'egg_logs';
  static const String _treatmentKey = 'treatment';
  static const String _blockKey = 'block';
  static const String _researcherNameKey = 'researcher_name';
  static const String _feedPriceKey = 'feed_price';
  static const String _eggPriceKey = 'egg_price';

  List<ProductionLog> _productionLogs = [];
  List<EggLog> _eggLogs = [];
  String _treatment = 'T1';
  String _block = '1';
  String _researcherName = '';
  double _feedPrice = 0.0;
  double _eggPrice = 0.0;

  List<ProductionLog> get productionLogs => _productionLogs.where((l) => !l.isDeleted).toList();
  List<EggLog> get eggLogs => _eggLogs.where((l) => !l.isDeleted).toList();
  
  List<ProductionLog> get allProductionLogs => _productionLogs;
  List<EggLog> get allEggLogs => _eggLogs;
  
  String get treatment => _treatment;
  String get block => _block;
  String get researcherName => _researcherName;
  double get feedPrice => _feedPrice;
  double get eggPrice => _eggPrice;

  bool get isProfileComplete => _researcherName.trim().isNotEmpty;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    _treatment = prefs.getString(_treatmentKey) ?? 'T1';
    _block = prefs.getString(_blockKey) ?? '1';
    _researcherName = prefs.getString(_researcherNameKey) ?? '';
    _feedPrice = prefs.getDouble(_feedPriceKey) ?? 0.0;
    _eggPrice = prefs.getDouble(_eggPriceKey) ?? 0.0;

    final prodString = prefs.getString(_prodLogsKey);
    if (prodString != null) {
      final List<dynamic> decoded = jsonDecode(prodString);
      _productionLogs = decoded.map((e) => ProductionLog.fromJson(e)).toList();
    }

    final eggString = prefs.getString(_eggLogsKey);
    if (eggString != null) {
      final List<dynamic> decoded = jsonDecode(eggString);
      _eggLogs = decoded.map((e) => EggLog.fromJson(e)).toList();
    }
    notifyListeners();
  }

  void setTreatment(String t) async {
    _treatment = t;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_treatmentKey, t);
  }

  void setBlock(String b) async {
    _block = b;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_blockKey, b);
  }

  void setResearcherName(String name) async {
    _researcherName = name;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_researcherNameKey, name);
  }

  void setFeedPrice(double price) async {
    _feedPrice = price;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_feedPriceKey, price);
  }

  void setEggPrice(double price) async {
    _eggPrice = price;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_eggPriceKey, price);
  }

  Future<void> addProductionLog(ProductionLog log) async {
    _productionLogs.insert(0, log);
    notifyListeners();
    await _saveData(_prodLogsKey, _productionLogs.map((e) => e.toJson()).toList());
  }

  Future<void> addEggLog(EggLog log) async {
    _eggLogs.insert(0, log);
    notifyListeners();
    await _saveData(_eggLogsKey, _eggLogs.map((e) => e.toJson()).toList());
  }

  Future<void> deleteProductionLog(String id) async {
    final index = _productionLogs.indexWhere((log) => log.id == id);
    if (index != -1) {
      _productionLogs[index] = _productionLogs[index].copyWith(
        isDeleted: true,
        isSynced: false,
        lastModified: DateTime.now().toIso8601String(),
      );
      notifyListeners();
      await _saveData(_prodLogsKey, _productionLogs.map((e) => e.toJson()).toList());
    }
  }

  Future<void> deleteEggLog(String id) async {
    final index = _eggLogs.indexWhere((log) => log.id == id);
    if (index != -1) {
      _eggLogs[index] = _eggLogs[index].copyWith(
        isDeleted: true,
        isSynced: false,
        lastModified: DateTime.now().toIso8601String(),
      );
      notifyListeners();
      await _saveData(_eggLogsKey, _eggLogs.map((e) => e.toJson()).toList());
    }
  }

  Future<void> updateProductionLog(ProductionLog log) async {
    final index = _productionLogs.indexWhere((l) => l.id == log.id);
    if (index != -1) {
      _productionLogs[index] = log.copyWith(
        isSynced: false,
        lastModified: DateTime.now().toIso8601String(),
      );
      notifyListeners();
      await _saveData(_prodLogsKey, _productionLogs.map((e) => e.toJson()).toList());
    }
  }

  Future<void> updateEggLog(EggLog log) async {
    final index = _eggLogs.indexWhere((l) => l.id == log.id);
    if (index != -1) {
      _eggLogs[index] = log.copyWith(
        isSynced: false,
        lastModified: DateTime.now().toIso8601String(),
      );
      notifyListeners();
      await _saveData(_eggLogsKey, _eggLogs.map((e) => e.toJson()).toList());
    }
  }

  Future<void> markProductionLogSynced(String id) async {
    final index = _productionLogs.indexWhere((l) => l.id == id);
    if (index != -1) {
      _productionLogs[index] = _productionLogs[index].copyWith(isSynced: true);
      notifyListeners();
      await _saveData(_prodLogsKey, _productionLogs.map((e) => e.toJson()).toList());
    }
  }

  Future<void> markEggLogSynced(String id) async {
    final index = _eggLogs.indexWhere((l) => l.id == id);
    if (index != -1) {
      _eggLogs[index] = _eggLogs[index].copyWith(isSynced: true);
      notifyListeners();
      await _saveData(_eggLogsKey, _eggLogs.map((e) => e.toJson()).toList());
    }
  }

  Future<void> clearProductionLogs() async {
    _productionLogs.clear();
    notifyListeners();
    await _saveData(_prodLogsKey, []);
  }

  Future<void> clearEggLogs() async {
    _eggLogs.clear();
    notifyListeners();
    await _saveData(_eggLogsKey, []);
  }

  Future<void> mergeProductionLogs(List<ProductionLog> cloudLogs) async {
    bool changed = false;
    for (var cloud in cloudLogs) {
      final localIndex = _productionLogs.indexWhere((l) => l.id == cloud.id);
      
      if (localIndex == -1) {
        // Log doesn't exist locally. Add it, but only if it's not deleted.
        // Actually, we should keep it even if deleted so we don't try to re-sync it up later.
        _productionLogs.add(cloud.copyWith(isSynced: true));
        changed = true;
      } else {
        // Log exists locally. Check which is newer.
        final local = _productionLogs[localIndex];
        final cloudTime = DateTime.parse(cloud.lastModified);
        final localTime = DateTime.parse(local.lastModified);
        
        if (cloudTime.isAfter(localTime)) {
          _productionLogs[localIndex] = cloud.copyWith(isSynced: true);
          changed = true;
        }
      }
    }
    
    if (changed) {
      notifyListeners();
      await _saveData(_prodLogsKey, _productionLogs.map((e) => e.toJson()).toList());
    }
  }

  Future<void> mergeEggLogs(List<EggLog> cloudLogs) async {
    bool changed = false;
    for (var cloud in cloudLogs) {
      final localIndex = _eggLogs.indexWhere((l) => l.id == cloud.id);
      
      if (localIndex == -1) {
        _eggLogs.add(cloud.copyWith(isSynced: true));
        changed = true;
      } else {
        final local = _eggLogs[localIndex];
        final cloudTime = DateTime.parse(cloud.lastModified);
        final localTime = DateTime.parse(local.lastModified);
        
        if (cloudTime.isAfter(localTime)) {
          _eggLogs[localIndex] = cloud.copyWith(isSynced: true);
          changed = true;
        }
      }
    }
    
    if (changed) {
      notifyListeners();
      await _saveData(_eggLogsKey, _eggLogs.map((e) => e.toJson()).toList());
    }
  }

  Future<void> _saveData(String key, List<Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(data));
  }
}
