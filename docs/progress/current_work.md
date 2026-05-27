# Current Work - In Progress

<!--
FORMAT:
    ## Active Item: <Name> (TASK_ID)

    **Status**: In Progress | Proposed | Blocked

    ### Problem
    One sentence.

    ### Agreed Approach
    1. step

    ### Files
    - `path/to/file.dart` - new | modify

    ### Out of Scope
    - item

    ## Up next

    N. **TASK_ID - Name** - one-line description; depends on XX if applicable
-->

## Session Context

- **Last updated**: 2026-05-26
- **Active area**: Cross-tab UX motion/feedback polish (UI-only) + widget test refresh + docs sync
- **Immediate next action**: Manual QA on Android/iOS/desktop with reduced-motion and performance checks

---

## Active Item: UX Motion And Feedback Polish (UI-MOTION-2026-05-26)

**Status**: Completed

### Problem
Core user flows worked correctly but completion actions felt static, causing lower perceived responsiveness.

### Agreed Approach
1. Introduce shared UI-only primitives for motion and haptic feedback without changing business logic.
2. Apply micro-interactions to high-frequency surfaces across Home, Workout, and Profile.
3. Respect reduced-motion accessibility by disabling animation/haptics when `MediaQuery.disableAnimations` is enabled.
4. Refresh widget tests to validate shell smoke and key UX state transitions.

### Files
- `lib/common/widgets/motion_tokens.dart` - new
- `lib/common/widgets/app_haptics.dart` - new
- `lib/common/widgets/tap_scale.dart` - new
- `lib/common/widgets/success_pulse_overlay.dart` - new
- `lib/common/widgets/animated_metric_bar.dart` - new
- `lib/features/workout/presentation/active_workout_screen.dart` - modify
- `lib/features/workout/presentation/create_routine_screen.dart` - modify
- `lib/features/workout/presentation/workout_home_screen.dart` - modify
- `lib/features/workout/presentation/routine_detail_screen.dart` - modify
- `lib/features/home/presentation/home_dashboard_screen.dart` - modify
- `lib/features/profile/presentation/profile_home_screen.dart` - modify
- `lib/features/profile/presentation/measures_screen.dart` - modify
- `lib/features/profile/presentation/statistics_screen.dart` - modify
- `lib/features/profile/presentation/muscle_map_screen.dart` - modify
- `test/widget_test.dart` - modify
- `docs/architecture/features_architecture.md` - modify
- `docs/architecture/general_architecture.md` - modify
- `docs/progress/todo.md` - modify
- `docs/progress/current_work.md` - modify
- `docs/progress/progress_log.md` - append

### Out of Scope
- Changes to repository/DAO/service/business behavior
- Route contracts and model schemas
- Adding third-party animation or haptic packages
- Audio/confetti or copywriting changes

---

## Active Item: Home Dashboard UI Redesign (UI-HOME-2026-05-22)

**Status**: Completed

### Problem
Home dashboard visual hierarchy no longer matched the desired reference style (dark, compact, card-based), even though the existing business logic and data model were correct.

### Agreed Approach
1. Rebuild Home tab body UI with section-oriented cards and consistent visual tokens.
2. Keep all existing `HomeDashboardCubit` action flows and navigation behavior unchanged.
3. Add lightweight section-level animation only in presentation layer.
4. Update docs to capture the redesign scope and no-logic-change guarantee.

### Files
- `lib/features/home/presentation/home_dashboard_screen.dart` - modify
- `README.md` - modify
- `docs/architecture/features_architecture.md` - modify
- `docs/architecture/general_architecture.md` - modify
- `docs/progress/todo.md` - modify
- `docs/progress/current_work.md` - modify
- `docs/progress/progress_log.md` - append

### Out of Scope
- Changes to repository/service/data/business logic
- Navigation route contracts
- Theme-wide refactor beyond Home screen file-local tokens
- Fixing tests
- Schema/data migrations

---

## Up Next

1. **QA-UX1 - Cross-device UX QA** - verify motion timing and completion feedback quality on Android/iOS/desktop.
2. **QA-ANR1 - Emulator performance pass** - inspect ANR/skip-frame reports and compare emulator vs physical-device behavior.
3. **C6 - Database migrations** - add an `onUpgrade` path before any future schema version bump.
