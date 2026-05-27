import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/common/utils/getit_utils.dart';
import 'package:gym_tracker/core/models/exercise_model.dart';
import 'package:gym_tracker/features/library/bloc/exercise_detail_cubit.dart';
import 'package:gym_tracker/features/library/bloc/exercise_list_cubit.dart';
import 'package:gym_tracker/features/library/presentation/exercise_detail_screen.dart';
import 'package:gym_tracker/features/library/presentation/exercise_list_screen.dart';
import 'package:gym_tracker/features/profile/bloc/measures_cubit.dart';
import 'package:gym_tracker/features/profile/bloc/muscle_map_cubit.dart';
import 'package:gym_tracker/features/profile/bloc/statistics_cubit.dart';
import 'package:gym_tracker/features/profile/bloc/workout_detail_cubit.dart';
import 'package:gym_tracker/features/profile/bloc/workout_history_cubit.dart';
import 'package:gym_tracker/features/profile/presentation/measures_screen.dart';
import 'package:gym_tracker/features/profile/presentation/muscle_map_screen.dart';
import 'package:gym_tracker/features/profile/presentation/statistics_screen.dart';
import 'package:gym_tracker/features/profile/presentation/workout_detail_screen.dart';
import 'package:gym_tracker/features/profile/presentation/workout_history_screen.dart';
import 'package:gym_tracker/features/shell/presentation/main_shell_screen.dart';
import 'package:gym_tracker/features/workout/bloc/active_workout_cubit.dart';
import 'package:gym_tracker/features/workout/bloc/add_exercise_cubit.dart';
import 'package:gym_tracker/features/workout/bloc/create_routine_cubit.dart';
import 'package:gym_tracker/features/workout/bloc/routine_detail_cubit.dart';
import 'package:gym_tracker/features/workout/presentation/active_workout_screen.dart';
import 'package:gym_tracker/features/workout/presentation/add_exercise_screen.dart';
import 'package:gym_tracker/features/workout/presentation/create_routine_screen.dart';
import 'package:gym_tracker/features/workout/presentation/routine_detail_screen.dart';

import 'route_args.dart';
export 'route_args.dart';

class Routes {
  static const String home = '/';
  static const String activeWorkout = '/active-workout';
  static const String addExercise = '/add-exercise';
  static const String createRoutine = '/create-routine';
  static const String routineDetail = '/routine-detail';
  static const String editRoutine = '/edit-routine';
  static const String exerciseList = '/exercise-list';
  static const String exerciseDetail = '/exercise-detail';
  static const String statistics = '/statistics';
  static const String muscleMap = '/muscle-map';
  static const String measures = '/measures';
  static const String workoutHistory = '/workout-history';
  static const String workoutDetail = '/workout-detail';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const MainShellScreen());

      // ── Singleton cubit — use BlocProvider.value (no auto-close) ──
      case activeWorkout:
        final args = settings.arguments as ActiveWorkoutRouteArgs;
        final cubit = getIt<ActiveWorkoutCubit>();
        cubit.load(args.workoutId);
        return MaterialPageRoute(
          builder: (_) => BlocProvider<ActiveWorkoutCubit>.value(
            value: cubit,
            child: const ActiveWorkoutScreen(),
          ),
        );

      // ── Factory cubits — use BlocProvider(create:) so they auto-close ──
      case addExercise:
        final args = settings.arguments as AddExerciseRouteArgs? ?? const AddExerciseRouteArgs();
        return MaterialPageRoute<List<Exercise>>(
          builder: (_) => BlocProvider(
            create: (_) => getIt<AddExerciseCubit>()
              ..load(initiallySelectedIds: args.initiallySelectedExerciseIds),
            child: AddExerciseScreen(args: args),
          ),
        );
      case createRoutine:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => getIt<CreateRoutineCubit>()..prepareNew(),
            child: const CreateRoutineScreen(),
          ),
        );
      case routineDetail:
        final detailArgs = settings.arguments as RoutineDetailRouteArgs;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => getIt<RoutineDetailCubit>()..load(detailArgs.routineId),
            child: const RoutineDetailScreen(),
          ),
        );
      case editRoutine:
        final editArgs = settings.arguments as EditRoutineRouteArgs;
        return MaterialPageRoute<bool>(
          builder: (_) => BlocProvider(
            create: (_) => getIt<CreateRoutineCubit>()..prepareEdit(editArgs.detail),
            child: const CreateRoutineScreen(),
          ),
        );
      case exerciseList:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => getIt<ExerciseListCubit>()..load(),
            child: const ExerciseListScreen(),
          ),
        );
      case exerciseDetail:
        final args = settings.arguments as ExerciseDetailRouteArgs;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => getIt<ExerciseDetailCubit>()..load(args.exerciseId),
            child: const ExerciseDetailScreen(),
          ),
        );
      case statistics:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => getIt<StatisticsCubit>()..load(),
            child: const StatisticsScreen(),
          ),
        );
      case muscleMap:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => getIt<MuscleMapCubit>()..load(),
            child: const MuscleMapScreen(),
          ),
        );
      case measures:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => getIt<MeasuresCubit>()..load(),
            child: const MeasuresScreen(),
          ),
        );
      case workoutHistory:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => getIt<WorkoutHistoryCubit>()..load(),
            child: const WorkoutHistoryScreen(),
          ),
        );
      case workoutDetail:
        final args = settings.arguments as WorkoutDetailRouteArgs;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => getIt<WorkoutDetailCubit>()..load(args.workoutId),
            child: const WorkoutDetailScreen(),
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
