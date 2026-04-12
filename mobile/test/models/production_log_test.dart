import 'package:flutter_test/flutter_test.dart';
import 'package:quail_logger_flutter/models/production_log.dart';

void main() {
  group('ProductionLog', () {
    final Map<String, dynamic> standardJson = {
      'id': 'test-id',
      'timestamp': '2023-10-27T10:00:00Z',
      'treatment': 'A',
      'block': '1',
      'eggs': 10.0,
      'eggmass': 500.0,
      'quails': 50.0,
      'days': 1.0,
      'feedgiven': 2000.0,
      'feedrefusal': 100.0,
      'vfi': 38.0,
      'fcr': 2.5,
      'hdep': 80.0,
      'isdeleted': false,
      'issynced': true,
      'lastmodified': '2023-10-27T11:00:00Z',
      'recordedby': 'user1',
    };

    test('fromJson should handle happy path with standard keys', () {
      final log = ProductionLog.fromJson(standardJson);

      expect(log.id, 'test-id');
      expect(log.timestamp, '2023-10-27T10:00:00Z');
      expect(log.treatment, 'A');
      expect(log.block, '1');
      expect(log.eggs, 10.0);
      expect(log.eggMass, 500.0);
      expect(log.quails, 50.0);
      expect(log.days, 1.0);
      expect(log.feedGiven, 2000.0);
      expect(log.feedRefusal, 100.0);
      expect(log.vfi, 38.0);
      expect(log.fcr, 2.5);
      expect(log.hdep, 80.0);
      expect(log.isDeleted, false);
      expect(log.isSynced, true);
      expect(log.lastModified, '2023-10-27T11:00:00Z');
      expect(log.recordedby, 'user1');
    });

    test('fromJson should handle fallback keys for eggMass, feedGiven, feedRefusal, isDeleted, isSynced, lastModified', () {
      final Map<String, dynamic> fallbackJson = {
        'id': 'test-id',
        'timestamp': '2023-10-27T10:00:00Z',
        'treatment': 'A',
        'block': '1',
        'eggs': 10,
        'egg_mass': 550.0,
        'quails': 50,
        'days': 1,
        'feed_given': 2100.0,
        'feed_refusal': 110.0,
        'vfi': 39.0,
        'fcr': 2.6,
        'hdep': 81.0,
        'is_deleted': true,
        'is_synced': false,
        'last_modified': '2023-10-27T12:00:00Z',
        'recordedby': 'user1',
      };

      final log = ProductionLog.fromJson(fallbackJson);
      expect(log.eggMass, 550.0);
      expect(log.feedGiven, 2100.0);
      expect(log.feedRefusal, 110.0);
      expect(log.isDeleted, true);
      expect(log.isSynced, false);
      expect(log.lastModified, '2023-10-27T12:00:00Z');

      final Map<String, dynamic> camelFallbackJson = {
        ...fallbackJson,
        'egg_mass': null,
        'feed_given': null,
        'feed_refusal': null,
        'is_deleted': null,
        'is_synced': null,
        'last_modified': null,
        'eggMass': 560.0,
        'feedGiven': 2200.0,
        'feedRefusal': 120.0,
        'isDeleted': true,
        'isSynced': true,
        'lastModified': '2023-10-27T13:00:00Z',
      };

      final logCamel = ProductionLog.fromJson(camelFallbackJson);
      expect(logCamel.eggMass, 560.0);
      expect(logCamel.feedGiven, 2200.0);
      expect(logCamel.feedRefusal, 120.0);
      expect(logCamel.isDeleted, true);
      expect(logCamel.isSynced, true);
      expect(logCamel.lastModified, '2023-10-27T13:00:00Z');
    });

    test('fromJson should use default values for missing fields', () {
      final Map<String, dynamic> minimalJson = {
        'id': 'test-id',
        'timestamp': '2023-10-27T10:00:00Z',
        'treatment': 'A',
        'block': '1',
        'eggs': 10,
        'quails': 50,
        'days': 1,
        'vfi': 38.0,
        'hdep': 80.0,
      };

      final log = ProductionLog.fromJson(minimalJson);
      expect(log.eggMass, 0.0);
      expect(log.feedGiven, 0.0);
      expect(log.feedRefusal, 0.0);
      expect(log.fcr, 0.0);
      expect(log.isDeleted, false);
      expect(log.isSynced, false);
      expect(log.lastModified, '2023-10-27T10:00:00Z');
      expect(log.recordedby, '');
    });

    test('toJson should return a valid Map with expected keys', () {
      final log = ProductionLog(
        id: 'test-id',
        timestamp: '2023-10-27T10:00:00Z',
        treatment: 'A',
        block: '1',
        eggs: 10.0,
        eggMass: 500.0,
        quails: 50.0,
        days: 1.0,
        feedGiven: 2000.0,
        feedRefusal: 100.0,
        vfi: 38.0,
        fcr: 2.5,
        hdep: 80.0,
        isDeleted: false,
        isSynced: true,
        lastModified: '2023-10-27T11:00:00Z',
        recordedby: 'user1',
      );

      final json = log.toJson();

      expect(json['id'], 'test-id');
      expect(json['timestamp'], '2023-10-27T10:00:00Z');
      expect(json['treatment'], 'A');
      expect(json['block'], '1');
      expect(json['eggs'], 10.0);
      expect(json['eggmass'], 500.0);
      expect(json['quails'], 50.0);
      expect(json['days'], 1.0);
      expect(json['feedgiven'], 2000.0);
      expect(json['feedrefusal'], 100.0);
      expect(json['vfi'], 38.0);
      expect(json['fcr'], 2.5);
      expect(json['hdep'], 80.0);
      expect(json['isdeleted'], false);
      expect(json['issynced'], true);
      expect(json['lastmodified'], '2023-10-27T11:00:00Z');
      expect(json['recordedby'], 'user1');
    });

    test('round-trip serialization should maintain data integrity', () {
      final originalLog = ProductionLog(
        id: 'test-id',
        timestamp: '2023-10-27T10:00:00Z',
        treatment: 'A',
        block: '1',
        eggs: 10.0,
        eggMass: 500.0,
        quails: 50.0,
        days: 1.0,
        feedGiven: 2000.0,
        feedRefusal: 100.0,
        vfi: 38.0,
        fcr: 2.5,
        hdep: 80.0,
        isDeleted: false,
        isSynced: true,
        lastModified: '2023-10-27T11:00:00Z',
        recordedby: 'user1',
      );

      final json = originalLog.toJson();
      final recoveredLog = ProductionLog.fromJson(json);

      expect(recoveredLog.id, originalLog.id);
      expect(recoveredLog.timestamp, originalLog.timestamp);
      expect(recoveredLog.treatment, originalLog.treatment);
      expect(recoveredLog.block, originalLog.block);
      expect(recoveredLog.eggs, originalLog.eggs);
      expect(recoveredLog.eggMass, originalLog.eggMass);
      expect(recoveredLog.quails, originalLog.quails);
      expect(recoveredLog.days, originalLog.days);
      expect(recoveredLog.feedGiven, originalLog.feedGiven);
      expect(recoveredLog.feedRefusal, originalLog.feedRefusal);
      expect(recoveredLog.vfi, originalLog.vfi);
      expect(recoveredLog.fcr, originalLog.fcr);
      expect(recoveredLog.hdep, originalLog.hdep);
      expect(recoveredLog.isDeleted, originalLog.isDeleted);
      expect(recoveredLog.isSynced, originalLog.isSynced);
      expect(recoveredLog.lastModified, originalLog.lastModified);
      expect(recoveredLog.recordedby, originalLog.recordedby);
    });
  });
}
