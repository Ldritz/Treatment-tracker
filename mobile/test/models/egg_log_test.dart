import 'package:flutter_test/flutter_test.dart';
import 'package:quail_logger_flutter/models/egg_log.dart';

void main() {
  group('EggLog JSON Serialization', () {
    final Map<String, dynamic> standardJson = {
      'id': 'log-123',
      'timestamp': '2026-04-12T12:00:00Z',
      'treatment': 'T1',
      'block': 'B1',
      'weight': 10.5,
      'l1': 30.1,
      'l2': 30.2,
      'l3': 30.3,
      'length': 30.2,
      'w1': 20.1,
      'w2': 20.2,
      'w3': 20.3,
      'width': 20.2,
      'albumenheight': 5.5,
      'shellweight': 1.2,
      'yolkweight': 3.4,
      'haughunit': 70.0,
      'shapeindex': 66.8,
      'yolkpct': 32.4,
      'isdeleted': false,
      'issynced': true,
      'lastmodified': '2026-04-12T12:30:00Z',
      'recordedby': 'Researcher A',
    };

    test('should correctly parse standard lowercase JSON', () {
      final log = EggLog.fromJson(standardJson);

      expect(log.id, 'log-123');
      expect(log.weight, 10.5);
      expect(log.albumenHeight, 5.5);
      expect(log.isSynced, true);
      expect(log.recordedby, 'Researcher A');
    });

    test('should correctly parse snake_case fallback keys', () {
      final Map<String, dynamic> snakeCaseJson = {
        ...standardJson,
        'albumen_height': 6.0,
        'shell_weight': 1.5,
        'yolk_weight': 3.5,
        'haugh_unit': 75.0,
        'shape_index': 67.0,
        'yolk_pct': 33.0,
        'is_deleted': true,
        'is_synced': false,
        'last_modified': '2026-04-12T13:00:00Z',
      };
      
      // Remove the lowercase versions to force fallback
      snakeCaseJson.remove('albumenheight');
      snakeCaseJson.remove('shellweight');
      snakeCaseJson.remove('yolkweight');
      snakeCaseJson.remove('haughunit');
      snakeCaseJson.remove('shapeindex');
      snakeCaseJson.remove('yolkpct');
      snakeCaseJson.remove('isdeleted');
      snakeCaseJson.remove('issynced');
      snakeCaseJson.remove('lastmodified');

      final log = EggLog.fromJson(snakeCaseJson);

      expect(log.albumenHeight, 6.0);
      expect(log.shellWeight, 1.5);
      expect(log.haughUnit, 75.0);
      expect(log.isDeleted, true);
      expect(log.lastModified, '2026-04-12T13:00:00Z');
    });

    test('should correctly parse camelCase fallback keys', () {
      final Map<String, dynamic> camelCaseJson = {
        ...standardJson,
        'albumenHeight': 7.0,
        'shellWeight': 2.0,
        'haughUnit': 80.0,
      };
      
      camelCaseJson.remove('albumenheight');
      camelCaseJson.remove('shellweight');
      camelCaseJson.remove('haughunit');

      final log = EggLog.fromJson(camelCaseJson);

      expect(log.albumenHeight, 7.0);
      expect(log.shellWeight, 2.0);
      expect(log.haughUnit, 80.0);
    });

    test('should fulfill round-trip serialization (toJson -> fromJson)', () {
      final logInitial = EggLog(
        id: 'round-trip-id',
        timestamp: '2026-04-12T10:00:00Z',
        treatment: 'T2',
        block: 'B2',
        weight: 12.0,
        l1: 31.0, l2: 31.0, l3: 31.0, length: 31.0,
        w1: 21.0, w2: 21.0, w3: 21.0, width: 21.0,
        albumenHeight: 6.0,
        shellWeight: 1.4,
        yolkWeight: 3.6,
        haughUnit: 72.0,
        shapeIndex: 68.0,
        yolkPct: 30.0,
        recordedby: 'Researcher B',
      );

      final json = logInitial.toJson();
      final logResult = EggLog.fromJson(json);

      expect(logResult.id, logInitial.id);
      expect(logResult.treatment, logInitial.treatment);
      expect(logResult.albumenHeight, logInitial.albumenHeight);
      expect(logResult.recordedby, logInitial.recordedby);
    });

    test('should handle numeric types (int as double) correctly', () {
      final Map<String, dynamic> mixedJson = {
        ...standardJson,
        'weight': 10, // int
        'l1': 30,     // int
      };

      final log = EggLog.fromJson(mixedJson);
      expect(log.weight, 10.0);
      expect(log.l1, 30.0);
    });

    test('should use default values for missing optional fields', () {
      final Map<String, dynamic> minimalJson = {
        'id': 'min-id',
        'timestamp': '2026-04-12T10:00:00Z',
        'treatment': 'T1',
        'block': 'B1',
        'weight': 10.0,
        'length': 30.0,
        'width': 20.0,
      };

      final log = EggLog.fromJson(minimalJson);

      expect(log.l1, 0.0);
      expect(log.albumenHeight, 0.0);
      expect(log.isDeleted, false);
      expect(log.recordedby, '');
    });
  });
}
