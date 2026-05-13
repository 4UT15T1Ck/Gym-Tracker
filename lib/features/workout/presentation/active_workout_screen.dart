import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/common/routes/routes.dart';
import 'package:gym_tracker/common/utils/date_formatters.dart';
import 'package:gym_tracker/core/enums/set_type_enum.dart';
import 'package:gym_tracker/core/models/exercise_model.dart';
import 'package:gym_tracker/core/models/workout_set_model.dart';
import 'package:gym_tracker/core/repositories/repository_models.dart';
import 'package:gym_tracker/features/home/bloc/home_dashboard_cubit.dart';
import 'package:gym_tracker/features/profile/bloc/profile_cubit.dart';
import 'package:gym_tracker/features/shell/bloc/shell_active_workout_cubit.dart';
import 'package:gym_tracker/features/workout/bloc/active_workout_cubit.dart';
import 'package:gym_tracker/features/workout/bloc/rest_timer_bloc.dart';
import 'package:gym_tracker/features/workout/bloc/workout_home_cubit.dart';

class ActiveWorkoutScreen extends StatelessWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ActiveWorkoutCubit, ActiveWorkoutState>(
      listenWhen: (previous, current) => previous.didFinish != current.didFinish,
      listener: (context, state) {
        if (state.didFinish) {
          context.read<ShellActiveWorkoutCubit>().refreshNow();
          context.read<HomeDashboardCubit>().load();
          context.read<WorkoutHomeCubit>().load();
          context.read<ProfileCubit>().load();
          Navigator.of(context).pop(true);
        }
      },
      child: BlocBuilder<ActiveWorkoutCubit, ActiveWorkoutState>(
        builder: (context, state) {
          final detail = state.detail;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Log Workout'),
              actions: [
                TextButton(
                  onPressed: state.isFinishing
                      ? null
                      : () async {
                          final shouldFinish = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Finish workout?'),
                              content: const Text('Completed sets will be saved to history.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                                FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Finish')),
                              ],
                            ),
                          );
                          if (shouldFinish == true && context.mounted) {
                            FocusManager.instance.primaryFocus?.unfocus();
                            await Future<void>.delayed(const Duration(milliseconds: 120));
                            if (context.mounted) {
                              await context.read<ActiveWorkoutCubit>().finish();
                            }
                          }
                        },
                  child: const Text('Finish'),
                ),
              ],
            ),
            body: detail == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      _WorkoutTimersBanner(
                        startTime: detail.workout.startTime,
                        volumeKg: detail.workout.volume,
                        completedSets: state.completedSets,
                      ),
                      const SizedBox(height: 12),
                      Text(detail.workout.name, style: Theme.of(context).textTheme.titleLarge),
                      if (detail.workout.notes?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(detail.workout.notes!.trim()),
                      ],
                      const SizedBox(height: 12),
                      if (detail.exercises.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('No exercises yet. Add one to start logging.')),
                        ),
                      ...detail.exercises.indexed.map(
                        (entry) => _ExerciseBlock(
                          detail: entry.$2,
                          state: state,
                          index: entry.$1,
                          exerciseCount: detail.exercises.length,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () async {
                          final selected = await Navigator.of(context).pushNamed<List<Exercise>>(
                            Routes.addExercise,
                            arguments: const AddExerciseRouteArgs(),
                          );
                          if (!context.mounted || selected == null) return;
                          context.read<ActiveWorkoutCubit>().addExercises(selected);
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Exercise'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final shouldDiscard = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Discard workout?'),
                              content: const Text('This will discard the current workout and nothing will be saved.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Keep')),
                                FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Discard')),
                              ],
                            ),
                          );
                          if (shouldDiscard == true && context.mounted) {
                            await context.read<ActiveWorkoutCubit>().cancel();
                            if (context.mounted) {
                              context.read<ShellActiveWorkoutCubit>().refreshNow();
                              context.read<HomeDashboardCubit>().load();
                              context.read<WorkoutHomeCubit>().load();
                              context.read<ProfileCubit>().load();
                            }
                            if (context.mounted) {
                              Navigator.of(context).pop(false);
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Discard Workout'),
                      ),
                      BlocBuilder<RestTimerBloc, RestTimerState>(
                        builder: (context, rt) {
                          final pad = rt is RestTimerRunning ? 84.0 : 20.0;
                          return SizedBox(height: pad);
                        },
                      ),
                    ],
                  ),
            bottomSheet: BlocBuilder<RestTimerBloc, RestTimerState>(
              builder: (context, restState) {
                if (restState is! RestTimerRunning) return const SizedBox.shrink();
                return _RestTimerBottomBar(secondsRemaining: restState.secondsRemaining);
              },
            ),
          );
        },
      ),
    );
  }
}

class _RestTimerBottomBar extends StatelessWidget {
  final int secondsRemaining;

  const _RestTimerBottomBar({required this.secondsRemaining});

  @override
  Widget build(BuildContext context) {
    if (secondsRemaining <= 0) return const SizedBox.shrink();

    final remaining = Duration(seconds: secondsRemaining);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(14),
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => context.read<RestTimerBloc>().add(const AdjustRestTimer(-15)),
                  child: const Text('- 15'),
                ),
                Expanded(
                  child: Text(
                    DateFormatters.elapsed(remaining),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: () => context.read<RestTimerBloc>().add(const AdjustRestTimer(15)),
                  child: const Text('+15'),
                ),
                TextButton(
                  onPressed: () => context.read<RestTimerBloc>().add(const SkipRestTimer()),
                  child: const Text('Skip'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkoutTimersBanner extends StatefulWidget {
  final DateTime startTime;
  final double volumeKg;
  final int completedSets;

  const _WorkoutTimersBanner({
    required this.startTime,
    required this.volumeKg,
    required this.completedSets,
  });

  @override
  State<_WorkoutTimersBanner> createState() => _WorkoutTimersBannerState();
}

class _WorkoutTimersBannerState extends State<_WorkoutTimersBanner> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(widget.startTime);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Stat(label: 'Duration', value: DateFormatters.elapsed(elapsed)),
            _Stat(label: 'Volume', value: '${widget.volumeKg.toStringAsFixed(0)} kg'),
            _Stat(label: 'Sets', value: '${widget.completedSets}'),
          ],
        ),
      ],
    );
  }
}

class _ExerciseBlock extends StatelessWidget {
  final WorkoutExerciseDetail detail;
  final ActiveWorkoutState state;
  final int index;
  final int exerciseCount;

  const _ExerciseBlock({
    required this.detail,
    required this.state,
    required this.index,
    required this.exerciseCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    detail.exercise.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.lightBlueAccent),
                  ),
                ),
                PopupMenuButton<_ExerciseAction>(
                  onSelected: (action) async {
                    final cubit = context.read<ActiveWorkoutCubit>();
                    switch (action) {
                      case _ExerciseAction.up:
                        await cubit.moveExercise(detail.workoutExercise.id, -1);
                        return;
                      case _ExerciseAction.down:
                        await cubit.moveExercise(detail.workoutExercise.id, 1);
                        return;
                      case _ExerciseAction.remove:
                        await cubit.removeExercise(detail.workoutExercise.id);
                        return;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _ExerciseAction.up,
                      enabled: index > 0,
                      child: const Text('Go up'),
                    ),
                    PopupMenuItem(
                      value: _ExerciseAction.down,
                      enabled: index < exerciseCount - 1,
                      child: const Text('Go down'),
                    ),
                    const PopupMenuItem(
                      value: _ExerciseAction.remove,
                      child: Text('Remove'),
                    ),
                  ],
                ),
              ],
            ),
            TextField(decoration: const InputDecoration(hintText: 'Add notes here...')),
            Text('Rest: ${detail.workoutExercise.restSeconds ?? 90}s'),
            const SizedBox(height: 8),
            const Row(
              children: [
                SizedBox(width: 38, child: Text('SET')),
                Expanded(child: Text('PREVIOUS')),
                SizedBox(width: 82, child: Text('KG')),
                SizedBox(width: 82, child: Text('REPS')),
                SizedBox(width: 48, child: Icon(Icons.check)),
              ],
            ),
            ...detail.sets.indexed.map((entry) {
              final index = entry.$1;
              final set = entry.$2;
              return _SetRow(
                key: ValueKey(set.id),
                index: index,
                set: set,
                previous: state.previousByExerciseId[detail.exercise.id] ?? '-',
              );
            }),
            TextButton.icon(
              onPressed: () => context.read<ActiveWorkoutCubit>().addSet(detail.workoutExercise.id),
              icon: const Icon(Icons.add),
              label: const Text('Add Set'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetRow extends StatefulWidget {
  final int index;
  final WorkoutSet set;
  final String previous;

  const _SetRow({super.key, required this.index, required this.set, required this.previous});

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  ActiveWorkoutCubit? _cubit;
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;
  late final FocusNode _weightFocus;
  late final FocusNode _repsFocus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cubit ??= context.read<ActiveWorkoutCubit>();
  }

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: _weightDisplay);
    _repsController = TextEditingController(text: _repsDisplay);
    _weightFocus = FocusNode();
    _repsFocus = FocusNode();
    _weightFocus.addListener(_onWeightFocusChange);
    _repsFocus.addListener(_onRepsFocusChange);
  }

  String get _weightDisplay => widget.set.weight?.toString() ?? '';

  String get _repsDisplay => widget.set.reps?.toString() ?? '';

  void _onWeightFocusChange() {
    if (!_weightFocus.hasFocus) {
      _commitWeight();
    }
  }

  void _onRepsFocusChange() {
    if (!_repsFocus.hasFocus) {
      _commitReps();
    }
  }

  bool _sameWeightAsPersisted() {
    final t = _weightController.text.trim();
    if (t.isEmpty) return widget.set.weight == null;
    final p = double.tryParse(t);
    return p != null && p == widget.set.weight;
  }

  bool _sameRepsAsPersisted() {
    final t = _repsController.text.trim();
    if (t.isEmpty) return widget.set.reps == null;
    final p = int.tryParse(t);
    return p != null && p == widget.set.reps;
  }

  Future<void> _commitWeight() async {
    if (_sameWeightAsPersisted()) return;
    final value = _weightController.text;
    final cubit = _cubit ?? context.read<ActiveWorkoutCubit>();
    await cubit.updateSetValue(
      widget.set,
      weight: double.tryParse(value.trim()),
      clearWeight: value.trim().isEmpty,
    );
  }

  Future<void> _commitReps() async {
    if (_sameRepsAsPersisted()) return;
    final value = _repsController.text;
    final cubit = _cubit ?? context.read<ActiveWorkoutCubit>();
    await cubit.updateSetValue(
      widget.set,
      reps: int.tryParse(value.trim()),
      clearReps: value.trim().isEmpty,
    );
  }

  Future<void> _commitEditsThenToggle() async {
    await _commitWeight();
    await _commitReps();
    if (!mounted) return;
    await (_cubit ?? context.read<ActiveWorkoutCubit>()).toggleSet(widget.set);
  }

  Future<void> _showSetMenu() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await _commitWeight();
    await _commitReps();
    if (!mounted) return;
    final selection = await showModalBottomSheet<Object>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...SetType.values.map(
              (type) => ListTile(
                leading: _SetTypeBadge(type: type, fallbackNumber: widget.index + 1),
                title: Text(type.displayName),
                onTap: () => Navigator.of(context).pop(type),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Remove set'),
              onTap: () => Navigator.of(context).pop(_SetMenuAction.remove),
            ),
          ],
        ),
      ),
    );
    if (!mounted || selection == null) return;
    final cubit = _cubit ?? context.read<ActiveWorkoutCubit>();
    if (selection == _SetMenuAction.remove) {
      await cubit.removeSet(widget.set);
      return;
    }
    await cubit.updateSetType(widget.set, selection as SetType);
  }

  void _persistDirtyWithoutFocus() {
    final cubit = _cubit;
    if (cubit == null) return;
    if (!_sameWeightAsPersisted()) {
      final value = _weightController.text;
      unawaited(
        cubit.updateSetValue(
          widget.set,
          weight: double.tryParse(value.trim()),
          clearWeight: value.trim().isEmpty,
        ),
      );
    }
    if (!_sameRepsAsPersisted()) {
      final value = _repsController.text;
      unawaited(
        cubit.updateSetValue(
          widget.set,
          reps: int.tryParse(value.trim()),
          clearReps: value.trim().isEmpty,
        ),
      );
    }
  }

  @override
  void didUpdateWidget(covariant _SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.set.id != widget.set.id) {
      _weightController.text = _weightDisplay;
      _repsController.text = _repsDisplay;
      return;
    }
    if (!_weightFocus.hasFocus && oldWidget.set.weight != widget.set.weight) {
      _weightController.text = _weightDisplay;
    }
    if (!_repsFocus.hasFocus && oldWidget.set.reps != widget.set.reps) {
      _repsController.text = _repsDisplay;
    }
  }

  @override
  void dispose() {
    _weightFocus.removeListener(_onWeightFocusChange);
    _repsFocus.removeListener(_onRepsFocusChange);
    _persistDirtyWithoutFocus();
    _weightFocus.dispose();
    _repsFocus.dispose();
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final set = widget.set;
    return Container(
      color: set.isCompleted
          ? Theme.of(context).colorScheme.primary.withOpacity(0.18)
          : set.setType == SetType.warmUp
              ? Colors.amber.withOpacity(0.12)
              : null,
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: InkWell(
              onTap: _showSetMenu,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _SetTypeBadge(type: set.setType, fallbackNumber: widget.index + 1),
              ),
            ),
          ),
          Expanded(child: Text(widget.previous, overflow: TextOverflow.ellipsis)),
          SizedBox(
            width: 82,
            child: TextField(
              controller: _weightController,
              focusNode: _weightFocus,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(isDense: true),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 82,
            child: TextField(
              controller: _repsController,
              focusNode: _repsFocus,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(isDense: true),
            ),
          ),
          IconButton(
            onPressed: _commitEditsThenToggle,
            icon: Icon(set.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(label),
      ],
    );
  }
}

enum _ExerciseAction { up, down, remove }

enum _SetMenuAction { remove }

class _SetTypeBadge extends StatelessWidget {
  final SetType type;
  final int fallbackNumber;

  const _SetTypeBadge({required this.type, required this.fallbackNumber});

  @override
  Widget build(BuildContext context) {
    final label = type == SetType.working ? '$fallbackNumber' : type.marker;
    final color = _setTypeColor(type, Theme.of(context).colorScheme.onSurface);
    return Text(
      label,
      textAlign: TextAlign.center,
      style: TextStyle(fontWeight: FontWeight.w700, color: color),
    );
  }

  Color _setTypeColor(SetType type, Color normalColor) {
    switch (type) {
      case SetType.warmUp:
        return Colors.amber;
      case SetType.working:
        return normalColor;
      case SetType.dropSet:
        return Colors.lightBlueAccent;
      case SetType.amrap:
        return Colors.lightGreenAccent;
      case SetType.failure:
        return Colors.redAccent;
    }
  }
}
