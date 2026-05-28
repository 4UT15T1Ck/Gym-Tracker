import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/common/routes/routes.dart';
import 'package:gym_tracker/core/enums/tracking_type_enum.dart';
import 'package:gym_tracker/features/library/bloc/exercise_list_cubit.dart';

class ExerciseListScreen extends StatelessWidget {
  const ExerciseListScreen({super.key});
  static const _bgColor = Color(0xFF080A0F);
  static const _cardColor = Color(0xFF151A23);
  static const _mutedText = Color(0xFF8C94A5);
  static const _accent = Color(0xFF4A8DFF);
  static const _outline = Color(0xFF283041);
  static const _accentTextDark = Color(0xFF0E335A);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExerciseListCubit, ExerciseListState>(
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
                          'Exercise Library',
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
                    onChanged: context.read<ExerciseListCubit>().search,
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
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
                            (item) => DropdownMenuItem<String?>(
                              value: item.id,
                              child: Text(item.name),
                            ),
                          ),
                        ],
                        onChanged: context
                            .read<ExerciseListCubit>()
                            .setEquipment,
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
                            (item) => DropdownMenuItem<String?>(
                              value: item.id,
                              child: Text(item.name),
                            ),
                          ),
                        ],
                        onChanged: context.read<ExerciseListCubit>().setMuscle,
                      ),
                    ],
                  ),
                ),
                if (state.isLoading)
                  const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    itemCount: state.exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = state.exercises[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _outline),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A8DFF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.fitness_center,
                              color: _accentTextDark,
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
                              color: _mutedText,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: _mutedText,
                          ),
                          onTap: () => Navigator.of(context).pushNamed(
                            Routes.exerciseDetail,
                            arguments: ExerciseDetailRouteArgs(
                              exerciseId: exercise.id,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: Colors.redAccent),
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
      width: 175,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: ExerciseListScreen._cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ExerciseListScreen._outline),
      ),
      child: DropdownButton<T>(
        value: value,
        hint: Text(
          hint,
          style: const TextStyle(color: ExerciseListScreen._mutedText),
        ),
        dropdownColor: ExerciseListScreen._cardColor,
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
