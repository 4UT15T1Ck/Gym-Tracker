import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/common/routes/routes.dart';
import 'package:gym_tracker/core/enums/tracking_type_enum.dart';
import 'package:gym_tracker/core/models/exercise_model.dart';
import 'package:gym_tracker/features/workout/bloc/add_exercise_cubit.dart';

class AddExerciseScreen extends StatelessWidget {
  final AddExerciseRouteArgs args;

  const AddExerciseScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddExerciseCubit, AddExerciseState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            leading: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            title: const Text('Add Exercise'),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search exercises'),
                  onChanged: (value) => context.read<AddExerciseCubit>().setQuery(value),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    DropdownButton<String?>(
                      value: state.equipmentId,
                      hint: const Text('All Equipment'),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('All Equipment')),
                        ...state.equipment.map((e) => DropdownMenuItem<String?>(value: e.id, child: Text(e.name))),
                      ],
                      onChanged: (value) => context.read<AddExerciseCubit>().setEquipment(value),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String?>(
                      value: state.muscleId,
                      hint: const Text('All Muscles'),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('All Muscles')),
                        ...state.muscles.map((m) => DropdownMenuItem<String?>(value: m.id, child: Text(m.name))),
                      ],
                      onChanged: (value) => context.read<AddExerciseCubit>().setMuscle(value),
                    ),
                  ],
                ),
              ),
              if (state.isLoading) const LinearProgressIndicator(),
              Expanded(
                child: ListView(
                  children: [
                    if (state.recentExercises.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Recent Exercises'),
                      ),
                      ...state.recentExercises.map((exercise) => _ExerciseRow(exercise: exercise, args: args)),
                    ],
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('All Exercises'),
                    ),
                    ...state.exercises.map((exercise) => _ExerciseRow(exercise: exercise, args: args)),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: FilledButton(
                    onPressed: state.selectedIds.isEmpty
                        ? null
                        : () => Navigator.of(context).pop(context.read<AddExerciseCubit>().selectedExercises()),
                    child: Text('Add ${state.selectedIds.length} exercises'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final Exercise exercise;
  final AddExerciseRouteArgs args;

  const _ExerciseRow({required this.exercise, required this.args});

  @override
  Widget build(BuildContext context) {
    final selected = context.select((AddExerciseCubit cubit) => cubit.state.selectedIds.contains(exercise.id));
    return ListTile(
      leading: Container(width: 42, height: 42, color: Theme.of(context).colorScheme.surfaceContainerHighest),
      title: Text(exercise.name),
      subtitle: Text(exercise.trackingType.displayName),
      selected: selected,
      trailing: IconButton(
        icon: const Icon(Icons.show_chart),
        onPressed: () => Navigator.of(context).pushNamed(
          Routes.exerciseDetail,
          arguments: ExerciseDetailRouteArgs(exerciseId: exercise.id),
        ),
      ),
      onTap: () => context.read<AddExerciseCubit>().toggle(exercise, multiSelect: args.multiSelect),
    );
  }
}
