import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gym_tracker/core/services/notification_service.dart';
import 'package:gym_tracker/app.dart';
import 'package:gym_tracker/core/data/preferences_store.dart';
import 'package:gym_tracker/common/utils/getit_utils.dart';
import 'package:gym_tracker/features/home/bloc/home_dashboard_cubit.dart';
import 'package:gym_tracker/features/profile/bloc/profile_cubit.dart';
import 'package:gym_tracker/features/workout/bloc/workout_home_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PreferencesStore.init();
  await GetItUtils.setup();
  if (Platform.isAndroid || Platform.isIOS) {
    final notificationService = getIt<NotificationService>();
    await notificationService.init();
    await notificationService.requestPermission();
  }
  getIt<HomeDashboardCubit>().load();
  getIt<WorkoutHomeCubit>().load();
  getIt<ProfileCubit>().load();
  runApp(const MainApp());
}
