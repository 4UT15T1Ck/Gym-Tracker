# Progress Log

Append-only. Each entry records what was completed for a task, with a timestamp.
Never edit or delete past entries. Newest entries go at the bottom.

Format:
```
## [TASK_ID] Task Name
**Date**: YYYY-MM-DD
**Files changed**: list of files
- bullet: what was done / added / decided
```

---

## [C1] Database Setup
**Date**: 2026-05-01 (retroactive)
**Files changed**: `core/data/db_module.dart`
- Created DatabaseModule with sqflite, 10 tables, foreign keys enabled
- Added PRAGMA foreign_keys = ON in onConfigure
- Added CHECK constraints for enum columns (tracking_type, status, set_type)

---

## [C3] Seed Data
**Date**: 2026-05-01 (retroactive)
**Files changed**: `core/data/seed_helper.dart`, `assets/seed_data.json`
- Implemented seedDatabaseFromJson() loading muscles, equipment, exercises, and secondary muscles from JSON
- Batch insert with ConflictAlgorithm.replace
- Secondary muscle parsing handles multiple JSON formats (array of strings, array of objects)

---

## [C4] Database Indexes
**Date**: 2026-05-01 (retroactive)
**Files changed**: `core/data/db_module.dart`
- Added standard indexes on foreign key columns
- Added unique composite indexes on (parent_id, order) for all ordered child tables
- Order column quoted as reserved SQL word

---

## [C2] DI Setup
**Date**: 2026-05-01 (retroactive)
**Files changed**: `common/utils/getit_utils.dart`, `common/utils/getit_utils.config.dart`, `core/data/db_module.dart`, `core/data/uuid_module.dart`
- Set up get_it + injectable with @injectableInit entry point
- DatabaseModule as @preResolve @singleton
- UuidModule providing Uuid singleton

---

## [E1–E8] Exercise Library Data Layer
**Date**: 2026-05-01 (retroactive)
**Files changed**: `core/models/exercise_model.dart`, `core/models/muscle_model.dart`, `core/models/equipment_model.dart`, `core/models/exercise_second_muscle_model.dart`, `core/dao/exercise_dao.dart`, `core/dao/muscle_dao.dart`, `core/dao/equipment_dao.dart`, `core/dao/exercise_stats_dao.dart`, `core/repositories/exercise_repository.dart`, `core/repository_impl/exercise_repository_impl.dart`, `core/repositories/repository_models.dart`
- Complete exercise domain models with toMap/fromMap
- Full DAO set including filtered queries and stats
- ExerciseRepositoryImpl assembling ExerciseDetail from multiple DAOs
- ExerciseStats with personal best, history, weight/volume over time

---

## [R1–R6] Routine Data Layer
**Date**: 2026-05-01 (retroactive)
**Files changed**: `core/models/routine_model.dart`, `core/models/routine_exercise_model.dart`, `core/models/routine_set_model.dart`, `core/dao/routine_dao.dart`, `core/dao/routine_exercise_dao.dart`, `core/dao/routine_set_dao.dart`, `core/repositories/routine_repository.dart`, `core/repository_impl/routine_repository_impl.dart`
- Full routine CRUD with transaction management
- Exercise and set add/remove/reorder operations
- Save/draft/copy flows with RoutineInput DTOs
- Sync completed workout sets back to routine template

---

## [W1–W6] Workout Data Layer
**Date**: 2026-05-01 (retroactive)
**Files changed**: `core/models/workout_model.dart`, `core/models/workout_exercise_model.dart`, `core/models/workout_set_model.dart`, `core/dao/workout_dao.dart`, `core/dao/workout_exercise_dao.dart`, `core/dao/workout_set_dao.dart`, `core/repositories/workout_repository.dart`, `core/repository_impl/workout_repository_impl.dart`
- Full workout lifecycle (start, complete, cancel)
- Transaction-based set completion with volume recalculation
- Workout history with paginated summaries and batch exercise name fetching
- Start workout from routine with exercise/set copying

---

## [A1–A3] Analytics Data Layer
**Date**: 2026-05-01 (retroactive)
**Files changed**: `core/dao/analytics_dao.dart`, `core/repositories/analytics_repository.dart`, `core/repository_impl/analytics_repository_impl.dart`
- Volume history, workout frequency (week buckets), muscle group breakdown
- AnalyticsRepositoryImpl with UTC week-bucket calculation

---

## [DOCS] Project Documentation
**Date**: 2026-05-01
**Files changed**: `docs/architecture/general_architecture.md`, `docs/architecture/features_architecture.md`, `docs/architecture/database_and_models.md`, `docs/technical/technical_reference.md`, `docs/progress/todo.md`, `docs/progress/current_work.md`, `docs/progress/progress_log.md`
- Created full project documentation following Agent Rule docs template
- Documented all architecture, features, database schema, technical patterns, and progress

---

## [DOCS-2026-05-22] Documentation Sync
**Date**: 2026-05-22
**Files changed**: `README.md`, `docs/architecture/general_architecture.md`, `docs/architecture/features_architecture.md`, `docs/architecture/database_and_models.md`, `docs/architecture/DATA_ACCESS_LAYER.md`, `docs/technical/technical_reference.md`, `docs/progress/todo.md`, `docs/progress/current_work.md`, `docs/progress/progress_log.md`
- Updated README with current app surface, setup commands, stack, and documentation map
- Refreshed architecture docs for shell navigation, home dashboard, workout/routine flows, exercise library, profile, notifications, preferences, and measurements
- Added `body_measure_entries`, `BodyMeasurementDao`, and `BodyMeasurementRepositoryImpl` to database/DAL docs
- Updated progress docs to show implemented presentation surfaces and remaining engineering follow-ups

---

## [UI-HOME-2026-05-22] Home Dashboard Visual Redesign
**Date**: 2026-05-22
**Files changed**: `lib/features/home/presentation/home_dashboard_screen.dart`, `README.md`, `docs/architecture/features_architecture.md`, `docs/architecture/general_architecture.md`, `docs/progress/todo.md`, `docs/progress/current_work.md`, `docs/progress/progress_log.md`
- Rebuilt Home tab body as dark card-based sections with clearer data hierarchy (header, quick start, week streak, last workout, PRs, recovery)
- Added lightweight section-level entrance animation in presentation layer only
- Kept all existing Home business logic and navigation behavior unchanged (`HomeDashboardCubit`, dashboard service, route flow)
- Synced docs to reflect the visual-only scope and new Home UI structure

---

## [UI-MOTION-2026-05-26] Cross-Tab UX Motion And Feedback Polish
**Date**: 2026-05-26
**Files changed**: `lib/common/widgets/motion_tokens.dart`, `lib/common/widgets/app_haptics.dart`, `lib/common/widgets/tap_scale.dart`, `lib/common/widgets/success_pulse_overlay.dart`, `lib/common/widgets/animated_metric_bar.dart`, `lib/features/workout/presentation/active_workout_screen.dart`, `lib/features/workout/presentation/create_routine_screen.dart`, `lib/features/workout/presentation/workout_home_screen.dart`, `lib/features/workout/presentation/routine_detail_screen.dart`, `lib/features/home/presentation/home_dashboard_screen.dart`, `lib/features/profile/presentation/profile_home_screen.dart`, `lib/features/profile/presentation/measures_screen.dart`, `lib/features/profile/presentation/statistics_screen.dart`, `lib/features/profile/presentation/muscle_map_screen.dart`, `test/widget_test.dart`, `docs/architecture/features_architecture.md`, `docs/architecture/general_architecture.md`, `docs/progress/todo.md`, `docs/progress/current_work.md`, `docs/progress/progress_log.md`
- Added shared UI-only motion/haptic primitives in `common/widgets` with reduced-motion support (`MediaQuery.disableAnimations`).
- Applied completion feedback and micro-interactions across Workout, Home, and Profile surfaces without changing repository/DAO/service behavior.
- Replaced default widget counter test with app-relevant smoke and UX state-transition tests.
- Synced architecture and progress docs to reflect shared widget extraction and updated testing status.
