import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/common/routes/routes.dart';
import 'package:gym_tracker/common/widgets/tap_scale.dart';
import 'package:gym_tracker/core/enums/tracking_type_enum.dart';
import 'package:gym_tracker/core/models/exercise_model.dart';
import 'package:gym_tracker/features/workout/bloc/add_exercise_cubit.dart';

class AddExerciseScreen extends StatelessWidget {
  static const _bgColor = Color(0xFF080A0F);
  static const _cardColor = Color(0xFF151A23);
  static const _mutedText = Color(0xFF8C94A5);
  static const _accent = Color(0xFF4A8DFF);
  static const _outline = Color(0xFF283041);

  final AddExerciseRouteArgs args;

  const AddExerciseScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddExerciseCubit, AddExerciseState>(
      builder: (context, state) {
        final theme = Theme.of(context);
        return Scaffold(
          backgroundColor: _bgColor,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
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
                          'Add Exercise',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: _mutedText),
                      hintText: 'Search exercises',
                      hintStyle: theme.textTheme.bodyLarge?.copyWith(
                        color: _mutedText,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: _accent,
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: _cardColor,
                    ),
                    onChanged: (value) =>
                        context.read<AddExerciseCubit>().setQuery(value),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      _FilterDropdown<String?>(
                        value: state.equipmentId,
                        hint: 'All Equipment',
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All Equipment'),
                          ),
                          ...state.equipment.map(
                            (e) => DropdownMenuItem<String?>(
                              value: e.id,
                              child: Text(e.name),
                            ),
                          ),
                        ],
                        onChanged: (value) => context
                            .read<AddExerciseCubit>()
                            .setEquipment(value),
                      ),
                      const SizedBox(width: 12),
                      _FilterDropdown<String?>(
                        value: state.muscleId,
                        hint: 'All Muscles',
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All Muscles'),
                          ),
                          ...state.muscles.map(
                            (m) => DropdownMenuItem<String?>(
                              value: m.id,
                              child: Text(m.name),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            context.read<AddExerciseCubit>().setMuscle(value),
                      ),
                    ],
                  ),
                ),
                if (state.isLoading)
                  const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    children: [
                      if (state.recentExercises.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            'Recent Exercises',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: _mutedText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        ...state.recentExercises.map(
                          (exercise) =>
                              _ExerciseRow(exercise: exercise, args: args),
                        ),
                      ],
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          'All Exercises',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: _mutedText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      ...state.exercises.map(
                        (exercise) =>
                            _ExerciseRow(exercise: exercise, args: args),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: TapScale(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: state.selectedIds.isEmpty
                            ? null
                            : () => Navigator.of(context).pop(
                                context
                                    .read<AddExerciseCubit>()
                                    .selectedExercises(),
                              ),
                        child: Text(
                          'Add ${state.selectedIds.length} exercises',
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

class _ExerciseRow extends StatelessWidget {
  final Exercise exercise;
  final AddExerciseRouteArgs args;

  const _ExerciseRow({required this.exercise, required this.args});

  @override
  Widget build(BuildContext context) {
    final selected = context.select(
      (AddExerciseCubit cubit) => cubit.state.selectedIds.contains(exercise.id),
    );
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFF1A2A43)
            : AddExerciseScreen._cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? AddExerciseScreen._accent
              : AddExerciseScreen._outline,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF0F141D),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.fitness_center,
            color: AddExerciseScreen._mutedText,
            size: 18,
          ),
        ),
        title: Text(
          exercise.name,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          exercise.trackingType.displayName,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AddExerciseScreen._mutedText,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.show_chart,
            color: AddExerciseScreen._mutedText,
          ),
          onPressed: () => Navigator.of(context).pushNamed(
            Routes.exerciseDetail,
            arguments: ExerciseDetailRouteArgs(exerciseId: exercise.id),
          ),
        ),
        onTap: () => context.read<AddExerciseCubit>().toggle(
          exercise,
          multiSelect: args.multiSelect,
        ),
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AddExerciseScreen._cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AddExerciseScreen._outline),
      ),
      child: DropdownButton<T>(
        value: value,
        hint: Text(
          hint,
          style: const TextStyle(color: AddExerciseScreen._mutedText),
        ),
        dropdownColor: AddExerciseScreen._cardColor,
        underline: const SizedBox.shrink(),
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.white),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}
