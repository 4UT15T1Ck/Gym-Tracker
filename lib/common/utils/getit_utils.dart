import 'package:get_it/get_it.dart';
import 'package:gym_tracker/common/utils/getit_utils.config.dart';
import 'package:gym_tracker/features/shell/bloc/shell_active_workout_cubit.dart';
import 'package:injectable/injectable.dart';

final getIt = GetIt.instance;

@injectableInit
Future<void> configureDependencies() => getIt.init();

class GetItUtils {
  static Future<void> setup() async {
    await configureDependencies();
    await getIt<ShellActiveWorkoutCubit>().load();
  }
}
