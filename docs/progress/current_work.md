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
- **Active area**: Documentation refresh only
- **Immediate next action**: After docs, run a codegen/test follow-up before any feature work

---

## Active Item: Documentation Sync (DOCS-2026-05-22)

**Status**: Completed

### Problem
README and docs still described the project as data-layer-only, while the app now includes shell navigation, dashboards, routine/workout flows, exercise library, profile surfaces, notifications, and measurements.

### Agreed Approach
1. Update README with the current app surface, setup commands, stack, and docs map.
2. Refresh architecture docs to describe the current package layout, navigation, DI, services, and feature surfaces.
3. Refresh progress docs to distinguish completed presentation work from remaining engineering follow-ups.
4. Do not edit core app code, generated code, assets, platform folders, or tests during this pass.

### Files
- `README.md` - modify
- `docs/architecture/general_architecture.md` - modify
- `docs/architecture/features_architecture.md` - modify
- `docs/architecture/database_and_models.md` - modify
- `docs/technical/technical_reference.md` - modify
- `docs/progress/todo.md` - modify
- `docs/progress/progress_log.md` - append
- `docs/progress/current_work.md` - modify

### Out of Scope
- Core source changes under `lib/`
- Regenerating `getit_utils.config.dart`
- Fixing tests
- Schema migrations

---

## Up Next

1. **DI1 - Regenerate DI config** - run `dart run build_runner build --delete-conflicting-outputs` after confirming all current injectable annotations should be registered.
2. **TST1 - Refresh widget test** - replace the default counter smoke test with a Gym Tracker smoke test that matches `MainApp`.
3. **C6 - Database migrations** - add an `onUpgrade` path before any future schema version bump.
4. **S3 - Shared widgets** - extract repeated UI pieces only after duplication is clear across features.
5. **UX1 - Theme polish** - expand the current dark Material 3 seed theme into a fuller app theme if design direction is needed.
