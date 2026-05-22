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

- **Last updated**: 2026-05-22
- **Active area**: Home dashboard visual redesign + docs sync
- **Immediate next action**: Visual QA pass on device sizes and optional micro-polish

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

1. **UI-QA1 - Home visual QA** - check 320dp phone and tablet for text/chip overflow and spacing consistency.
2. **TST1 - Refresh widget test** - replace default counter smoke test with an app-appropriate Home/shell smoke test.
3. **S3 - Shared widgets** - evaluate whether Home card primitives should be extracted only if reuse appears in other features.
4. **C6 - Database migrations** - add an `onUpgrade` path before any future schema version bump.
