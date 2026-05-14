import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/common/routes/routes.dart';
import 'package:gym_tracker/core/enums/tracking_type_enum.dart';
import 'package:gym_tracker/features/library/bloc/exercise_list_cubit.dart';

class ExerciseListScreen extends StatelessWidget {
  const ExerciseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExerciseListCubit, ExerciseListState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Exercise Library')),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search exercises'),
                  onChanged: context.read<ExerciseListCubit>().search,
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    DropdownButton<String?>(
                      value: state.equipmentId,
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('All Equipment')),
                        ...state.equipment.map((item) => DropdownMenuItem<String?>(value: item.id, child: Text(item.name))),
                      ],
                      onChanged: context.read<ExerciseListCubit>().setEquipment,
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String?>(
                      value: state.muscleId,
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('All Muscles')),
                        ...state.muscles.map((item) => DropdownMenuItem<String?>(value: item.id, child: Text(item.name))),
                      ],
                      onChanged: context.read<ExerciseListCubit>().setMuscle,
                    ),
                  ],
                ),
              ),
              if (state.isLoading) const LinearProgressIndicator(),
              Expanded(
                child: ListView.builder(
                  itemCount: state.exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = state.exercises[index];
                    return ListTile(
                      leading: Container(width: 42, height: 42, color: Theme.of(context).colorScheme.surfaceContainerHighest),
                      title: Text(exercise.name),
                      subtitle: Text(exercise.trackingType.displayName),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).pushNamed(
                        Routes.exerciseDetail,
                        arguments: ExerciseDetailRouteArgs(exerciseId: exercise.id),
                      ),
                    );
                  },
                ),
              ),
              if (state.errorMessage != null) Text(state.errorMessage!),
            ],
          ),
        );
      },
    );
  }
}
