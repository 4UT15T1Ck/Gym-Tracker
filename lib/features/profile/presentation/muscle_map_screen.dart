import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/common/widgets/motion_tokens.dart';
import 'package:gym_tracker/features/profile/bloc/muscle_map_cubit.dart';

class MuscleMapScreen extends StatelessWidget {
  const MuscleMapScreen({super.key});
  static const _bgColor = Color(0xFF080A0F);
  static const _cardColor = Color(0xFF151A23);
  static const _mutedText = Color(0xFF8C94A5);
  static const _accent = Color(0xFF4A8DFF);
  static const _outline = Color(0xFF283041);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MuscleMapCubit, MuscleMapState>(
      builder: (context, state) {
        final theme = Theme.of(context);
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
                        'Muscle Map',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width - 32,
                    ),
                    child: SegmentedButton<int>(
                      style: SegmentedButton.styleFrom(
                        foregroundColor: _mutedText,
                        selectedForegroundColor: Colors.white,
                        selectedBackgroundColor: _accent,
                        side: const BorderSide(color: _outline),
                      ),
                      segments: const [
                        ButtonSegment(value: 7, label: Text('This Week')),
                        ButtonSegment(value: 28, label: Text('Last 4 Wks')),
                        ButtonSegment(value: 84, label: Text('Last 12 Wks')),
                      ],
                      selected: {state.days},
                      onSelectionChanged: (value) => context
                          .read<MuscleMapCubit>()
                          .load(days: value.first),
                    ),
                  ),
                ),
                if (state.isLoading)
                  const LinearProgressIndicator(minHeight: 2),
                const SizedBox(height: 16),

                // ── All-muscles heat-map grid ──
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    border: Border.all(color: _outline),
                    borderRadius: BorderRadius.circular(14),
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
                        key: ValueKey<String>(
                          'muscle-chip-${item.key}-${state.days}',
                        ),
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
                          side: const BorderSide(color: Colors.transparent),
                          label: Text(
                            '${item.key} ${_countLabel(count)}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          onPressed: () =>
                              _showDetail(context, item.key, count),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Per-muscle progress bars ──
                Text(
                  'Muscle Breakdown',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ...sortedEntries.map((entry) {
                  final count = entry.value;
                  final ratio = maxCount > 0
                      ? (count / maxCount).clamp(0.0, 1.0)
                      : 0.0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _outline),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: _colorForCount(count),
                          radius: 8,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: ratio,
                                minHeight: 7,
                                borderRadius: BorderRadius.circular(999),
                                color: _accent,
                                backgroundColor: const Color(0xFF0F141D),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${_countLabel(count)} sets',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _mutedText,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
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
