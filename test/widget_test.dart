import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/core/enums/set_type_enum.dart';
import 'package:gym_tracker/core/enums/tracking_type_enum.dart';
import 'package:gym_tracker/core/models/body_measure_entry_model.dart';
import 'package:gym_tracker/core/models/exercise_model.dart';
import 'package:gym_tracker/core/models/workout_exercise_model.dart';
import 'package:gym_tracker/core/models/workout_model.dart';
import 'package:gym_tracker/core/models/workout_set_model.dart';
import 'package:gym_tracker/core/repositories/analytics_repository.dart';
import 'package:gym_tracker/core/repositories/body_measurement_repository.dart';
import 'package:gym_tracker/core/repositories/exercise_repository.dart';
import 'package:gym_tracker/core/repositories/repository_models.dart';
import 'package:gym_tracker/core/repositories/routine_repository.dart';
import 'package:gym_tracker/core/repositories/workout_repository.dart';
import 'package:gym_tracker/core/services/notification_service.dart';
import 'package:gym_tracker/features/home/bloc/home_dashboard_cubit.dart';
import 'package:gym_tracker/features/profile/bloc/measures_cubit.dart';
import 'package:gym_tracker/features/profile/bloc/profile_cubit.dart';
import 'package:gym_tracker/features/profile/presentation/measures_screen.dart';
import 'package:gym_tracker/features/profile/presentation/profile_home_screen.dart';
import 'package:gym_tracker/features/shell/bloc/shell_active_workout_cubit.dart';
import 'package:gym_tracker/features/shell/presentation/main_shell_screen.dart';
import 'package:gym_tracker/features/workout/bloc/active_workout_cubit.dart';
import 'package:gym_tracker/features/workout/bloc/create_routine_cubit.dart';
import 'package:gym_tracker/features/workout/bloc/rest_timer_bloc.dart';
import 'package:gym_tracker/features/workout/bloc/workout_home_cubit.dart';
import 'package:gym_tracker/features/workout/presentation/active_workout_screen.dart';
import 'package:gym_tracker/features/workout/presentation/create_routine_screen.dart';

void main() {
  testWidgets('Main shell smoke test renders bottom navigation', (
    tester,
  ) async {
    final workoutRepo = _NoopWorkoutRepository();
    final routineRepo = _NoopRoutineRepository();
    final exerciseRepo = _NoopExerciseRepository();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<HomeDashboardCubit>(
            create: (_) =>
                HomeDashboardCubit(workoutRepo, routineRepo, exerciseRepo),
          ),
          BlocProvider<WorkoutHomeCubit>(
            create: (_) => WorkoutHomeCubit(routineRepo, workoutRepo),
          ),
          BlocProvider<ProfileCubit>(
            create: (_) =>
                ProfileCubit(workoutRepo, _NoopAnalyticsRepository()),
          ),
          BlocProvider<ShellActiveWorkoutCubit>(
            create: (_) => ShellActiveWorkoutCubit(workoutRepo),
          ),
        ],
        child: const MaterialApp(home: MainShellScreen()),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Workout'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('Active workout set toggle updates UI state', (tester) async {
    final activeCubit = _TestActiveWorkoutCubit();
    final restBloc = RestTimerBloc(
      NotificationService(),
      onApplyRest: (restEndsAt, workoutExerciseId) {},
      onCompleteSkipped: () {},
      onCompleteNaturally: () {},
      onClearWithoutSkip: () {},
    );
    addTearDown(activeCubit.close);
    addTearDown(restBloc.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ActiveWorkoutCubit>.value(value: activeCubit),
          BlocProvider<RestTimerBloc>.value(value: restBloc),
        ],
        child: const MaterialApp(home: ActiveWorkoutScreen()),
      ),
    );

    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);

    await tester.tap(find.byIcon(Icons.radio_button_unchecked));
    await tester.pump();

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('Create routine save shows loading/check sequence', (
    tester,
  ) async {
    final cubit = _TestCreateRoutineCubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                key: const ValueKey<String>('open-create-routine'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<bool>(
                      builder: (_) => BlocProvider<CreateRoutineCubit>.value(
                        value: cubit,
                        child: const CreateRoutineScreen(),
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('open-create-routine')));
    await tester.pumpAndSettle();

    expect(find.text('Create Routine'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 90));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 120));
    expect(cubit.state.didSave, isTrue);
  });

  testWidgets('Profile chart updates when range changes', (tester) async {
    final cubit = _TestProfileCubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<ProfileCubit>.value(
            value: cubit,
            child: const ProfileHomeScreen(),
          ),
        ),
      ),
    );

    expect(find.byType(AnimatedContainer), findsWidgets);
    expect(find.byType(SegmentedButton<ProfileChartRange>), findsOneWidget);

    await tester.tap(find.text('Month'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));

    expect(cubit.state.chartRange, ProfileChartRange.month);
    expect(cubit.state.chartBars.length, 10);
  });

  testWidgets('Measures screen renders updated list from state reload', (
    tester,
  ) async {
    final repository = _InMemoryBodyMeasurementRepository();
    final cubit = MeasuresCubit(repository);
    addTearDown(cubit.close);

    await repository.addEntry(
      date: DateTime(2026, 5, 20),
      weight: 78.5,
      bodyFatPercent: 16.2,
      customMeasurements: const {},
    );
    await cubit.load();

    await tester.pumpWidget(
      BlocProvider<MeasuresCubit>.value(
        value: cubit,
        child: const MaterialApp(home: MeasuresScreen()),
      ),
    );
    await tester.pump();

    expect(find.byType(ListTile), findsOneWidget);
    expect(find.textContaining('Weight: 78.5'), findsOneWidget);

    await repository.deleteEntry('entry-0');
    await cubit.load();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));

    expect(find.byType(ListTile), findsNothing);
  });
}

class _TestActiveWorkoutCubit extends ActiveWorkoutCubit {
  _TestActiveWorkoutCubit()
    : super(_NoopWorkoutRepository(), _NoopExerciseRepository()) {
    emit(
      ActiveWorkoutState(
        detail: _seedDetail(),
        previousByExerciseId: const {'ex-1': '-'},
      ),
    );
  }

  static WorkoutDetail _seedDetail() {
    final workout = Workout(
      id: 'w-1',
      name: 'Test Workout',
      startTime: DateTime(2026, 5, 1, 10),
      volume: 0,
    );
    final exercise = Exercise(
      id: 'ex-1',
      name: 'Bench Press',
      trackingType: ExerciseTrackingType.weightReps,
      primaryMuscleId: 'chest',
    );
    final workoutExercise = WorkoutExercise(
      id: 'we-1',
      workoutId: workout.id,
      exerciseId: exercise.id,
      order: 0,
      restSeconds: 90,
    );
    final set = WorkoutSet(
      id: 'set-1',
      workoutExerciseId: workoutExercise.id,
      setType: SetType.working,
      weight: 80,
      reps: 8,
      order: 0,
      isCompleted: false,
    );
    return WorkoutDetail(
      workout: workout,
      exercises: [
        WorkoutExerciseDetail(
          workoutExercise: workoutExercise,
          exercise: exercise,
          sets: [set],
        ),
      ],
    );
  }

  @override
  Future<void> toggleSet(WorkoutSet target) async {
    final detail = state.detail;
    if (detail == null) return;
    final updatedExercises = detail.exercises.map((exercise) {
      if (exercise.workoutExercise.id != target.workoutExerciseId) {
        return exercise;
      }
      final updatedSets = exercise.sets.map((set) {
        if (set.id != target.id) return set;
        return WorkoutSet(
          id: set.id,
          workoutExerciseId: set.workoutExerciseId,
          setType: set.setType,
          weight: set.weight,
          reps: set.reps,
          durationSeconds: set.durationSeconds,
          distance: set.distance,
          rpe: set.rpe,
          completedAt: set.isCompleted ? null : DateTime(2026, 5, 1, 10, 1),
          order: set.order,
          isCompleted: !set.isCompleted,
        );
      }).toList();
      return WorkoutExerciseDetail(
        workoutExercise: exercise.workoutExercise,
        exercise: exercise.exercise,
        sets: updatedSets,
      );
    }).toList();

    emit(
      state.copyWith(
        detail: WorkoutDetail(
          workout: detail.workout,
          exercises: updatedExercises,
        ),
      ),
    );
  }
}

class _TestCreateRoutineCubit extends CreateRoutineCubit {
  _TestCreateRoutineCubit() : super(_NoopRoutineRepository()) {
    emit(state.copyWith(title: 'Push Day'));
  }

  @override
  Future<void> save() async {
    emit(state.copyWith(isSaving: true, clearError: true));
    await Future<void>.delayed(const Duration(milliseconds: 60));
    emit(state.copyWith(isSaving: false, didSave: true));
  }
}

class _TestProfileCubit extends ProfileCubit {
  _TestProfileCubit()
    : super(_NoopWorkoutRepository(), _NoopAnalyticsRepository()) {
    emit(_stateFor(ProfileChartRange.week));
  }

  static ProfileState _stateFor(ProfileChartRange range) {
    final count = range == ProfileChartRange.week ? 7 : 10;
    final bars = List.generate(
      count,
      (index) => ProfileChartBar(
        label: 'B${index + 1}',
        start: DateTime(2026, 5, index + 1),
        end: DateTime(2026, 5, index + 1),
        value: (index + 1) * (range == ProfileChartRange.week ? 8 : 5),
      ),
    );
    return ProfileState(
      username: 'Alex',
      initials: 'A',
      chartRange: range,
      chartMetric: ProfileChartMetric.volume,
      chartBars: bars,
    );
  }

  @override
  Future<void> load() async {}

  @override
  Future<void> updateChart(
    ProfileChartMetric metric,
    ProfileChartRange range,
  ) async {
    emit(_stateFor(range).copyWith(chartMetric: metric));
  }

  @override
  Future<void> updateName(String value) async {
    emit(
      state.copyWith(
        username: value,
        initials: value.trim().isEmpty ? 'A' : value.trim()[0].toUpperCase(),
      ),
    );
  }
}

class _InMemoryBodyMeasurementRepository implements BodyMeasurementRepository {
  final List<BodyMeasureEntry> _entries = <BodyMeasureEntry>[];
  int _counter = 0;

  @override
  Future<BodyMeasureEntry> addEntry({
    required DateTime date,
    double? weight,
    double? bodyFatPercent,
    Map<String, double> customMeasurements = const {},
  }) async {
    final entry = BodyMeasureEntry(
      id: 'entry-${_counter++}',
      date: date,
      weight: weight,
      bodyFatPercent: bodyFatPercent,
      customMeasurements: customMeasurements,
    );
    _entries.insert(0, entry);
    return entry;
  }

  @override
  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((entry) => entry.id == id);
  }

  @override
  Future<List<BodyMeasureEntry>> getEntries() async {
    return List<BodyMeasureEntry>.from(_entries);
  }

  @override
  Future<BodyMeasureEntry?> getLatestEntry() async {
    return _entries.isEmpty ? null : _entries.first;
  }
}

class _NoopWorkoutRepository implements WorkoutRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(invocation.memberName.toString());
  }
}

class _NoopRoutineRepository implements RoutineRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(invocation.memberName.toString());
  }
}

class _NoopExerciseRepository implements ExerciseRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(invocation.memberName.toString());
  }
}

class _NoopAnalyticsRepository implements AnalyticsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(invocation.memberName.toString());
  }
}
