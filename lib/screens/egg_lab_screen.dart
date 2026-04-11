import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../models/egg_log.dart';
import '../widgets/input_card.dart';
import '../widgets/stat_box.dart';
import '../widgets/custom_button.dart';
import '../widgets/farm_grid_layout.dart';
import '../widgets/at_a_glance_widget.dart';
import '../theme.dart';

class EggLabScreen extends StatefulWidget {
  const EggLabScreen({super.key});

  @override
  State<EggLabScreen> createState() => _EggLabScreenState();
}

class _EggLabScreenState extends State<EggLabScreen> {
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _l1Ctrl = TextEditingController();
  final TextEditingController _l2Ctrl = TextEditingController();
  final TextEditingController _l3Ctrl = TextEditingController();
  final TextEditingController _w1Ctrl = TextEditingController();
  final TextEditingController _w2Ctrl = TextEditingController();
  final TextEditingController _w3Ctrl = TextEditingController();
  final TextEditingController _albumenCtrl = TextEditingController();
  final TextEditingController _shellCtrl = TextEditingController();
  final TextEditingController _yolkCtrl = TextEditingController();

  double _w = 0, _l = 0, _wd = 0, _h = 0, _sw = 0, _yw = 0;

  @override
  void initState() {
    super.initState();
    _weightCtrl.addListener(_calcStats);
    _l1Ctrl.addListener(_calcStats);
    _l2Ctrl.addListener(_calcStats);
    _l3Ctrl.addListener(_calcStats);
    _w1Ctrl.addListener(_calcStats);
    _w2Ctrl.addListener(_calcStats);
    _w3Ctrl.addListener(_calcStats);
    _albumenCtrl.addListener(_calcStats);
    _shellCtrl.addListener(_calcStats);
    _yolkCtrl.addListener(_calcStats);
  }

  void _calcStats() {
    setState(() {
      _w = double.tryParse(_weightCtrl.text) ?? 0;
      double l1 = double.tryParse(_l1Ctrl.text) ?? 0;
      double l2 = double.tryParse(_l2Ctrl.text) ?? 0;
      double l3 = double.tryParse(_l3Ctrl.text) ?? 0;
      _l = (l1 + l2 + l3) / 3;

      double w1 = double.tryParse(_w1Ctrl.text) ?? 0;
      double w2 = double.tryParse(_w2Ctrl.text) ?? 0;
      double w3 = double.tryParse(_w3Ctrl.text) ?? 0;
      _wd = (w1 + w2 + w3) / 3;
      _h = double.tryParse(_albumenCtrl.text) ?? 0;
      _sw = double.tryParse(_shellCtrl.text) ?? 0;
      _yw = double.tryParse(_yolkCtrl.text) ?? 0;
    });
  }

  double get haughUnit {
    if (_h > 0 && _w > 0) {
      double val = 100 * log10(_h - 1.7 * pow(_w, 0.37) + 7.6);
      return val.isNaN ? 0 : val;
    }
    return 0;
  }

  double get shapeIndex {
    if (_l > 0 && _wd > 0) {
      return (_wd / _l) * 100;
    }
    return 0;
  }

  double get yolkPct {
    if (_w > 0 && _yw > 0) {
      return (_yw / _w) * 100;
    }
    return 0;
  }

  double log10(num x) => log(x) / ln10;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _l1Ctrl.dispose();
    _l2Ctrl.dispose();
    _l3Ctrl.dispose();
    _w1Ctrl.dispose();
    _w2Ctrl.dispose();
    _w3Ctrl.dispose();
    _albumenCtrl.dispose();
    _shellCtrl.dispose();
    _yolkCtrl.dispose();
    super.dispose();
  }

  void _saveLog() {
    if (_weightCtrl.text.isEmpty || 
        _l1Ctrl.text.isEmpty || _l2Ctrl.text.isEmpty || _l3Ctrl.text.isEmpty ||
        _w1Ctrl.text.isEmpty || _w2Ctrl.text.isEmpty || _w3Ctrl.text.isEmpty ||
        _albumenCtrl.text.isEmpty || _shellCtrl.text.isEmpty || _yolkCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all egg trait fields.')));
      return;
    }

    final storage = context.read<StorageService>();
    final newLog = EggLog(
      id: UniqueKey().toString(),
      timestamp: DateTime.now().toIso8601String(),
      treatment: storage.treatment,
      block: storage.block,
      weight: _w,
      l1: double.tryParse(_l1Ctrl.text) ?? 0,
      l2: double.tryParse(_l2Ctrl.text) ?? 0,
      l3: double.tryParse(_l3Ctrl.text) ?? 0,
      length: _l,
      w1: double.tryParse(_w1Ctrl.text) ?? 0,
      w2: double.tryParse(_w2Ctrl.text) ?? 0,
      w3: double.tryParse(_w3Ctrl.text) ?? 0,
      width: _wd,
      albumenHeight: _h,
      shellWeight: _sw,
      yolkWeight: _yw,
      haughUnit: double.parse(haughUnit.toStringAsFixed(1)),
      shapeIndex: double.parse(shapeIndex.toStringAsFixed(1)),
      yolkPct: double.parse(yolkPct.toStringAsFixed(1)),
    );

    storage.addEggLog(newLog);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Egg Lab Log Saved successfully!'), backgroundColor: AppTheme.secondary));
    
    _weightCtrl.clear();
    _l1Ctrl.clear();
    _l2Ctrl.clear();
    _l3Ctrl.clear();
    _w1Ctrl.clear();
    _w2Ctrl.clear();
    _w3Ctrl.clear();
    _albumenCtrl.clear();
    _shellCtrl.clear();
    _yolkCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16).copyWith(bottom: 100, top: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AtAGlanceWidget(isDailyMode: false),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const FarmGridLayout(indicatorContext: 'egg'),
            ),
            const SizedBox(height: 24),
            const Text('Egg Characteristics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 16),
            InputCard(label: 'Egg Weight', unit: 'g', controller: _weightCtrl),
            const SizedBox(height: 16),
            const Text('Dimensions (3 Readings averaged)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: InputCard(label: 'L1', placeholder: 'mm', controller: _l1Ctrl)),
                const SizedBox(width: 8),
                Expanded(child: InputCard(label: 'L2', placeholder: 'mm', controller: _l2Ctrl)),
                const SizedBox(width: 8),
                Expanded(child: InputCard(label: 'L3', placeholder: 'mm', controller: _l3Ctrl)),
              ],
            ),
            Row(
              children: [
                Expanded(child: InputCard(label: 'W1', placeholder: 'mm', controller: _w1Ctrl)),
                const SizedBox(width: 8),
                Expanded(child: InputCard(label: 'W2', placeholder: 'mm', controller: _w2Ctrl)),
                const SizedBox(width: 8),
                Expanded(child: InputCard(label: 'W3', placeholder: 'mm', controller: _w3Ctrl)),
              ],
            ),
            if (_l > 0 && _wd > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text('Averages → Length: ${_l.toStringAsFixed(2)} mm | Width: ${_wd.toStringAsFixed(2)} mm', style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.bold)),
              ),
            InputCard(label: 'Albumen Height', unit: 'mm', controller: _albumenCtrl),
            Row(
              children: [
                Expanded(child: InputCard(label: 'Shell Weight', unit: 'g', controller: _shellCtrl)),
                const SizedBox(width: 8),
                Expanded(child: InputCard(label: 'Yolk Weight', unit: 'g', controller: _yolkCtrl)),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Lab Results (Auto Calculate)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 16),
            Row(
              children: [
                StatBox(label: 'Haugh Unit (HU)', value: haughUnit.toStringAsFixed(1), color: const Color(0xFF818CF8)),
                const SizedBox(width: 8),
                StatBox(label: 'Shape Index', value: shapeIndex.toStringAsFixed(1), unit: '%', color: AppTheme.secondaryLight),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                StatBox(label: 'Yolk Percentage', value: yolkPct.toStringAsFixed(1), unit: '%', color: const Color(0xFFF59E0B)),
              ],
            ),
            const SizedBox(height: 32),
            CustomButton(title: 'Save Lab Record', onPressed: _saveLog),
          ],
        ),
      ),
    );
  }
}
