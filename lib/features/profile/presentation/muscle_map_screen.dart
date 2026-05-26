import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/common/widgets/motion_tokens.dart';
import 'package:gym_tracker/features/profile/bloc/muscle_map_cubit.dart';

class MuscleMapScreen extends StatelessWidget {
  const MuscleMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MuscleMapCubit, MuscleMapState>(
      builder: (context, state) {
        final maxCount = state.muscleCounts.values.fold<double>(
          0,
          (prev, v) => v > prev ? v : prev,
        );

        // Sort muscles: highest count first, then alphabetically for ties
        final sortedEntries = state.muscleCounts.entries.toList()
          ..sort((a, b) {
            final cmp = b.value.compareTo(a.value);
            return cmp != 0 ? cmp : a.key.compareTo(b.key);
          });

        return Scaffold(
          appBar: AppBar(title: const Text('Muscle Map')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 7, label: Text('This Week')),
                  ButtonSegment(value: 28, label: Text('Last 4 Wks')),
                  ButtonSegment(value: 84, label: Text('Last 12 Wks')),
                ],
                selected: {state.days},
                onSelectionChanged: (value) =>
                    context.read<MuscleMapCubit>().load(days: value.first),
              ),
              if (state.isLoading) const LinearProgressIndicator(),
              const SizedBox(height: 16),

              // ── All-muscles heat-map grid ──
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: sortedEntries.indexed.map((entry) {
                    final index = entry.$1;
                    final item = entry.$2;
                    final count = item.value;
                    return TweenAnimationBuilder<double>(
                      key: ValueKey<String>('muscle-chip-${item.key}-${state.days}'),
                      tween: Tween(begin: 0, end: 1),
                      duration: MotionTokens.resolve(
                        context,
                        Duration(milliseconds: 180 + (index * 18)),
                      ),
                      curve: MotionTokens.standardCurve,
                      builder: (context, value, chip) => Opacity(
                        opacity: value,
                        child: Transform.scale(
                          scale: 0.95 + (value * 0.05),
                          child: chip,
                        ),
                      ),
                      child: ActionChip(
                        backgroundColor: _colorForCount(count),
                        label: Text(
                          '${item.key} ${_countLabel(count)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        onPressed: () => _showDetail(context, item.key, count),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // ── Per-muscle progress bars ──
              Text(
                'Muscle Breakdown',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ...sortedEntries.map((entry) {
                final count = entry.value;
                final ratio =
                    maxCount > 0 ? (count / maxCount).clamp(0.0, 1.0) : 0.0;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _colorForCount(count),
                    radius: 8,
                  ),
                  title: Text(entry.key),
                  subtitle: LinearProgressIndicator(value: ratio),
                  trailing: Text('${_countLabel(count)} sets'),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ── helpers ──

  void _showDetail(BuildContext context, String muscle, double count) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(muscle),
        content: Text(
          '${_countLabel(count)} weighted sets in the selected period.',
        ),
      ),
    );
  }

  Color _colorForCount(double count) {
    if (count >= 9) return Colors.red.shade700;
    if (count >= 4) return Colors.orange.shade700;
    if (count >= 1) return Colors.lightGreen.shade700;
    return Colors.grey.shade700;
  }

  String _countLabel(double count) {
    if (count == count.roundToDouble()) return count.toStringAsFixed(0);
    return count.toStringAsFixed(1);
  }
}
