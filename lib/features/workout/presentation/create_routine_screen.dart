import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/common/routes/routes.dart';
import 'package:gym_tracker/core/enums/set_type_enum.dart';
import 'package:gym_tracker/core/models/exercise_model.dart';
import 'package:gym_tracker/features/workout/bloc/create_routine_cubit.dart';

class CreateRoutineScreen extends StatelessWidget {
  const CreateRoutineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreateRoutineCubit, CreateRoutineState>(
      listenWhen: (previous, current) => previous.didSave != current.didSave,
      listener: (context, state) {
        if (state.didSave) Navigator.of(context).pop(true);
      },
      child: BlocBuilder<CreateRoutineCubit, CreateRoutineState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              leading: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(state.isEditing ? 'Back' : 'Cancel'),
              ),
              title: Text(state.isEditing ? 'Edit Routine' : 'Create Routine'),
              actions: [
                TextButton(
                  onPressed: state.isSaving ? null : () => context.read<CreateRoutineCubit>().save(),
                  child: const Text('Save'),
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  key: ValueKey('routine-title-${state.routineIdBeingEdited ?? 'new'}'),
                  initialValue: state.title,
                  decoration: const InputDecoration(labelText: 'Routine title'),
                  onChanged: context.read<CreateRoutineCubit>().updateTitle,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: ValueKey('routine-notes-${state.routineIdBeingEdited ?? 'new'}'),
                  initialValue: state.notes,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Optional',
                  ),
                  onChanged: context.read<CreateRoutineCubit>().updateNotes,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    final result = await Navigator.of(context).pushNamed<List<Exercise>>(
                      Routes.addExercise,
                      arguments: const AddExerciseRouteArgs(),
                    );
                    if (!context.mounted || result == null) return;
                    context.read<CreateRoutineCubit>().addExercises(result);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add exercise'),
                ),
                if (state.exercises.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text('Get started by adding an exercise')),
                  ),
                ...state.exercises.indexed.map((entry) {
                  final exerciseIndex = entry.$1;
                  final item = entry.$2;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(item.exercise.name, style: Theme.of(context).textTheme.titleMedium)),
                              IconButton(
                                onPressed: () => context.read<CreateRoutineCubit>().moveExercise(exerciseIndex, -1),
                                icon: const Icon(Icons.keyboard_arrow_up),
                              ),
                              IconButton(
                                onPressed: () => context.read<CreateRoutineCubit>().moveExercise(exerciseIndex, 1),
                                icon: const Icon(Icons.keyboard_arrow_down),
                              ),
                              IconButton(
                                onPressed: () => context.read<CreateRoutineCubit>().removeExercise(exerciseIndex),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                          TextFormField(
                            key: ValueKey('rest-${item.exercise.id}'),
                            initialValue: item.restSeconds?.toString() ?? '',
                            decoration: const InputDecoration(labelText: 'Rest seconds'),
                            keyboardType: TextInputType.number,
                            onChanged: (value) => context.read<CreateRoutineCubit>().updateRestSeconds(
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
                                  child: _SetTypeBadge(type: set.setType, fallbackNumber: setIndex + 1),
                                ),
                                Expanded(
                                  child: DropdownButton<SetType>(
                                    value: set.setType,
                                    isExpanded: true,
                                    items: SetType.values
                                        .map((type) => DropdownMenuItem(value: type, child: Text(type.displayName)))
                                        .toList(),
                                    onChanged: (type) {
                                      if (type == null) return;
                                      context.read<CreateRoutineCubit>().updateSet(
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
                                    key: ValueKey('weight-${item.exercise.id}-$setIndex'),
                                    initialValue: set.targetWeight?.toString() ?? '',
                                    decoration: const InputDecoration(labelText: 'Kg'),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) => context.read<CreateRoutineCubit>().updateSet(
                                          exerciseIndex: exerciseIndex,
                                          setIndex: setIndex,
                                          targetWeight: double.tryParse(value),
                                          clearWeight: value.trim().isEmpty,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 78,
                                  child: TextFormField(
                                    key: ValueKey('reps-${item.exercise.id}-$setIndex'),
                                    initialValue: set.targetReps?.toString() ?? '',
                                    decoration: const InputDecoration(labelText: 'Reps'),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) => context.read<CreateRoutineCubit>().updateSet(
                                          exerciseIndex: exerciseIndex,
                                          setIndex: setIndex,
                                          targetReps: int.tryParse(value),
                                          clearReps: value.trim().isEmpty,
                                        ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => context.read<CreateRoutineCubit>().removeSet(exerciseIndex, setIndex),
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            );
                          }),
                          TextButton.icon(
                            onPressed: () => context.read<CreateRoutineCubit>().addSet(exerciseIndex),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Set'),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                if (state.isSaving) const LinearProgressIndicator(),
                if (state.errorMessage != null) Text(state.errorMessage!),
              ],
            ),
          );
        },
      ),
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
