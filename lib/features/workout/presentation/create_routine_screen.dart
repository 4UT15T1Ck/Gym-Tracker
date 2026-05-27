import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/common/routes/routes.dart';
import 'package:gym_tracker/common/widgets/app_haptics.dart';
import 'package:gym_tracker/common/widgets/motion_tokens.dart';
import 'package:gym_tracker/common/widgets/success_pulse_overlay.dart';
import 'package:gym_tracker/common/widgets/tap_scale.dart';
import 'package:gym_tracker/core/enums/set_type_enum.dart';
import 'package:gym_tracker/core/models/exercise_model.dart';
import 'package:gym_tracker/features/workout/bloc/create_routine_cubit.dart';

class CreateRoutineScreen extends StatelessWidget {
  const CreateRoutineScreen({super.key});
  static const _bgColor = Color(0xFF080A0F);
  static const _cardColor = Color(0xFF151A23);
  static const _mutedText = Color(0xFF8C94A5);
  static const _accent = Color(0xFF4A8DFF);
  static const _outline = Color(0xFF283041);

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreateRoutineCubit, CreateRoutineState>(
      listenWhen: (previous, current) => previous.didSave != current.didSave,
      listener: (context, state) async {
        if (state.didSave) {
          await AppHaptics.success(context);
          if (context.mounted) {
            await SuccessPulseOverlay.show(
              context,
              message: 'Routine saved',
              duration: MotionTokens.successPulse,
            );
          }
          if (context.mounted) {
            Navigator.of(context).pop(true);
          }
        }
      },
      child: BlocBuilder<CreateRoutineCubit, CreateRoutineState>(
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
                          state.isEditing ? 'Edit Routine' : 'Create Routine',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TapScale(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(72, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: state.isSaving
                              ? null
                              : () => context.read<CreateRoutineCubit>().save(),
                          child: AnimatedSwitcher(
                            duration: MotionTokens.resolve(
                              context,
                              MotionTokens.fast,
                            ),
                            switchInCurve: MotionTokens.standardCurve,
                            switchOutCurve: MotionTokens.standardCurve,
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  ),
                                ),
                            child: _saveLabelForState(state),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _outline),
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          key: ValueKey(
                            'routine-title-${state.routineIdBeingEdited ?? 'new'}',
                          ),
                          initialValue: state.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                          decoration: _inputDecoration('Routine title', theme),
                          onChanged: context
                              .read<CreateRoutineCubit>()
                              .updateTitle,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: ValueKey(
                            'routine-notes-${state.routineIdBeingEdited ?? 'new'}',
                          ),
                          initialValue: state.notes,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                          ),
                          decoration: _inputDecoration(
                            'Notes',
                            theme,
                            hintText: 'Optional',
                          ),
                          onChanged: context
                              .read<CreateRoutineCubit>()
                              .updateNotes,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TapScale(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _cardColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () async {
                        final result = await Navigator.of(context)
                            .pushNamed<List<Exercise>>(
                              Routes.addExercise,
                              arguments: const AddExerciseRouteArgs(),
                            );
                        if (!context.mounted || result == null) return;
                        context.read<CreateRoutineCubit>().addExercises(result);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add exercise'),
                    ),
                  ),
                  if (state.exercises.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'Get started by adding an exercise',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: _mutedText,
                          ),
                        ),
                      ),
                    ),
                  ...state.exercises.indexed.map((entry) {
                    final exerciseIndex = entry.$1;
                    final item = entry.$2;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.exercise.name,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => context
                                      .read<CreateRoutineCubit>()
                                      .moveExercise(exerciseIndex, -1),
                                  icon: const Icon(
                                    Icons.keyboard_arrow_up,
                                    color: _mutedText,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => context
                                      .read<CreateRoutineCubit>()
                                      .moveExercise(exerciseIndex, 1),
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: _mutedText,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => context
                                      .read<CreateRoutineCubit>()
                                      .removeExercise(exerciseIndex),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                            TextFormField(
                              key: ValueKey('rest-${item.exercise.id}'),
                              initialValue: item.restSeconds?.toString() ?? '',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                              ),
                              decoration: _inputDecoration(
                                'Rest seconds',
                                theme,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) => context
                                  .read<CreateRoutineCubit>()
                                  .updateRestSeconds(
                                    exerciseIndex,
                                    int.tryParse(value),
                                  ),
                            ),
                            const SizedBox(height: 8),
                            ...item.sets.indexed.map((setEntry) {
                              final setIndex = setEntry.$1;
                              final set = setEntry.$2;
                              return Row(
                                children: [
                                  SizedBox(
                                    width: 28,
                                    child: _SetTypeBadge(
                                      type: set.setType,
                                      fallbackNumber: setIndex + 1,
                                    ),
                                  ),
                                  Expanded(
                                    child: DropdownButton<SetType>(
                                      value: set.setType,
                                      dropdownColor: _cardColor,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(color: Colors.white),
                                      isExpanded: true,
                                      items: SetType.values
                                          .map(
                                            (type) => DropdownMenuItem(
                                              value: type,
                                              child: Text(type.displayName),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (type) {
                                        if (type == null) return;
                                        context
                                            .read<CreateRoutineCubit>()
                                            .updateSet(
                                              exerciseIndex: exerciseIndex,
                                              setIndex: setIndex,
                                              setType: type,
                                            );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 78,
                                    child: TextFormField(
                                      key: ValueKey(
                                        'weight-${item.exercise.id}-$setIndex',
                                      ),
                                      initialValue:
                                          set.targetWeight?.toString() ?? '',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(color: Colors.white),
                                      decoration: _inputDecoration('Kg', theme),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) => context
                                          .read<CreateRoutineCubit>()
                                          .updateSet(
                                            exerciseIndex: exerciseIndex,
                                            setIndex: setIndex,
                                            targetWeight: double.tryParse(
                                              value,
                                            ),
                                            clearWeight: value.trim().isEmpty,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 78,
                                    child: TextFormField(
                                      key: ValueKey(
                                        'reps-${item.exercise.id}-$setIndex',
                                      ),
                                      initialValue:
                                          set.targetReps?.toString() ?? '',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(color: Colors.white),
                                      decoration: _inputDecoration(
                                        'Reps',
                                        theme,
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) => context
                                          .read<CreateRoutineCubit>()
                                          .updateSet(
                                            exerciseIndex: exerciseIndex,
                                            setIndex: setIndex,
                                            targetReps: int.tryParse(value),
                                            clearReps: value.trim().isEmpty,
                                          ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => context
                                        .read<CreateRoutineCubit>()
                                        .removeSet(exerciseIndex, setIndex),
                                    icon: const Icon(
                                      Icons.close,
                                      color: _mutedText,
                                    ),
                                  ),
                                ],
                              );
                            }),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: _accent,
                                ),
                                onPressed: () => context
                                    .read<CreateRoutineCubit>()
                                    .addSet(exerciseIndex),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Set'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  AnimatedSwitcher(
                    duration: MotionTokens.resolve(context, MotionTokens.base),
                    switchInCurve: MotionTokens.standardCurve,
                    switchOutCurve: MotionTokens.standardCurve,
                    child: state.isSaving
                        ? const Padding(
                            key: ValueKey('saving-progress'),
                            padding: EdgeInsets.only(top: 8),
                            child: LinearProgressIndicator(),
                          )
                        : const SizedBox.shrink(key: ValueKey('saving-empty')),
                  ),
                  AnimatedSwitcher(
                    duration: MotionTokens.resolve(context, MotionTokens.base),
                    switchInCurve: MotionTokens.standardCurve,
                    switchOutCurve: MotionTokens.standardCurve,
                    child: state.errorMessage == null
                        ? const SizedBox.shrink(key: ValueKey('error-empty'))
                        : _ErrorPanel(
                            key: const ValueKey('error-panel'),
                            message: state.errorMessage!,
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _saveLabelForState(CreateRoutineState state) {
    if (state.isSaving) {
      return const SizedBox(
        key: ValueKey('save-saving'),
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (state.didSave) {
      return const Icon(
        Icons.check_rounded,
        key: ValueKey('save-done'),
        size: 18,
      );
    }
    return const Text('Save', key: ValueKey('save-idle'));
  }

  InputDecoration _inputDecoration(
    String label,
    ThemeData theme, {
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      labelStyle: theme.textTheme.bodyMedium?.copyWith(color: _mutedText),
      hintStyle: theme.textTheme.bodyMedium?.copyWith(color: _mutedText),
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
}

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

class _ErrorPanel extends StatelessWidget {
  final String message;

  const _ErrorPanel({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
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
