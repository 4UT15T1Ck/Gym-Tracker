import 'package:gym_tracker/core/dao/exercise_dao.dart';
import 'package:gym_tracker/core/dao/routine_exercise_dao.dart';
import 'package:gym_tracker/core/dao/routine_set_dao.dart';
import 'package:gym_tracker/core/dao/workout_dao.dart';
import 'package:gym_tracker/core/dao/workout_exercise_dao.dart';
import 'package:gym_tracker/core/dao/workout_set_dao.dart';
import 'package:gym_tracker/core/enums/set_type_enum.dart';
import 'package:gym_tracker/core/enums/workout_status_enum.dart';
import 'package:gym_tracker/core/models/routine_set_model.dart';
import 'package:gym_tracker/core/models/workout_exercise_model.dart';
import 'package:gym_tracker/core/models/workout_model.dart';
import 'package:gym_tracker/core/models/workout_set_model.dart';
import 'package:gym_tracker/core/repositories/repository_models.dart';
import 'package:gym_tracker/core/repositories/workout_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

@LazySingleton(as: WorkoutRepository)
class WorkoutRepositoryImpl implements WorkoutRepository {
  final WorkoutDao _workoutDao;
  final WorkoutExerciseDao _workoutExerciseDao;
  final WorkoutSetDao _workoutSetDao;
  final RoutineExerciseDao _routineExerciseDao;
  final RoutineSetDao _routineSetDao;
  final ExerciseDao _exerciseDao;
  final Database _db;
  final Uuid _uuid;

  WorkoutRepositoryImpl(
    this._workoutDao,
    this._workoutExerciseDao,
    this._workoutSetDao,
    this._routineExerciseDao,
    this._routineSetDao,
    this._exerciseDao,
    this._db,
    this._uuid,
  );

  @override
  Future<WorkoutDetail> startWorkout({required String name, String? routineId}) async {
    return await _db.transaction((txn) async {
      final workoutId = _uuid.v4();
      final workout = Workout(
        id: workoutId,
        routineId: routineId,
        name: name,
        startTime: DateTime.now(),
        status: WorkoutStatus.active,
      );
      await _workoutDao.insert(workout, txn);

      if (routineId != null) {
        final routineExercises = await _routineExerciseDao.getByRoutineId(routineId);
        final reIds = routineExercises.map((re) => re.id).toList();
        final routineSets = reIds.isEmpty
            ? <RoutineSet>[]
            : await _routineSetDao.getByRoutineExerciseIds(reIds);

        final setsByReId = <String, List<RoutineSet>>{};
        for (final set in routineSets) {
          setsByReId.putIfAbsent(set.routineExerciseId, () => []).add(set);
        }

        for (final (index, routineExercise) in routineExercises.indexed) {
          final weId = _uuid.v4();
          final workoutExercise = WorkoutExercise(
            id: weId,
            workoutId: workoutId,
            exerciseId: routineExercise.exerciseId,
            order: index,
            restSeconds: routineExercise.targetRestSeconds,
          );
          await _workoutExerciseDao.insert(workoutExercise, txn);

          final sets = setsByReId[routineExercise.id] ?? [];
          for (final (setIndex, routineSet) in sets.indexed) {
            final wsId = _uuid.v4();
            final workoutSet = WorkoutSet(
              id: wsId,
              workoutExerciseId: weId,
              setType: routineSet.setType,
              weight: routineSet.targetWeight,
              reps: routineSet.targetReps,
              durationSeconds: routineSet.targetDurationSeconds,
              distance: routineSet.targetDistance,
              rpe: routineSet.targetRpe,
              order: setIndex,
              isCompleted: false,
            );
            await _workoutSetDao.insert(workoutSet, txn);
          }
        }
      }

      final workoutExercises = await _workoutExerciseDao.getByWorkoutId(workoutId);
      final weIds = workoutExercises.map((we) => we.id).toList();
      final workoutSets = weIds.isEmpty
          ? <WorkoutSet>[]
          : await _workoutSetDao.getByWorkoutExerciseIds(weIds);
      final exerciseIds = workoutExercises.map((we) => we.exerciseId).toList();
      final exercises = await _exerciseDao.getByIds(exerciseIds);

      final exerciseMap = {for (var e in exercises) e.id: e};
      final setsByWeId = <String, List<WorkoutSet>>{};
      for (final set in workoutSets) {
        setsByWeId.putIfAbsent(set.workoutExerciseId, () => []).add(set);
      }

      final exerciseDetails = workoutExercises.map((we) {
        final exercise = exerciseMap[we.exerciseId];
        if (exercise == null) {
          throw Exception('Exercise not found: ${we.exerciseId}');
        }
        final sets = setsByWeId[we.id] ?? [];
        return WorkoutExerciseDetail(
          workoutExercise: we,
          exercise: exercise,
          sets: sets,
        );
      }).toList();

      return WorkoutDetail(
        workout: workout,
        exercises: exerciseDetails,
      );
    });
  }

  @override
  Future<WorkoutDetail?> getActiveWorkout() async {
    final workout = await _workoutDao.getActive();
    if (workout == null) return null;
    return await getWorkoutDetail(workout.id);
  }

  @override
  Future<WorkoutDetail> getWorkoutDetail(String workoutId) async {
    final workout = await _workoutDao.getById(workoutId);
    if (workout == null) {
      throw Exception('Workout not found: $workoutId');
    }

    final workoutExercises = await _workoutExerciseDao.getByWorkoutId(workoutId);
    final weIds = workoutExercises.map((we) => we.id).toList();
    final workoutSets = weIds.isEmpty
        ? <WorkoutSet>[]
        : await _workoutSetDao.getByWorkoutExerciseIds(weIds);
    final exerciseIds = workoutExercises.map((we) => we.exerciseId).toList();
    final exercises = await _exerciseDao.getByIds(exerciseIds);

    final exerciseMap = {for (var e in exercises) e.id: e};
    final setsByWeId = <String, List<WorkoutSet>>{};
    for (final set in workoutSets) {
      setsByWeId.putIfAbsent(set.workoutExerciseId, () => []).add(set);
    }

    final exerciseDetails = workoutExercises.map((we) {
      final exercise = exerciseMap[we.exerciseId];
      if (exercise == null) {
        throw Exception('Exercise not found: ${we.exerciseId}');
      }
      final sets = setsByWeId[we.id] ?? [];
      return WorkoutExerciseDetail(
        workoutExercise: we,
        exercise: exercise,
        sets: sets,
      );
    }).toList();

    return WorkoutDetail(
      workout: workout,
      exercises: exerciseDetails,
    );
  }

  @override
  Future<Workout> completeWorkout(String workoutId) async {
    return await _db.transaction((txn) async {
      final endTime = DateTime.now();
      await _workoutDao.updateStatus(workoutId, WorkoutStatus.completed, txn);
      await _workoutDao.updateEndTime(workoutId, endTime, txn);
      final workout = await _workoutDao.getById(workoutId, txn);
      if (workout == null) {
        throw Exception('Workout not found: $workoutId');
      }
      return workout;
    });
  }

  @override
  Future<void> cancelWorkout(String workoutId) async {
    await _db.transaction((txn) async {
      await _workoutDao.updateStatus(workoutId, WorkoutStatus.cancelled, txn);
      await _workoutDao.updateEndTime(workoutId, DateTime.now(), txn);
    });
  }

  @override
  Future<List<WorkoutSummary>> getWorkoutHistory({
    int limit = 20,
    int offset = 0,
    DateTime? from,
    DateTime? to,
  }) async {
    final historyMaps = await _workoutDao.getHistory(
      limit: limit,
      offset: offset,
      from: from,
      to: to,
    );

    final workoutIds = historyMaps.map((map) => map['id'] as String).toList();
    final exerciseNamesMap = await _workoutDao.getExerciseNamesForWorkouts(workoutIds);

    return historyMaps.map((map) {
      final workoutId = map['id'] as String;
      return WorkoutSummary(
        id: workoutId,
        name: map['name'] as String,
        startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
        endTime: DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int),
        volume: (map['volume'] as num).toDouble(),
        totalSets: map['total_sets'] as int,
        totalExercises: map['total_exercises'] as int,
        exerciseNames: exerciseNamesMap[workoutId] ?? [],
      );
    }).toList();
  }

  @override
  Future<Workout> updateWorkoutMeta({
    required String workoutId,
    String? name,
    String? notes,
  }) async {
    await _workoutDao.updateMeta(id: workoutId, name: name, notes: notes);
    final workout = await _workoutDao.getById(workoutId);
    if (workout == null) {
      throw Exception('Workout not found: $workoutId');
    }
    return workout;
  }

  @override
  Future<WorkoutExercise> addExerciseToWorkout({
    required String workoutId,
    required String exerciseId,
    int? restSeconds,
  }) async {
    return await _db.transaction((txn) async {
      final maxOrder = await _workoutExerciseDao.getMaxOrder(workoutId, txn);
      final weId = _uuid.v4();
      final workoutExercise = WorkoutExercise(
        id: weId,
        workoutId: workoutId,
        exerciseId: exerciseId,
        order: maxOrder + 1,
        restSeconds: restSeconds,
      );
      await _workoutExerciseDao.insert(workoutExercise, txn);
      return workoutExercise;
    });
  }

  @override
  Future<void> reorderWorkoutExercises({
    required String workoutId,
    required List<String> orderedIds,
  }) async {
    await _db.transaction((txn) async {
      for (final (index, id) in orderedIds.indexed) {
        await _workoutExerciseDao.updateOrder(id, index, txn);
      }
    });
  }

  @override
  Future<void> removeExerciseFromWorkout(String workoutExerciseId) async {
    await _workoutExerciseDao.delete(workoutExerciseId, _db);
  }

  @override
  Future<WorkoutSet> addSet({
    required String workoutExerciseId,
    SetType setType = SetType.working,
  }) async {
    return await _db.transaction((txn) async {
      final maxOrder = await _workoutSetDao.getMaxOrder(workoutExerciseId, txn);
      final wsId = _uuid.v4();
      final workoutSet = WorkoutSet(
        id: wsId,
        workoutExerciseId: workoutExerciseId,
        setType: setType,
        order: maxOrder + 1,
        isCompleted: false,
      );
      await _workoutSetDao.insert(workoutSet, txn);
      return workoutSet;
    });
  }

  @override
  Future<WorkoutSet> updateSet(WorkoutSet set) async {
    await _workoutSetDao.update(set, _db);
    return set;
  }

  @override
  Future<({WorkoutSet set, double newVolume})> completeSet(String setId) async {
    return await _db.transaction((txn) async {
      final set = await _workoutSetDao.getById(setId, txn);
      if (set == null) {
        throw Exception('Set not found: $setId');
      }

      final updatedSet = WorkoutSet(
        id: set.id,
        workoutExerciseId: set.workoutExerciseId,
        setType: set.setType,
        weight: set.weight,
        reps: set.reps,
        durationSeconds: set.durationSeconds,
        distance: set.distance,
        rpe: set.rpe,
        completedAt: DateTime.now(),
        order: set.order,
        isCompleted: true,
      );
      await _workoutSetDao.update(updatedSet, txn);

      final workoutExercise = await _workoutExerciseDao.getById(set.workoutExerciseId, txn);
      if (workoutExercise == null) {
        throw Exception('Workout exercise not found');
      }
      final workoutId = workoutExercise.workoutId;

      final newVolume = await _workoutSetDao.computeVolume(workoutId, txn);
      await _workoutDao.updateVolume(workoutId, newVolume, txn);

      return (set: updatedSet, newVolume: newVolume);
    });
  }

  @override
  Future<({WorkoutSet set, double newVolume})> uncompleteSet(String setId) async {
    return await _db.transaction((txn) async {
      final set = await _workoutSetDao.getById(setId, txn);
      if (set == null) {
        throw Exception('Set not found: $setId');
      }

      final updatedSet = WorkoutSet(
        id: set.id,
        workoutExerciseId: set.workoutExerciseId,
        setType: set.setType,
        weight: set.weight,
        reps: set.reps,
        durationSeconds: set.durationSeconds,
        distance: set.distance,
        rpe: set.rpe,
        completedAt: null,
        order: set.order,
        isCompleted: false,
      );
      await _workoutSetDao.update(updatedSet, txn);

      final workoutExercise = await _workoutExerciseDao.getById(set.workoutExerciseId, txn);
      if (workoutExercise == null) {
        throw Exception('Workout exercise not found');
      }
      final workoutId = workoutExercise.workoutId;

      final newVolume = await _workoutSetDao.computeVolume(workoutId, txn);
      await _workoutDao.updateVolume(workoutId, newVolume, txn);

      return (set: updatedSet, newVolume: newVolume);
    });
  }

  @override
  Future<double> removeSet(String setId) async {
    return await _db.transaction((txn) async {
      final set = await _workoutSetDao.getById(setId, txn);
      if (set == null) {
        throw Exception('Set not found: $setId');
      }

      final workoutExercise = await _workoutExerciseDao.getById(set.workoutExerciseId, txn);
      if (workoutExercise == null) {
        throw Exception('Workout exercise not found');
      }
      final workoutId = workoutExercise.workoutId;

      await _workoutSetDao.delete(setId, txn);

      final newVolume = await _workoutSetDao.computeVolume(workoutId, txn);
      await _workoutDao.updateVolume(workoutId, newVolume, txn);
      return newVolume;
    });
  }

  @override
  Future<void> reorderSets({
    required String workoutExerciseId,
    required List<String> orderedIds,
  }) async {
    await _db.transaction((txn) async {
      for (final (index, id) in orderedIds.indexed) {
        await _workoutSetDao.updateOrder(id, index, txn);
      }
    });
  }

  @override
  Future<DateTime?> getLastCompletedSetTime(String workoutExerciseId) async {
    return await _workoutSetDao.getLastCompletedAt(workoutExerciseId);
  }
}
