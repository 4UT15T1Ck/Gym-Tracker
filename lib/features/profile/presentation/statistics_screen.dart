import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/common/widgets/animated_metric_bar.dart';
import 'package:gym_tracker/common/widgets/motion_tokens.dart';
import 'package:gym_tracker/features/profile/bloc/statistics_cubit.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});
  static const _bgColor = Color(0xFF080A0F);
  static const _cardColor = Color(0xFF151A23);
  static const _mutedText = Color(0xFF8C94A5);
  static const _accent = Color(0xFF4A8DFF);
  static const _accentTextDark = Color(0xFF0E335A);
  static const _outline = Color(0xFF283041);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StatisticsCubit, StatisticsState>(
      builder: (context, state) {
        final theme = Theme.of(context);
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
                        'Statistics',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (state.isLoading) const LinearProgressIndicator(),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Reveal(
                      delayMs: 20,
                      child: _Counter(
                        label: 'Workouts',
                        value: '${state.totalWorkouts}',
                      ),
                    ),
                    _Reveal(
                      delayMs: 50,
                      child: _Counter(
                        label: 'Sets',
                        value: '${state.totalSets}',
                      ),
                    ),
                    _Reveal(
                      delayMs: 80,
                      child: _Counter(
                        label: 'Reps',
                        value: '${state.totalReps}',
                      ),
                    ),
                    _Reveal(
                      delayMs: 110,
                      child: _Counter(
                        label: 'Volume',
                        value: '${state.totalVolume.toStringAsFixed(0)} kg',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Volume Over Time',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _outline),
                  ),
                  child: _SimpleBars(values: state.volumeHistory),
                ),
                const SizedBox(height: 24),
                Text(
                  'Personal Records',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (state.prs.isEmpty)
                  Text(
                    'No PRs yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _mutedText,
                    ),
                  ),
                ...state.prs.indexed.map(
                  (entry) => _Reveal(
                    delayMs: 140 + (entry.$1 * 20),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _outline),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.emoji_events,
                          color: _accentTextDark,
                        ),
                        title: Text(
                          entry.$2,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
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
}

class _Counter extends StatelessWidget {
  final String label;
  final String value;

  const _Counter({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Container(
        decoration: BoxDecoration(
          color: StatisticsScreen._cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: StatisticsScreen._outline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: StatisticsScreen._mutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimpleBars extends StatelessWidget {
  final List<({DateTime date, double volume})> values;

  const _SimpleBars({required this.values});

  @override
  Widget build(BuildContext context) {
    final maxValue = values.fold<double>(
      1,
      (max, value) => value.volume > max ? value.volume : max,
    );
    return SizedBox(
      height: 210,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values.take(30).map((value) {
          final label = '${value.date.month}/${value.date.day}';
          return Expanded(
            child: InkWell(
              onTap: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(label),
                  content: Text(
                    'Volume: ${value.volume.toStringAsFixed(0)} kg',
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${value.volume.toStringAsFixed(0)}kg',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white),
                    ),
                    AnimatedMetricBar(
                      value: value.volume,
                      maxValue: maxValue,
                      minHeight: 8,
                      maxHeight: 138,
                      color: StatisticsScreen._accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: StatisticsScreen._mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Reveal extends StatelessWidget {
  final Widget child;
  final int delayMs;

  const _Reveal({required this.child, required this.delayMs});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: MotionTokens.resolve(
        context,
        Duration(milliseconds: MotionTokens.base.inMilliseconds + delayMs),
      ),
      curve: MotionTokens.standardCurve,
      builder: (context, value, item) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 8),
          child: item,
        ),
      ),
      child: child,
    );
  }
}
