import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/common/routes/routes.dart';
import 'package:gym_tracker/common/utils/getit_utils.dart';
import 'package:gym_tracker/features/home/bloc/home_dashboard_cubit.dart';
import 'package:gym_tracker/features/profile/bloc/profile_cubit.dart';
import 'package:gym_tracker/features/shell/bloc/shell_active_workout_cubit.dart';
import 'package:gym_tracker/core/services/notification_service.dart';
import 'package:gym_tracker/features/workout/bloc/rest_timer_bloc.dart';
import 'package:gym_tracker/features/workout/bloc/workout_home_cubit.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: MultiBlocProvider(
        providers: [
          BlocProvider<HomeDashboardCubit>.value(value: getIt<HomeDashboardCubit>()),
          BlocProvider<WorkoutHomeCubit>.value(value: getIt<WorkoutHomeCubit>()),
          BlocProvider<ProfileCubit>.value(value: getIt<ProfileCubit>()),
          BlocProvider<ShellActiveWorkoutCubit>.value(value: getIt<ShellActiveWorkoutCubit>()),
          BlocProvider<RestTimerBloc>.value(value: getIt<RestTimerBloc>()),
        ],
        child: MaterialApp(
          navigatorKey: NotificationService.navigatorKey,
          title: 'Gym Tracker',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
          onGenerateRoute: Routes.onGenerateRoute,
          initialRoute: Routes.home,
        ),
      ),
    );
  }
}
