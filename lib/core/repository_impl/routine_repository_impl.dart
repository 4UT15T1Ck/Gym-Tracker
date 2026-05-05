import 'package:gym_tracker/core/dao/exercise_dao.dart';
import 'package:gym_tracker/core/dao/routine_dao.dart';
import 'package:gym_tracker/core/dao/routine_exercise_dao.dart';
import 'package:gym_tracker/core/dao/routine_set_dao.dart';
import 'package:gym_tracker/core/dao/workout_dao.dart';
import 'package:gym_tracker/core/dao/workout_exercise_dao.dart';
import 'package:gym_tracker/core/dao/workout_set_dao.dart';
import 'package:gym_tracker/core/enums/set_type_enum.dart';
import 'package:gym_tracker/core/models/routine_exercise_model.dart';
import 'package:gym_tracker/core/models/routine_model.dart';
import 'package:gym_tracker/core/models/routine_set_model.dart';
import 'package:gym_tracker/core/models/workout_set_model.dart';
import 'package:gym_tracker/core/repositories/routine_repository.dart';
import 'package:gym_tracker/core/repositories/repository_models.dart';
import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

@LazySingleton(as: RoutineRepository)
class RoutineRepositoryImpl implements RoutineRepository {
  final RoutineDao _routineDao;
  final RoutineExerciseDao _routineExerciseDao;
  final RoutineSetDao _routineSetDao;
  final ExerciseDao _exerciseDao;
  final WorkoutDao _workoutDao;
  final WorkoutExerciseDao _workoutExerciseDao;
  final WorkoutSetDao _workoutSetDao;
  final Database _db;
  final Uuid _uuid;

  RoutineRepositoryImpl(
    this._routineDao,
    this._routineExerciseDao,
    this._routineSetDao,
    this._exerciseDao,
    this._workoutDao,
    this._workoutExerciseDao,
    this._workoutSetDao,
    this._db,
    this._uuid,
  );

  @override
  Future<List<Routine>> getRoutines() async {
    return await _routineDao.getAll();
  }

  @override
  Future<RoutineDetail> getRoutineDetail(String routineId) async {
    final routine = await _routineDao.getById(routineId);
    if (routine == null) {
      throw Exception('Routine not found: $routineId');
    }

    final routineExercises = await _routineExerciseDao.getByRoutineId(
      routineId,
    );
    final reIds = routineExercises.map((re) => re.id).toList();
    final routineSets = reIds.isEmpty
        ? <RoutineSet>[]
        : await _routineSetDao.getByRoutineExerciseIds(reIds);
    final exerciseIds = routineExercises.map((re) => re.exerciseId).toList();
    final exercises = await _exerciseDao.getByIds(exerciseIds);

    final exerciseMap = {for (var e in exercises) e.id: e};
    final setsByReId = <String, List<RoutineSet>>{};
    for (final set in routineSets) {
      setsByReId.putIfAbsent(set.routineExerciseId, () => []).add(set);
    }

    final exerciseDetails = routineExercises.map((re) {
      final exercise = exerciseMap[re.exerciseId];
      if (exercise == null) {
        throw Exception('Exercise not found: ${re.exerciseId}');
      }
      final sets = setsByReId[re.id] ?? [];
      return RoutineExerciseDetail(
        routineExercise: re,
        exercise: exercise,
        sets: sets,
      );
    }).toList();

    return RoutineDetail(routine: routine, exercises: exerciseDetails);
  }

  @override
  Future<RoutineDetail> saveRoutine(RoutineInput input) async {
    return await _db.transaction((txn) async {
      final routineId = _uuid.v4();
      final routine = Routine(
        id: routineId,
        name: input.name,
        notes: input.notes,
      );
      await _routineDao.insert(routine, txn);

      for (final (index, exerciseInput) in input.exercises.indexed) {
        final reId = _uuid.v4();
        final routineExercise = RoutineExercise(
          id: reId,
          routineId: routineId,
          exerciseId: exerciseInput.exerciseId,
          order: index,
          targetRestSeconds: exerciseInput.targetRestSeconds,
        );
        await _routineExerciseDao.insert(routineExercise, txn);

        for (final (setIndex, setInput) in exerciseInput.sets.indexed) {
          final setId = _uuid.v4();
          final routineSet = RoutineSet(
            id: setId,
            routineExerciseId: reId,
            setType: setInput.setType,
            targetWeight: setInput.targetWeight,
            targetReps: setInput.targetReps,
            targetDurationSeconds: setInput.targetDurationSeconds,
            targetDistance: setInput.targetDistance,
            targetRpe: setInput.targetRpe,
            order: setIndex,
          );
          await _routineSetDao.insert(routineSet, txn);
        }
      }

      return await getRoutineDetail(routineId);
    });
  }

  @override
  Future<RoutineDetail> updateRoutine({
    required String routineId,
    required RoutineInput input,
  }) async {
    return await _db.transaction((txn) async {
      final routine = Routine(
        id: routineId,
        name: input.name,
        notes: input.notes,
      );
      await _routineDao.update(routine, txn);
      await _routineExerciseDao.deleteByRoutineId(routineId, txn);

      for (final (index, exerciseInput) in input.exercises.indexed) {
        final reId = _uuid.v4();
        final routineExercise = RoutineExercise(
          id: reId,
          routineId: routineId,
          exerciseId: exerciseInput.exerciseId,
          order: index,
          targetRestSeconds: exerciseInput.targetRestSeconds,
        );
        await _routineExerciseDao.insert(routineExercise, txn);

        for (final (setIndex, setInput) in exerciseInput.sets.indexed) {
          final setId = _uuid.v4();
          final routineSet = RoutineSet(
            id: setId,
            routineExerciseId: reId,
            setType: setInput.setType,
            targetWeight: setInput.targetWeight,
            targetReps: setInput.targetReps,
            targetDurationSeconds: setInput.targetDurationSeconds,
            targetDistance: setInput.targetDistance,
            targetRpe: setInput.targetRpe,
            order: setIndex,
          );
          await _routineSetDao.insert(routineSet, txn);
        }
      }

      return await getRoutineDetail(routineId);
    });
  }

  @override
  Future<void> deleteRoutine(String routineId) async {
    await _routineDao.delete(routineId, _db);
  }

  @override
  Future<RoutineInput> getRoutineDraft(
    String sourceRoutineId, {
    bool asCopy = false,
  }) async {
    final detail = await getRoutineDetail(sourceRoutineId);
    return RoutineInput(
      name: asCopy ? '${detail.routine.name} Copy' : detail.routine.name,
      notes: detail.routine.notes,
      exercises: detail.exercises.map((ed) {
        return RoutineExerciseInput(
          exerciseId: ed.exercise.id,
          order: ed.routineExercise.order,
          targetRestSeconds: ed.routineExercise.targetRestSeconds,
          sets: ed.sets.map((s) {
            return RoutineSetInput(
              setType: s.setType,
              targetWeight: s.targetWeight,
              targetReps: s.targetReps,
              targetDurationSeconds: s.targetDurationSeconds,
              targetDistance: s.targetDistance,
              targetRpe: s.targetRpe,
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  @override
  Future<RoutineExercise> addExerciseToRoutine({
    required String routineId,
    required String exerciseId,
    int? targetRestSeconds,
  }) async {
    return await _db.transaction((txn) async {
      final maxOrder = await _routineExerciseDao.getMaxOrder(routineId, txn);

      final reId = _uuid.v4();
      final routineExercise = RoutineExercise(
        id: reId,
        routineId: routineId,
        exerciseId: exerciseId,
        order: maxOrder + 1,
        targetRestSeconds: targetRestSeconds,
      );
      await _routineExerciseDao.insert(routineExercise, txn);
      return routineExercise;
    });
  }

  @override
  Future<void> reorderRoutineExercises({
    required String routineId,
    required List<String> orderedIds,
  }) async {
    await _db.transaction((txn) async {
      for (final (index, id) in orderedIds.indexed) {
        await _routineExerciseDao.updateOrder(id, index, txn);
      }
    });
  }

  @override
  Future<void> removeExerciseFromRoutine(String routineExerciseId) async {
    await _routineExerciseDao.delete(routineExerciseId, _db);
  }

  @override
  Future<RoutineSet> addSetToRoutineExercise({
    required String routineExerciseId,
    required SetType setType,
    double? targetWeight,
    int? targetReps,
    int? targetDurationSeconds,
    double? targetDistance,
    double? targetRpe,
  }) async {
    return await _db.transaction((txn) async {
      final maxOrder = await _routineSetDao.getMaxOrder(routineExerciseId, txn);

      final setId = _uuid.v4();
      final routineSet = RoutineSet(
        id: setId,
        routineExerciseId: routineExerciseId,
        setType: setType,
        targetWeight: targetWeight,
        targetReps: targetReps,
        targetDurationSeconds: targetDurationSeconds,
        targetDistance: targetDistance,
        targetRpe: targetRpe,
        order: maxOrder + 1,
      );
      await _routineSetDao.insert(routineSet, txn);
      return routineSet;
    });
  }

  @override
  Future<RoutineSet> updateRoutineSet(RoutineSet set) async {
    await _routineSetDao.update(set, _db);
    return set;
  }

  @override
  Future<void> removeRoutineSet(String routineSetId) async {
    await _routineSetDao.delete(routineSetId, _db);
  }

  @override
  Future<void> reorderRoutineSets({
    required String routineExerciseId,
    required List<String> orderedIds,
  }) async {
    await _db.transaction((txn) async {
      for (final (index, id) in orderedIds.indexed) {
        await _routineSetDao.updateOrder(id, index, txn);
      }
    });
  }

  @override
  Future<void> syncCompletedSetsToRoutine({
    required String workoutId,
    required String routineId,
  }) async {
    final routineDetail = await getRoutineDetail(routineId);
    final workoutDetail = await _getWorkoutDetail(workoutId);

    await _db.transaction((txn) async {
      for (final workoutExerciseDetail in workoutDetail.exercises) {
        final matches = routineDetail.exercises.where(
          (red) => red.exercise.id == workoutExerciseDetail.exercise.id,
        );
        if (matches.isEmpty) continue;
        final matchingRoutineExercise = matches.first;

        for (final (index, workoutSet) in workoutExerciseDetail.sets.indexed) {
          if (!workoutSet.isCompleted) continue;

          if (index < matchingRoutineExercise.sets.length) {
            final routineSet = matchingRoutineExercise.sets[index];
            final updatedSet = RoutineSet(
              id: routineSet.id,
              routineExerciseId: routineSet.routineExerciseId,
              setType: routineSet.setType,
              targetWeight: workoutSet.weight,
              targetReps: workoutSet.reps,
              targetDurationSeconds: workoutSet.durationSeconds,
              targetDistance: workoutSet.distance,
              targetRpe: workoutSet.rpe,
              order: routineSet.order,
            );
            await _routineSetDao.update(updatedSet, txn);
          }
        }
      }
    });
  }

  Future<WorkoutDetail> _getWorkoutDetail(String workoutId) async {
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

    final workout = await _workoutDao.getById(workoutId);
    if (workout == null) {
      throw Exception('Workout not found');
    }

    return WorkoutDetail(
      workout: workout,
      exercises: exerciseDetails,
    );
  }
}
