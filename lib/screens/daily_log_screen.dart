import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../models/production_log.dart';
import '../widgets/input_card.dart';
import '../widgets/stat_box.dart';
import '../widgets/custom_button.dart';
import '../widgets/farm_grid_layout.dart';
import '../widgets/at_a_glance_widget.dart';
import '../theme.dart';

class DailyLogScreen extends StatefulWidget {
  const DailyLogScreen({super.key});

  @override
  State<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends State<DailyLogScreen> {
  final TextEditingController _eggsCtrl = TextEditingController();
  final TextEditingController _eggMassCtrl = TextEditingController();
  final TextEditingController _quailsCtrl = TextEditingController(text: '3');
  final TextEditingController _feedGivenCtrl = TextEditingController(text: '90');
  final TextEditingController _feedRefusalCtrl = TextEditingController();

  double _eggsNum = 0;
  double _eggMassNum = 0;
  double _quailsNum = 3;
  final double _daysNum = 1;
  double _feedGivenNum = 90;
  double _feedRefusalNum = 0;

  @override
  void initState() {
    super.initState();
    _eggsCtrl.addListener(_calcStats);
    _eggMassCtrl.addListener(_calcStats);
    _quailsCtrl.addListener(_calcStats);
    _feedGivenCtrl.addListener(_calcStats);
    _feedRefusalCtrl.addListener(_calcStats);
  }

  void _calcStats() {
    setState(() {
      _eggsNum = double.tryParse(_eggsCtrl.text) ?? 0;
      _eggMassNum = double.tryParse(_eggMassCtrl.text) ?? 0;
      
      double parsedQuails = double.tryParse(_quailsCtrl.text) ?? 3;
      if (parsedQuails == 0) parsedQuails = 1;

      if (parsedQuails != _quailsNum) {
        _quailsNum = parsedQuails;
        // Auto-calculate Feed Given (30g per bird per day) based on new quails count
        _feedGivenCtrl.text = (_quailsNum * 30).toStringAsFixed(0);
      } else {
        _quailsNum = parsedQuails;
      }

      _feedGivenNum = double.tryParse(_feedGivenCtrl.text) ?? 0;
      _feedRefusalNum = double.tryParse(_feedRefusalCtrl.text) ?? 0;
    });
  }

  double get vfi {
    return _feedGivenNum - _feedRefusalNum;
  }

  double get fcr {
    if (_eggMassNum > 0) {
      return vfi / _eggMassNum;
    }
    return 0;
  }

  double get hdep {
    return (_eggsNum / (_quailsNum * _daysNum)) * 100;
  }

  @override
  void dispose() {
    _eggsCtrl.dispose();
    _eggMassCtrl.dispose();
    _quailsCtrl.dispose();
    _feedGivenCtrl.dispose();
    _feedRefusalCtrl.dispose();
    super.dispose();
  }

  void _saveLog() {
    if (_eggsCtrl.text.isEmpty || _feedRefusalCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Eggs and Feed Refusal.')));
      return;
    }

    final storage = context.read<StorageService>();
    final newLog = ProductionLog(
      id: UniqueKey().toString(),
      timestamp: DateTime.now().toIso8601String(),
      treatment: storage.treatment,
      block: storage.block,
      eggs: _eggsNum,
      eggMass: _eggMassNum,
      quails: _quailsNum,
      days: _daysNum,
      feedGiven: _feedGivenNum,
      feedRefusal: _feedRefusalNum,
      vfi: double.parse(vfi.toStringAsFixed(1)),
      fcr: double.parse(fcr.toStringAsFixed(2)),
      hdep: double.parse(hdep.toStringAsFixed(1)),
      recordedby: storage.researcherName,
    );

    storage.addProductionLog(newLog);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Daily Log Saved successfully!'), backgroundColor: AppTheme.secondary));
    
    _eggsCtrl.clear();
    _eggMassCtrl.clear();
    _feedRefusalCtrl.clear();
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
            const AtAGlanceWidget(isDailyMode: true),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const FarmGridLayout(indicatorContext: 'daily'),
            ),
            const SizedBox(height: 24),
            const Text('Performance Data (Daily)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: InputCard(label: 'Number of Eggs', placeholder: '#', controller: _eggsCtrl)),
                const SizedBox(width: 8),
                Expanded(child: InputCard(label: 'Total Egg Mass', placeholder: 'g', unit: 'g', controller: _eggMassCtrl)),
              ],
            ),
            InputCard(label: 'Number of quails alive', controller: _quailsCtrl),
            InputCard(label: 'Feed Given', placeholder: '90', unit: 'g', controller: _feedGivenCtrl),
            InputCard(label: 'Feed Refusal', placeholder: 'Leftover feed', unit: 'g', controller: _feedRefusalCtrl),
            const SizedBox(height: 16),
            Row(
              children: [
                StatBox(label: 'VFI', value: vfi.toStringAsFixed(1), unit: 'g'),
                const SizedBox(width: 8),
                StatBox(label: 'FCR', value: fcr.toStringAsFixed(2), color: const Color(0xFF10B981)),
                const SizedBox(width: 8),
                StatBox(label: 'Daily HDEP', value: hdep.toStringAsFixed(1), unit: '%', color: AppTheme.secondary),
              ],
            ),
            const SizedBox(height: 32),
            CustomButton(title: 'Save Record', onPressed: _saveLog),
          ],
        ),
      ),
    );
  }
}
