import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/common/utils/date_formatters.dart';
import 'package:gym_tracker/common/widgets/animated_metric_bar.dart';
import 'package:gym_tracker/common/widgets/app_haptics.dart';
import 'package:gym_tracker/common/widgets/motion_tokens.dart';
import 'package:gym_tracker/features/profile/bloc/measures_cubit.dart';

class MeasuresScreen extends StatefulWidget {
  const MeasuresScreen({super.key});

  @override
  State<MeasuresScreen> createState() => _MeasuresScreenState();
}

class _MeasuresScreenState extends State<MeasuresScreen> {
  static const _bgColor = Color(0xFF080A0F);
  static const _cardColor = Color(0xFF151A23);
  static const _mutedText = Color(0xFF8C94A5);
  static const _accent = Color(0xFF4A8DFF);
  static const _outline = Color(0xFF283041);

  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final Set<String> _removingIds = <String>{};

  @override
  void dispose() {
    _weightController.dispose();
    _bodyFatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MeasuresCubit, MeasuresState>(
      builder: (context, state) {
        final theme = Theme.of(context);
        final maxValue = state.entries
            .map((e) => e.weight ?? 0)
            .fold<double>(1, (max, w) => w > max ? w : max);
        return Scaffold(
          backgroundColor: _bgColor,
          body: SafeArea(
            bottom: false,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                14,
                16,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Measures',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _outline),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _weightController,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                        ),
                        decoration: _inputDecoration('Weight (kg)', theme),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _bodyFatController,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                        ),
                        decoration: _inputDecoration('Body fat %', theme),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () async {
                            await context.read<MeasuresCubit>().add(
                              weight: double.tryParse(_weightController.text),
                              bodyFat: double.tryParse(_bodyFatController.text),
                            );
                            _weightController.clear();
                            _bodyFatController.clear();
                            if (!context.mounted) return;
                            await AppHaptics.success(context);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text('Entry added'),
                                  duration: Duration(milliseconds: 1000),
                                ),
                              );
                          },
                          child: const Text('Add Entry'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Weight History',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _outline),
                  ),
                  child: SizedBox(
                    height: 132,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: state.entries.reversed.take(30).map((entry) {
                        final weight = entry.weight ?? 0;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: AnimatedMetricBar(
                              value: weight <= 0 ? 0 : weight,
                              maxValue: maxValue <= 0 ? 1 : maxValue,
                              minHeight: 6,
                              maxHeight: 106,
                              color: _accent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (state.entries.isEmpty)
                  Text(
                    'No body metrics logged yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _mutedText,
                    ),
                  ),
                ...state.entries.map(
                  (entry) => AnimatedOpacity(
                    key: ValueKey<String>(entry.id),
                    opacity: _removingIds.contains(entry.id) ? 0 : 1,
                    duration: MotionTokens.resolve(context, MotionTokens.fast),
                    curve: MotionTokens.standardCurve,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _outline),
                      ),
                      child: ListTile(
                        title: Text(
                          DateFormatters.shortDate(entry.date),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Weight: ${entry.weight?.toStringAsFixed(1) ?? '-'} · Body fat: ${entry.bodyFatPercent?.toStringAsFixed(1) ?? '-'}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _mutedText,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _deleteEntry(entry.id),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, ThemeData theme) {
    return InputDecoration(
      labelText: label,
      labelStyle: theme.textTheme.bodyMedium?.copyWith(color: _mutedText),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accent, width: 1.5),
      ),
      filled: true,
      fillColor: const Color(0xFF0F141D),
    );
  }

  Future<void> _deleteEntry(String id) async {
    if (_removingIds.contains(id)) return;
    final cubit = context.read<MeasuresCubit>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _removingIds.add(id));
    await Future<void>.delayed(
      MotionTokens.resolve(context, MotionTokens.fast),
    );
    if (!mounted) return;
    await cubit.delete(id);
    if (!mounted) return;
    _removingIds.remove(id);
    await AppHaptics.selection();
    if (!mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Entry deleted'),
          duration: Duration(milliseconds: 1000),
        ),
      );
  }
}
