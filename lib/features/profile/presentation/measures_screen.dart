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
        return Scaffold(
          appBar: AppBar(title: const Text('Measures')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _weightController,
                decoration: const InputDecoration(labelText: 'Weight'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _bodyFatController,
                decoration: const InputDecoration(labelText: 'Body fat %'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              FilledButton(
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
              const SizedBox(height: 24),
              Text(
                'Weight History',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(
                height: 120,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: state.entries.reversed.take(30).map((entry) {
                    final weight = entry.weight ?? 0;
                    final maxValue = state.entries
                        .map((e) => e.weight ?? 0)
                        .fold<double>(1, (max, w) => w > max ? w : max);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: AnimatedMetricBar(
                          value: weight <= 0 ? 0 : weight,
                          maxValue: maxValue <= 0 ? 1 : maxValue,
                          minHeight: 4,
                          maxHeight: 100,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (state.entries.isEmpty)
                const Text('No body metrics logged yet.'),
              ...state.entries.map(
                (entry) => AnimatedOpacity(
                  key: ValueKey<String>(entry.id),
                  opacity: _removingIds.contains(entry.id) ? 0 : 1,
                  duration: MotionTokens.resolve(context, MotionTokens.fast),
                  curve: MotionTokens.standardCurve,
                  child: ListTile(
                    title: Text(DateFormatters.shortDate(entry.date)),
                    subtitle: Text(
                      'Weight: ${entry.weight?.toStringAsFixed(1) ?? '-'} · Body fat: ${entry.bodyFatPercent?.toStringAsFixed(1) ?? '-'}%',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteEntry(entry.id),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
