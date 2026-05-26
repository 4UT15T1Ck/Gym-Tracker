import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/common/routes/routes.dart';
import 'package:gym_tracker/common/utils/date_formatters.dart';
import 'package:gym_tracker/common/utils/muscle_group_utils.dart';
import 'package:gym_tracker/common/widgets/app_haptics.dart';
import 'package:gym_tracker/common/widgets/motion_tokens.dart';
import 'package:gym_tracker/common/widgets/tap_scale.dart';
import 'package:gym_tracker/core/repositories/repository_models.dart';
import 'package:gym_tracker/core/services/dashboard_service.dart';
import 'package:gym_tracker/features/home/bloc/home_dashboard_cubit.dart';
import 'package:gym_tracker/features/shell/bloc/shell_active_workout_cubit.dart';

class HomeDashboardScreen extends StatelessWidget {
  static const _bgColor = Color(0xFF080A0F);
  static const _cardColor = Color(0xFF11141B);
  static const _cardStroke = Color(0xFF1C2230);
  static const _accent = Color(0xFF2A7CFF);
  static const _mutedText = Color(0xFF8C94A5);
  static const _subtleText = Color(0xFF687287);
  static const _radius = 16.0;
  static const _sectionSpacing = 22.0;

  final VoidCallback onOpenWorkoutTab;

  const HomeDashboardScreen({super.key, required this.onOpenWorkoutTab});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeDashboardCubit, HomeDashboardState>(
      builder: (context, state) {
        final summary = state.summary;
        final mediaQuery = MediaQuery.of(context);
        final bottomInset = mediaQuery.padding.bottom;
        final listBottomPadding = bottomInset + 16.0;

        return Container(
          color: _bgColor,
          child: SafeArea(
            bottom: false,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 14, 16, listBottomPadding),
              children: [
                _HeaderSection(username: state.username),
                const SizedBox(height: _sectionSpacing),
                _AnimatedSection(
                  delayMs: 20,
                  child: _QuickStartSection(
                    suggestedRoutineName: summary?.suggestedRoutine?.name,
                    suggestedRoutineReason: summary?.suggestedRoutine?.reason,
                    onStartEmptyWorkout: () async {
                      final id = await context
                          .read<HomeDashboardCubit>()
                          .startEmptyWorkout();
                      if (context.mounted) {
                        context.read<ShellActiveWorkoutCubit>().refreshNow();
                      }
                      if (!context.mounted) return;
                      Navigator.of(context).pushNamed(
                        Routes.activeWorkout,
                        arguments: ActiveWorkoutRouteArgs(workoutId: id),
                      );
                    },
                    onPickRoutine: summary?.suggestedRoutine == null
                        ? onOpenWorkoutTab
                        : () async {
                            final id = await context
                                .read<HomeDashboardCubit>()
                                .startSuggestedRoutine();
                            if (context.mounted) {
                              context
                                  .read<ShellActiveWorkoutCubit>()
                                  .refreshNow();
                            }
                            if (!context.mounted || id == null) return;
                            Navigator.of(context).pushNamed(
                              Routes.activeWorkout,
                              arguments: ActiveWorkoutRouteArgs(workoutId: id),
                            );
                          },
                  ),
                ),
                const SizedBox(height: _sectionSpacing),
                _AnimatedSection(
                  delayMs: 70,
                  child: _WeekCard(
                    days: summary?.thisWeekTrainedDays ?? const [],
                    streak: summary?.streakDays ?? 0,
                  ),
                ),
                const SizedBox(height: _sectionSpacing),
                _AnimatedSection(
                  delayMs: 120,
                  child: _LastWorkoutCard(
                    workout: summary?.lastWorkout,
                    tags: summary?.lastWorkoutMuscleTags ?? const [],
                  ),
                ),
                const SizedBox(height: _sectionSpacing),
                _AnimatedSection(
                  delayMs: 170,
                  child: _RecentPrCard(
                    prs: summary?.recentPrs ?? const <RecentPrSummary>[],
                  ),
                ),
                const SizedBox(height: _sectionSpacing),
                _AnimatedSection(
                  delayMs: 220,
                  child: _RecoveryCard(
                    items: summary?.recovery ?? const <MuscleRecoverySummary>[],
                  ),
                ),
                AnimatedSwitcher(
                  duration: MotionTokens.resolve(context, MotionTokens.base),
                  switchInCurve: MotionTokens.standardCurve,
                  switchOutCurve: MotionTokens.standardCurve,
                  child: state.isLoading
                      ? const Padding(
                          key: ValueKey('home-loading'),
                          padding: EdgeInsets.only(top: 16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(999)),
                            child: LinearProgressIndicator(minHeight: 3),
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('home-loading-empty')),
                ),
                AnimatedSwitcher(
                  duration: MotionTokens.resolve(context, MotionTokens.base),
                  switchInCurve: MotionTokens.standardCurve,
                  switchOutCurve: MotionTokens.standardCurve,
                  child: state.errorMessage == null
                      ? const SizedBox.shrink(key: ValueKey('home-error-empty'))
                      : Padding(
                          key: const ValueKey('home-error-note'),
                          padding: const EdgeInsets.only(top: 12),
                          child: _ErrorNote(message: state.errorMessage!),
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

class _AnimatedSection extends StatelessWidget {
  final int delayMs;
  final Widget child;

  const _AnimatedSection({required this.delayMs, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, section) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 10),
          child: section,
        ),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final String username;

  const _HeaderSection({required this.username});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good morning, $username',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _fullDateLabel(DateTime.now()),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: HomeDashboardScreen._mutedText,
          ),
        ),
      ],
    );
  }

  String _fullDateLabel(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}

class _QuickStartSection extends StatelessWidget {
  final VoidCallback onStartEmptyWorkout;
  final VoidCallback onPickRoutine;
  final String? suggestedRoutineName;
  final String? suggestedRoutineReason;

  const _QuickStartSection({
    required this.onStartEmptyWorkout,
    required this.onPickRoutine,
    required this.suggestedRoutineName,
    required this.suggestedRoutineReason,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Quick Start'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 46,
                child: TapScale(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: HomeDashboardScreen._accent),
                      foregroundColor: HomeDashboardScreen._accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      await AppHaptics.selection(context);
                      onStartEmptyWorkout();
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Start Empty Workout'),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 46,
                child: TapScale(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0E295A),
                      foregroundColor: const Color(0xFF66A2FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      await AppHaptics.selection(context);
                      onPickRoutine();
                    },
                    icon: const Icon(Icons.view_list, size: 16),
                    label: Text(
                      suggestedRoutineName ?? 'Pick a Routine',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (suggestedRoutineReason != null) ...[
          const SizedBox(height: 8),
          Text(
            suggestedRoutineReason!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: HomeDashboardScreen._subtleText,
            ),
          ),
        ],
      ],
    );
  }
}

class _WeekCard extends StatelessWidget {
  final List<bool> days;
  final int streak;

  const _WeekCard({required this.days, required this.streak});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final labels = List.generate(
      7,
      (index) => DateFormatters.weekday(DateTime(2024, 1, index + 1)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('This Week'),
        const SizedBox(height: 10),
        _DashCard(
          child: AnimatedSwitcher(
            duration: MotionTokens.resolve(context, MotionTokens.base),
            switchInCurve: MotionTokens.standardCurve,
            switchOutCurve: MotionTokens.standardCurve,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Column(
              key: ValueKey<String>('week-${days.join()}-$streak'),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (index) {
                    final trained = index < days.length && days[index];
                    final isToday = now.weekday - 1 == index;
                    return Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: trained
                                  ? const Color(0xFFE8E9EC)
                                  : Colors.transparent,
                              border: Border.all(
                                color: trained
                                    ? const Color(0xFFE8E9EC)
                                    : (isToday
                                          ? HomeDashboardScreen._accent
                                          : const Color(0xFF2A3140)),
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.circle,
                                size: 8,
                                color: trained
                                    ? const Color(0xFF11141B)
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            labels[index],
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: HomeDashboardScreen._mutedText,
                                  fontSize: 11,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    text: '$streak',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                    children: [
                      TextSpan(
                        text: ' day streak',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: HomeDashboardScreen._mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LastWorkoutCard extends StatelessWidget {
  final WorkoutSummary? workout;
  final List<String> tags;

  const _LastWorkoutCard({required this.workout, required this.tags});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Last Workout'),
        const SizedBox(height: 10),
        _DashCard(
          child: workout == null
              ? Text(
                  'Log your first workout to see stats.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: HomeDashboardScreen._mutedText,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout!.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_relativeDay(workout!.startTime)} • ${DateFormatters.duration(workout!.startTime, workout!.endTime)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: HomeDashboardScreen._mutedText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: tags.isEmpty
                          ? [_TagChip(label: 'No tags')]
                          : tags.map((tag) => _TagChip(label: tag)).toList(),
                    ),
                    const SizedBox(height: 14),
                    RichText(
                      text: TextSpan(
                        text: 'Total Volume: ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: HomeDashboardScreen._mutedText,
                        ),
                        children: [
                          TextSpan(
                            text: '${workout!.volume.toStringAsFixed(0)} kg',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  String _relativeDay(DateTime start) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(start.year, start.month, start.day);
    final deltaDays = today.difference(target).inDays;
    if (deltaDays <= 0) return 'Today';
    if (deltaDays == 1) return 'Yesterday';
    return DateFormatters.shortDate(start);
  }
}

class _RecentPrCard extends StatelessWidget {
  final List<RecentPrSummary> prs;

  const _RecentPrCard({required this.prs});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Recent PRs'),
        const SizedBox(height: 10),
        _DashCard(
          child: AnimatedSwitcher(
            duration: MotionTokens.resolve(context, MotionTokens.base),
            switchInCurve: MotionTokens.standardCurve,
            switchOutCurve: MotionTokens.standardCurve,
            child: prs.isEmpty
                ? Text(
                    'No PRs yet.',
                    key: const ValueKey('prs-empty'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: HomeDashboardScreen._mutedText,
                    ),
                  )
                : Column(
                    key: ValueKey<String>(
                      'prs-${prs.map((e) => '${e.exerciseName}-${e.weight}-${e.reps}').join('|')}',
                    ),
                    children: List.generate(prs.length, (i) {
                      final pr = prs[i];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: i == prs.length - 1 ? 0 : 10,
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 20,
                              width: 20,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFF14D99A),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'PR',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: const Color(0xFF03261A),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 9,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                pr.exerciseName,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${pr.weight.toStringAsFixed(0)} kg',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              pr.reps != null ? '${pr.reps} reps' : '— reps',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: HomeDashboardScreen._subtleText,
                                  ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ),
      ],
    );
  }
}

class _RecoveryCard extends StatelessWidget {
  final List<MuscleRecoverySummary> items;

  const _RecoveryCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final source = items.take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Muscle Recovery'),
        const SizedBox(height: 10),
        _DashCard(
          child: AnimatedSwitcher(
            duration: MotionTokens.resolve(context, MotionTokens.base),
            switchInCurve: MotionTokens.standardCurve,
            switchOutCurve: MotionTokens.standardCurve,
            child: source.isEmpty
                ? Text(
                    'No recent recovery data.',
                    key: const ValueKey('recovery-empty'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: HomeDashboardScreen._mutedText,
                    ),
                  )
                : GridView.builder(
                    key: ValueKey<String>(
                      'recovery-${source.map((e) => '${e.group}-${e.status.name}-${e.sinceLabel}').join('|')}',
                    ),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: source.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.55,
                    ),
                    itemBuilder: (context, index) {
                      final item = source[index];
                      return Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _recoveryColor(item.status),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.group,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _compactSince(item.sinceLabel),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: HomeDashboardScreen._mutedText,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  String _compactSince(MuscleRecoverySummary item) {
    final lastTrainedAt = item.lastTrainedAt;
    if (lastTrainedAt == null) {
      return 'No history';
    }
    return _compactRelativeTime(lastTrainedAt);
  }

  String _compactRelativeTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final days = today.difference(target).inDays;

    if (days <= 0) {
      return 'Today';
    }
    if (days == 1) {
      return '1d ago';
    }
    if (days < 7) {
      return '${days}d ago';
    }

    final weeks = days ~/ 7;
    if (weeks == 1) {
      return '1w ago';
    }
    if (weeks < 5) {
      return '${weeks}w ago';
    }

    final months = days ~/ 30;
    if (months == 1) {
      return '1mo ago';
    }
    if (months < 12) {
      return '${months}mo ago';
    }

    final years = days ~/ 365;
    if (years == 1) {
      return '1y ago';
    }
    return '${years}y ago';
  }
}

class _ErrorNote extends StatelessWidget {
  final String message;

  const _ErrorNote({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1016),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF5A1E2B)),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: const Color(0xFFFFC6D1)),
      ),
    );
  }
}

class _DashCard extends StatelessWidget {
  final Widget child;

  const _DashCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HomeDashboardScreen._cardColor,
        borderRadius: BorderRadius.circular(HomeDashboardScreen._radius),
        border: Border.all(color: HomeDashboardScreen._cardStroke),
      ),
      child: child,
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF262C37),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF363E4C)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

Color _recoveryColor(RecoveryStatus status) {
  switch (status) {
    case RecoveryStatus.sore:
      return const Color(0xFFF55A5A);
    case RecoveryStatus.recovering:
      return const Color(0xFFF4AD36);
    case RecoveryStatus.ready:
      return const Color(0xFF14D99A);
    case RecoveryStatus.fresh:
      return const Color(0xFF39C9FF);
  }
}
