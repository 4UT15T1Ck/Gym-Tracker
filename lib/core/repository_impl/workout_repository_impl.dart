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
import 'package:rxdart/rxdart.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

const int _defaultWorkoutSetReps = 10;

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
  final BehaviorSubject<WorkoutDetail?> _activeWorkoutSubject;

  WorkoutRepositoryImpl(
    this._workoutDao,
    this._workoutExerciseDao,
    this._workoutSetDao,
    this._routineExerciseDao,
    this._routineSetDao,
    this._exerciseDao,
    this._db,
    this._uuid,
  ) : _activeWorkoutSubject = BehaviorSubject<WorkoutDetail?>.seeded(null);

  @override
  Stream<WorkoutDetail?> get activeWorkoutChanges => _activeWorkoutSubject.stream;

  @override
  Future<WorkoutDetail> startWorkout({required String name, String? routineId}) async {
    final detail = await _db.transaction((txn) async {
      final activeWorkout = await _workoutDao.getActive(txn);
      if (activeWorkout != null) {
        throw StateError('An active workout is already in progress.');
      }

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
        final routineExercises = await _routineExerciseDao.getByRoutineId(routineId, txn);
        final reIds = routineExercises.map((re) => re.id).toList();
        final routineSets = reIds.isEmpty
            ? <RoutineSet>[]
            : await _routineSetDao.getByRoutineExerciseIds(reIds, txn);

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

      final workoutExercises = await _workoutExerciseDao.getByWorkoutId(workoutId, txn);
      final weIds = workoutExercises.map((we) => we.id).toList();
      final workoutSets = weIds.isEmpty
          ? <WorkoutSet>[]
          : await _workoutSetDao.getByWorkoutExerciseIds(weIds, txn);
      final exerciseIds = workoutExercises.map((we) => we.exerciseId).toList();
      final exercises = await _exerciseDao.getByIds(exerciseIds, txn);

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
    _activeWorkoutSubject.add(detail);
    return detail;
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
    final workout = await _db.transaction((txn) async {
      final workoutExercises = await _workoutExerciseDao.getByWorkoutId(
        workoutId,
        txn,
      );
      final workoutExerciseIds = workoutExercises.map((we) => we.id).toList();
      final sets = await _workoutSetDao.getByWorkoutExerciseIds(
        workoutExerciseIds,
        txn,
      );
      final hasInvalidCompletedSet = sets.any(
        (set) => set.isCompleted && !_hasValidWeightAndReps(set),
      );
      if (hasInvalidCompletedSet) {
        throw StateError(
          'Completed sets must have weight and reps greater than 0.',
        );
      }

      final endTime = DateTime.now();
      await _workoutDao.updateStatus(workoutId, WorkoutStatus.completed, txn);
      await _workoutDao.updateEndTime(workoutId, endTime, txn);
      final workout = await _workoutDao.getById(workoutId, txn);
      if (workout == null) {
        throw Exception('Workout not found: $workoutId');
      }
      return workout;
    });
    _activeWorkoutSubject.add(null);
    return workout;
  }

  @override
  Future<void> cancelWorkout(String workoutId) async {
    await _db.transaction((txn) async {
      await _workoutDao.updateStatus(workoutId, WorkoutStatus.cancelled, txn);
      await _workoutDao.updateEndTime(workoutId, DateTime.now(), txn);
    });
    _activeWorkoutSubject.add(null);
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
  Future<List<({String workoutId, String exerciseId, String primaryMuscleId})>> getWorkoutMuscleGroups(
    List<String> workoutIds,
  ) async {
    return await _workoutDao.getWorkoutMuscleGroups(workoutIds);
  }

  @override
  Future<Workout> updateWorkoutMeta({
    required String workoutId,
    String? name,
    String? notes,
    bool clearNotes = false,
  }) async {
    await _workoutDao.updateMeta(
      id: workoutId,
      name: name,
      notes: notes,
      clearNotes: clearNotes,
    );
    final workout = await _workoutDao.getById(workoutId);
    if (workout == null) {
      throw Exception('Workout not found: $workoutId');
    }
    await _notifyActiveWorkoutChanged(workoutId);
    return workout;
  }

  @override
  Future<WorkoutExercise> addExerciseToWorkout({
    required String workoutId,
    required String exerciseId,
    int? restSeconds,
  }) async {
    final workoutExercise = await _db.transaction((txn) async {
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
    await _notifyActiveWorkoutChanged(workoutId);
    return workoutExercise;
  }

  @override
  Future<void> reorderWorkoutExercises({
    required String workoutId,
    required List<String> orderedIds,
  }) async {
    await _db.transaction((txn) async {
      // Two-pass: avoid unique constraint violation on (workout_id, order).
      for (final (index, id) in orderedIds.indexed) {
        await _workoutExerciseDao.updateOrder(id, -(index + 1), txn);
      }
      for (final (index, id) in orderedIds.indexed) {
        await _workoutExerciseDao.updateOrder(id, index, txn);
      }
    });
    await _notifyActiveWorkoutChanged(workoutId);
  }

  @override
  Future<void> removeExerciseFromWorkout(String workoutExerciseId) async {
    final workoutId = await _db.transaction<String?>((txn) async {
      final workoutExercise = await _workoutExerciseDao.getById(workoutExerciseId, txn);
      if (workoutExercise == null) return null;
      await _workoutExerciseDao.delete(workoutExerciseId, txn);
      final newVolume = await _workoutSetDao.computeVolume(workoutExercise.workoutId, txn);
      await _workoutDao.updateVolume(workoutExercise.workoutId, newVolume, txn);
      return workoutExercise.workoutId;
    });
    if (workoutId != null) {
      await _notifyActiveWorkoutChanged(workoutId);
    }
  }

  @override
  Future<WorkoutSet> addSet({
    required String workoutExerciseId,
    SetType setType = SetType.working,
  }) async {
    final result = await _db.transaction<({WorkoutSet set, String workoutId})>(
      (txn) async {
        final workoutExercise = await _workoutExerciseDao.getById(
          workoutExerciseId,
          txn,
        );
        if (workoutExercise == null) {
          throw Exception('Workout exercise not found: $workoutExerciseId');
        }
        final maxOrder = await _workoutSetDao.getMaxOrder(
          workoutExerciseId,
          txn,
        );
        final previousSet = await _workoutSetDao.getLastByWorkoutExerciseId(
          workoutExerciseId,
          txn,
        );
        final previousWeight = previousSet?.weight;
        final wsId = _uuid.v4();
        final workoutSet = WorkoutSet(
          id: wsId,
          workoutExerciseId: workoutExerciseId,
          setType: setType,
          weight: previousWeight != null && previousWeight > 0
              ? previousWeight
              : null,
          reps: _defaultWorkoutSetReps,
          order: maxOrder + 1,
          isCompleted: false,
        );
        await _workoutSetDao.insert(workoutSet, txn);
        return (set: workoutSet, workoutId: workoutExercise.workoutId);
      },
    );
    await _notifyActiveWorkoutChanged(result.workoutId);
    return result.set;
  }

  @override
  Future<WorkoutSet> updateSet(WorkoutSet set) async {
    final result = await _db.transaction<({WorkoutSet set, String? workoutId})>((txn) async {
      await _workoutSetDao.update(set, txn);
      // Recalculate volume so it stays in sync after weight/reps edits.
      final we = await _workoutExerciseDao.getById(set.workoutExerciseId, txn);
      if (we != null) {
        final newVolume = await _workoutSetDao.computeVolume(we.workoutId, txn);
        await _workoutDao.updateVolume(we.workoutId, newVolume, txn);
      }
      return (set: set, workoutId: we?.workoutId);
    });
    if (result.workoutId != null) {
      await _notifyActiveWorkoutChanged(result.workoutId!);
    }
    return result.set;
  }

  @override
  Future<({WorkoutSet set, double newVolume})> completeSet(String setId) async {
    String? workoutId;
    final result = await _db.transaction((txn) async {
      final set = await _workoutSetDao.getById(setId, txn);
      if (set == null) {
        throw Exception('Set not found: $setId');
      }
      if (!_hasValidWeightAndReps(set)) {
        throw StateError(
          'Weight and reps must be greater than 0 before completing a set.',
        );
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
      workoutId = workoutExercise.workoutId;

      final newVolume = await _workoutSetDao.computeVolume(workoutId!, txn);
      await _workoutDao.updateVolume(workoutId!, newVolume, txn);

      return (set: updatedSet, newVolume: newVolume);
    });
    if (workoutId != null) {
      await _notifyActiveWorkoutChanged(workoutId!);
    }
    return result;
  }

  static bool _hasValidWeightAndReps(WorkoutSet set) {
    final weight = set.weight;
    final reps = set.reps;
    return weight != null && weight > 0 && reps != null && reps > 0;
  }

  @override
  Future<({WorkoutSet set, double newVolume})> uncompleteSet(String setId) async {
    String? workoutId;
    final result = await _db.transaction((txn) async {
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
      workoutId = workoutExercise.workoutId;

      final newVolume = await _workoutSetDao.computeVolume(workoutId!, txn);
      await _workoutDao.updateVolume(workoutId!, newVolume, txn);

      return (set: updatedSet, newVolume: newVolume);
    });
    if (workoutId != null) {
      await _notifyActiveWorkoutChanged(workoutId!);
    }
    return result;
  }

  @override
  Future<double> removeSet(String setId) async {
    String? workoutId;
    final newVolume = await _db.transaction((txn) async {
      final set = await _workoutSetDao.getById(setId, txn);
      if (set == null) {
        throw Exception('Set not found: $setId');
      }

      final workoutExercise = await _workoutExerciseDao.getById(set.workoutExerciseId, txn);
      if (workoutExercise == null) {
        throw Exception('Workout exercise not found');
      }
      workoutId = workoutExercise.workoutId;

      await _workoutSetDao.delete(setId, txn);

      final newVolume = await _workoutSetDao.computeVolume(workoutId!, txn);
      await _workoutDao.updateVolume(workoutId!, newVolume, txn);
      return newVolume;
    });
    if (workoutId != null) {
      await _notifyActiveWorkoutChanged(workoutId!);
    }
    return newVolume;
  }

  @override
  Future<void> reorderSets({
    required String workoutExerciseId,
    required List<String> orderedIds,
  }) async {
    final workoutId = await _db.transaction<String?>((txn) async {
      final workoutExercise = await _workoutExerciseDao.getById(workoutExerciseId, txn);
      // Two-pass: avoid unique constraint violation on (workout_exercise_id, order).
      for (final (index, id) in orderedIds.indexed) {
        await _workoutSetDao.updateOrder(id, -(index + 1), txn);
      }
      for (final (index, id) in orderedIds.indexed) {
        await _workoutSetDao.updateOrder(id, index, txn);
      }
      return workoutExercise?.workoutId;
    });
    if (workoutId != null) {
      await _notifyActiveWorkoutChanged(workoutId);
    }
  }

  @override
  Future<DateTime?> getLastCompletedSetTime(String workoutExerciseId) async {
    return await _workoutSetDao.getLastCompletedAt(workoutExerciseId);
  }

  Future<void> _notifyActiveWorkoutChanged(String workoutId) async {
    final active = await getActiveWorkout();
    if (active == null) {
      _activeWorkoutSubject.add(null);
      return;
    }
    if (active.workout.id == workoutId) {
      _activeWorkoutSubject.add(active);
    }
  }
}
