import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../models/production_log.dart';
import '../widgets/input_card.dart';
import '../widgets/stat_box.dart';
import '../widgets/custom_button.dart';
import '../widgets/farm_grid_layout.dart';
import '../widgets/at_a_glance_widget.dart';
import '../widgets/success_overlay.dart';

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

  String? _eggsError;
  String? _eggMassError;
  String? _quailsError;
  String? _feedRefusalError;

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
      if (_eggsCtrl.text.isNotEmpty) {
        if (_eggsNum < 0 || _eggsNum > 20) {
          _eggsError = 'Range: 0-20';
        } else {
          _eggsError = null;
        }
      } else {
        _eggsError = null;
      }

      _eggMassNum = double.tryParse(_eggMassCtrl.text) ?? 0;
      if (_eggMassCtrl.text.isNotEmpty) {
        if (_eggMassNum < 0 || _eggMassNum > 250) {
          _eggMassError = 'Range: 0-250g';
        } else {
          _eggMassError = null;
        }
      } else {
        _eggMassError = null;
      }
      
      double parsedQuails = double.tryParse(_quailsCtrl.text) ?? 3;
      if (_quailsCtrl.text.isNotEmpty) {
        if (parsedQuails < 1 || parsedQuails > 50) {
          _quailsError = 'Range: 1-50';
        } else {
          _quailsError = null;
        }
      } else {
        _quailsError = null;
      }

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
      if (_feedRefusalCtrl.text.isNotEmpty) {
        if (_feedRefusalNum < 0 || _feedRefusalNum > _feedGivenNum * 1.5) {
          _feedRefusalError = 'Improbable value';
        } else {
          _feedRefusalError = null;
        }
      } else {
        _feedRefusalError = null;
      }
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
      SuccessOverlay.show(context, 'Please enter Eggs and Feed Refusal.');
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
    SuccessOverlay.show(context, 'Daily Log Saved!');
    
    _eggsCtrl.clear();
    _eggMassCtrl.clear();
    _feedRefusalCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16).copyWith(bottom: 100, top: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AtAGlanceWidget(isDailyMode: true),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
              ),
              child: const FarmGridLayout(indicatorContext: 'daily'),
            ),
            const SizedBox(height: 24),
            
            // Section 1: Egg Production
            _buildSectionCard(
              context,
              title: 'Egg Production',
              icon: LucideIcons.egg,
              children: [
                Row(
                  children: [
                    Expanded(child: InputCard(label: 'Number of Eggs', placeholder: '#', controller: _eggsCtrl, action: TextInputAction.next, errorText: _eggsError)),
                    const SizedBox(width: 12),
                    Expanded(child: InputCard(label: 'Egg Mass (g)', placeholder: '0.0', controller: _eggMassCtrl, action: TextInputAction.next, errorText: _eggMassError)),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),

            // Section 2: Feed & Performance
            _buildSectionCard(
              context,
              title: 'Feed & Performance',
              icon: LucideIcons.wheat,
              children: [
                Row(
                  children: [
                    Expanded(child: InputCard(label: 'Birds Alive', placeholder: '#', controller: _quailsCtrl, action: TextInputAction.next, errorText: _quailsError)),
                    const SizedBox(width: 12),
                    Expanded(child: InputCard(label: 'Feed Refusal (g)', placeholder: '0.0', controller: _feedRefusalCtrl, action: TextInputAction.done, errorText: _feedRefusalError)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.info, size: 16, color: theme.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'System set feed given at ${_feedGivenNum.toStringAsFixed(0)}g based on bird count.',
                          style: TextStyle(
                            fontSize: 12, 
                            color: theme.textTheme.bodySmall?.color
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            Text(
              'Calculated Insights', 
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold, 
                color: theme.textTheme.displaySmall?.color
              )
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                StatBox(label: 'HDEP %', value: hdep.toStringAsFixed(1), suffix: '%', color: const Color(0xFF10B981)),
                const SizedBox(width: 12),
                StatBox(label: 'FCR', value: fcr.toStringAsFixed(2), color: theme.primaryColor),
                const SizedBox(width: 12),
                StatBox(label: 'VFI', value: vfi.toStringAsFixed(1), suffix: 'g', color: theme.colorScheme.secondary),
              ],
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Save Daily Log',
              onPressed: _saveLog,
              icon: LucideIcons.checkCircle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, {required String title, required IconData icon, required List<Widget> children}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        boxShadow: theme.brightness == Brightness.dark ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.primaryColor),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: theme.textTheme.bodySmall?.color,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
