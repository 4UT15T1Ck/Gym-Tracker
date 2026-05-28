import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/common/routes/routes.dart';
import 'package:gym_tracker/common/widgets/animated_metric_bar.dart';
import 'package:gym_tracker/common/widgets/app_haptics.dart';
import 'package:gym_tracker/common/widgets/motion_tokens.dart';
import 'package:gym_tracker/common/widgets/tap_scale.dart';
import 'package:gym_tracker/features/profile/bloc/profile_cubit.dart';

class ProfileHomeScreen extends StatefulWidget {
  const ProfileHomeScreen({super.key});

  @override
  State<ProfileHomeScreen> createState() => _ProfileHomeScreenState();
}

class _ProfileHomeScreenState extends State<ProfileHomeScreen> {
  static const _bgColor = Color(0xFF080A0F);
  static const _cardColor = Color(0xFF151A23);
  static const _mutedText = Color(0xFF8C94A5);
  static const _accent = Color(0xFF4A8DFF);
  static const _accentTextDark = Color(0xFF0E335A);
  static const _outline = Color(0xFF283041);

  int _avatarPulseSeed = 0;

  void _pulseAvatar() {
    setState(() => _avatarPulseSeed++);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final theme = Theme.of(context);
        return ColoredBox(
          color: _bgColor,
          child: SafeArea(
            bottom: false,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                14,
                16,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              children: [
                Text(
                  'PROFILE',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _mutedText,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey<int>(_avatarPulseSeed),
                    tween: Tween(begin: 0.93, end: 1),
                    duration: MotionTokens.resolve(
                      context,
                      MotionTokens.emphasis,
                    ),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) =>
                        Transform.scale(scale: value, child: child),
                    child: CircleAvatar(
                      radius: 58,
                      backgroundColor: _accent,
                      child: Text(
                        state.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 28,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.username,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.edit, color: _mutedText, size: 18),
                        onPressed: () async {
                          final controller = TextEditingController(
                            text: state.username,
                          );
                          final name = await showDialog<String>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Profile name'),
                              content: TextField(
                                controller: controller,
                                autofocus: true,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(controller.text),
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          );
                          if (!context.mounted || name == null) return;
                          await context.read<ProfileCubit>().updateName(name);
                          if (!context.mounted) return;
                          _pulseAvatar();
                          await AppHaptics.success(context);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              const SnackBar(
                                content: Text('Profile updated'),
                                duration: Duration(milliseconds: 1100),
                              ),
                            );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Center(
                  child: Text(
                    '${state.totalWorkouts} workouts',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _mutedText,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'DASHBOARD',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: _mutedText,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.65,
                  children: const [
                    _DashboardCard(
                      icon: Icons.bar_chart,
                      title: 'Statistics',
                      subtitle: 'Volume, reps, PRs',
                      route: Routes.statistics,
                    ),
                    _DashboardCard(
                      icon: Icons.accessibility_new,
                      title: 'Muscle Map',
                      subtitle: 'Training balance',
                      route: Routes.muscleMap,
                    ),
                    _DashboardCard(
                      icon: Icons.straighten,
                      title: 'Measures',
                      subtitle: 'Body metrics',
                      route: Routes.measures,
                    ),
                    _DashboardCard(
                      icon: Icons.calendar_month,
                      title: 'Calendar',
                      subtitle: 'Workout history',
                      route: Routes.workoutHistory,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'THIS WEEK',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: _mutedText,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                _MainChart(state: state),
                if (state.isLoading) const LinearProgressIndicator(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MainChart extends StatelessWidget {
  final ProfileState state;

  const _MainChart({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = state.chartBars.fold<double>(0, (sum, b) => sum + b.value);
    final unit = _unitLabel(state.chartMetric);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: _ProfileHomeScreenState._cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _ProfileHomeScreenState._outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                total.toStringAsFixed(1),
                style: theme.textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  unit,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: _ProfileHomeScreenState._mutedText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _LabeledBarChart(bars: state.chartBars, metric: state.chartMetric),
        ],
      ),
    );
  }

  String _unitLabel(ProfileChartMetric metric) {
    switch (metric) {
      case ProfileChartMetric.duration:
        return 'hrs';
      case ProfileChartMetric.volume:
        return 'kg';
      case ProfileChartMetric.reps:
        return 'reps';
    }
  }
}

class _LabeledBarChart extends StatelessWidget {
  final List<ProfileChartBar> bars;
  final ProfileChartMetric metric;

  const _LabeledBarChart({required this.bars, required this.metric});

  @override
  Widget build(BuildContext context) {
    final maxValue = bars.fold<double>(
      1,
      (max, bar) => bar.value > max ? bar.value : max,
    );
    return SizedBox(
      height: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: bars.map((bar) {
          return Expanded(
            child: InkWell(
              onTap: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(bar.label),
                  content: Text(
                    '${_metricLabel(metric)}: ${_valueLabel(metric, bar.value)}',
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _valueLabel(metric, bar.value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white),
                    ),
                    AnimatedMetricBar(
                      value: bar.value,
                      maxValue: maxValue,
                      minHeight: 24,
                      maxHeight: 144,
                      color: _ProfileHomeScreenState._accent,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bar.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _ProfileHomeScreenState._mutedText,
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

  String _metricLabel(ProfileChartMetric metric) {
    switch (metric) {
      case ProfileChartMetric.duration:
        return 'Duration';
      case ProfileChartMetric.volume:
        return 'Volume';
      case ProfileChartMetric.reps:
        return 'Reps';
    }
  }

  String _valueLabel(ProfileChartMetric metric, double value) {
    switch (metric) {
      case ProfileChartMetric.duration:
        return '${value.toStringAsFixed(0)}m';
      case ProfileChartMetric.volume:
        return '${value.toStringAsFixed(0)}kg';
      case ProfileChartMetric.reps:
        return value.toStringAsFixed(0);
    }
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      child: Container(
        decoration: BoxDecoration(
          color: _ProfileHomeScreenState._cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _ProfileHomeScreenState._outline),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).pushNamed(route),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Icon(icon, color: _ProfileHomeScreenState._accentTextDark),
                const Spacer(),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _ProfileHomeScreenState._mutedText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
