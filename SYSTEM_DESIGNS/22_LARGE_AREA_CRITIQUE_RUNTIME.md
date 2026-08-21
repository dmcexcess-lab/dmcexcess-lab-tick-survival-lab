# Tick Survival Lab — System 22 Large-Area DEV Critique Runtime

Status: **IMPLEMENTED — canonical rural crossroads critique runtime**

Date: 2026-08-20

## 1. Goal

Make the implemented System 20 `rural.crossroads + temperate.rural` Candidate 001 inspectable and playable through the existing canonical WHAT/WHEN/render/movement/door stack without moving planning, camera math, or simulation rules into a monolith.

The live critique runtime shows the real generated 256×256 area using only the existing System 19 building library, with System 21 centered on the player by default and usable for detached inspection.

## 2. Non-goals

System 22 does not own:

- System 20 road/parcel/building selection rules;
- System 19 building geometry/interiors;
- camera modes/zoom values/input semantics;
- rendering/art selection;
- movement/collision/door gameplay rules;
- save files or long-term streaming partition architecture;
- new building profiles, actors, loot, vehicles, outbreak content, weather, lighting or sound.

It is explicitly a DEV critique/runtime composition layer for validating the already-approved generated area.

## 3. Related System 20 materialization slice

System 20 now owns `AreaMaterializationCoordinator.gd` as the separate one-time initial write transaction.

The coordinator:

1. validates the complete `GeneratedAreaPlan`;
2. regenerates and validates all public System 19 subplans from stored `BuildingGenerationRequest`s;
3. preflights stable IDs;
4. snapshots WHAT + Door State;
5. writes area terrain by ground-region priority;
6. writes outdoor semantic props;
7. materializes each System 19 building through `GeneratedBuildingMaterializer`, including CLOSED initial doors;
8. rolls back the whole operation on any failure;
9. relinquishes ownership after success.

No runtime regeneration of mutated worlds is introduced.

## 4. Implemented owners

### System 20

`game/scripts/generation/areas/AreaMaterializationCoordinator.gd`

Transactional initial WHAT + Door State write path only.

### System 22

`game/scripts/demo/RuralCrossroadsCritiqueFixture.gd`

DEV integration fixture:

- generates Candidate 001 through `LocalAreaGenerator`;
- materializes through `AreaMaterializationCoordinator`;
- derives the current critique collision/traversal registration from public generated plan semantics and explicit System 19 prop blocking facts;
- places the canonical player just outside the generated diner primary entrance.

`game/scripts/view/LargeAreaRenderWindowController.gd`

Presentation orchestration only:

- owns the current bounded renderer window inside the 256×256 logical area;
- listens to System 21 camera presentation changes;
- shifts the renderer window when the camera approaches its buffer edge;
- repositions `WorldView` so global cell -> global pixel mapping stays invariant when the renderer window shifts;
- updates System 21 render-window facts and the camera-aware door pointer;
- never changes WHAT or camera mode/zoom policy.

## 5. Render-window contract

The logical area remains 256×256 cells.

Candidate 001 presentation uses:

- 24 px per tactical cell at System 21 Normal zoom;
- an 80×96-cell bounded render window;
- a 12-cell safety buffer before the presentation window recenters.

Changing render origin never changes the global pixel location of a world cell. `WorldView.position` is translated by the render-origin offset so:

`global_pixel(cell) = base_pixel_origin + (cell - area_bounds.position) * cell_pixels`

remains invariant.

Therefore detached camera position and logical world position remain stable while presentation windows shift.

## 6. Player start

The DEV player starts one cell outside the generated Rural Diner primary exterior door, facing that door. The start is derived from public parcel/building-entry/frontage facts rather than a duplicated authored coordinate.

This immediately proves that System 20 placement, System 19 building geometry, System 18 door passage and normal movement operate in the same materialized area world.

## 7. Camera/UI behavior

System 21 remains authoritative:

- player-follow default;
- five existing zoom levels unchanged;
- detached two-finger/middle-drag inspection;
- CENTER returns to player follow;
- future focus/scripted seams unchanged.

The explicit camera controls remain screen-space UI.

### Safari CENTER correction

`CameraControls.gd` now owns a deterministic `dispatch_control_event()` activation contract shared by the real button `gui_input` path and CI.

- touch **release** activates the requested camera action immediately;
- that touch opens a 500 ms synthetic-mouse suppression window;
- Safari's immediate synthetic left-mouse release is consumed without emitting a duplicate action;
- CENTER visibly reports camera mode (`FOLLOW`, `INSPECT`, etc.) rather than only repeating zoom information;
- CENTER from detached/focus state emits one recenter request and System 21 returns to `FOLLOW_PLAYER`.

This avoids depending on browser-specific Button `pressed` synthesis for critical phone camera control.

## 8. Performance

- no 256×256 renderer scan every frame;
- only the bounded 80×96 presentation window is planned/drawn;
- System 20 generation/materialization occurs once at critique startup;
- render-window shifts occur only near the safety edge;
- no simulation polling loop is added.

## 9. Verification contract

`LargeAreaCritiqueRuntimeSmoke.gd` proves:

1. Candidate 001 generates and materializes into WHAT successfully;
2. all 12 existing-library building requests materialize and their doors are enrolled CLOSED;
3. roads/driveways/fields/outdoor props exist in WHAT;
4. player start is derived outside the generated diner door;
5. System 18 opens/enters that diner door in the area world;
6. render window is bounded smaller than 256×256;
7. shifting render origin preserves world-cell global pixel coordinates;
8. detached pan can shift the render window without moving the player;
9. CENTER returns to player follow;
10. direct Safari-style touch release emits one CENTER action and its synthetic mouse release emits no duplicate;
11. System 20 pure planning and System 21 camera regressions remain green;
12. canonical generated-area startup remains green.

Dedicated workflow: `.github/workflows/large-area-critique-runtime.yml`.
Exact-head context: `verify/system22-area-critique`.

The normal Pages workflow separately protects canonical integration/startup, Web export and deployment.

## 10. North-star fit

This is the first point where the generated local countryside becomes one playable continuous world instead of isolated critique buildings. It validates the open-world hierarchy using real persistent WHAT and existing gameplay systems while preserving generation/render/camera replaceability.

## 11. Approved decisions

On 2026-08-20 the user explicitly requested: **“Ok lets put it all together, that was still the diner. Also on safari the center button doesn't do anything.”**

That approved the previously described large-area critique integration and required the Safari CENTER defect to be corrected in the same bounded integration pass.
