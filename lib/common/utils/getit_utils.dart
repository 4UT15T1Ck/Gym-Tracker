import 'package:get_it/get_it.dart';
import 'package:gym_tracker/common/utils/getit_utils.config.dart';
import 'package:gym_tracker/core/repositories/workout_repository.dart';
import 'package:gym_tracker/core/services/notification_service.dart';
import 'package:gym_tracker/features/shell/bloc/shell_active_workout_cubit.dart';
import 'package:gym_tracker/features/workout/bloc/active_workout_cubit.dart';
import 'package:gym_tracker/features/workout/bloc/rest_timer_bloc.dart';
import 'package:injectable/injectable.dart';

final getIt = GetIt.instance;

@injectableInit
Future<void> configureDependencies() => getIt.init();

class GetItUtils {
  static Future<void> setup() async {
    await configureDependencies();
    if (!getIt.isRegistered<ShellActiveWorkoutCubit>()) {
      final shell = ShellActiveWorkoutCubit(getIt<WorkoutRepository>());
      getIt.registerSingleton<ShellActiveWorkoutCubit>(shell);
      await shell.load();
    }
    if (!getIt.isRegistered<NotificationService>()) {
      getIt.registerLazySingleton<NotificationService>(() => NotificationService());
    }
    if (!getIt.isRegistered<RestTimerBloc>()) {
      getIt.registerLazySingleton<RestTimerBloc>(
        () => RestTimerBloc(
          getIt<NotificationService>(),
          onApplyRest: (a, b) => getIt<ActiveWorkoutCubit>().applyRestFromTimer(a, b),
          onCompleteSkipped: () => getIt<ActiveWorkoutCubit>().completeRestTimerSkipped(),
          onCompleteNaturally: () => getIt<ActiveWorkoutCubit>().completeRestTimerNaturally(),
          onClearWithoutSkip: () => getIt<ActiveWorkoutCubit>().clearRestFromTimerWithoutSkip(),
        ),
      );
    }
  }
}
