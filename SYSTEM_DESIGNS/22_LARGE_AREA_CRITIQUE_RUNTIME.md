# Tick Survival Lab — System 22 Large-Area DEV Critique Runtime

Status: **IMPLEMENTED**

Date: 2026-08-20

## 1. Goal

Make the current System 20 Rural Crossroads candidate inspectable and playable through the existing canonical WHAT/WHEN/render/movement/door stack without moving planning, camera math, or simulation rules into a monolith.

The live critique runtime shows the real generated 256×256 area using only the existing System 19 building library, with System 21 centered on the player by default and usable for detached inspection.

System 22 was first implemented against Rural Crossroads Candidate 001. It intentionally consumes the current System 20 plan through public contracts, so Candidate 002 road/vegetation changes require no System 22 architecture change.

## 2. Non-goals

System 22 does not own:

- System 20 road/parcel/building selection/environment rules;
- System 19 building geometry/interiors;
- camera modes/zoom values/input semantics;
- rendering/art selection;
- movement/collision/door gameplay rules;
- save files or long-term streaming partition architecture;
- new building profiles, actors, loot, vehicles, outbreak content, weather, lighting or sound.

It is explicitly a DEV critique/runtime composition layer for validating an already-approved generated area.

## 3. Related System 20 materialization slice

System 20 owns `AreaMaterializationCoordinator.gd` separately from System 22.

The coordinator:

1. validates the complete `GeneratedAreaPlan`;
2. regenerates and validates all public System 19 subplans from stored `BuildingGenerationRequest`s;
3. preflights stable IDs / initial conflicts;
4. snapshots WHAT + Door State;
5. writes area terrain by ground-region priority;
6. writes outdoor semantic props;
7. materializes each System 19 building through `GeneratedBuildingMaterializer` so building floors override property/road base terrain and all doors initialize CLOSED;
8. rolls back the whole operation on any failure;
9. relinquishes ownership after success.

No runtime regeneration of mutated worlds is introduced.

## 4. Owners

### System 20

`game/scripts/generation/areas/AreaMaterializationCoordinator.gd`

Transactional initial WHAT + Door State write path only.

### System 22

`game/scripts/demo/RuralCrossroadsCritiqueFixture.gd`

DEV integration fixture:

- generates the current Rural Crossroads candidate through `LocalAreaGenerator`;
- materializes through `AreaMaterializationCoordinator`;
- registers exact current critique-content collision/traversal semantics from generated public plans;
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

The renderer draws a smaller bounded window around the camera for mobile performance:

- 24 px per tactical cell at System 21 Normal zoom;
- an 80×96-cell render window;
- a safety buffer before the visible window is recentered.

Changing the render window must never change the global pixel location of a world cell. `WorldView.position` is translated by the render-origin offset so:

`global_pixel(cell) = base_pixel_origin + (cell - area_bounds.position) * cell_pixels`

remains invariant.

Therefore detached camera positions remain stable while renderer windows shift.

## 6. Player start

The DEV player starts one cell outside the generated Rural Diner primary exterior door, facing the door. The start is derived from public parcel/building-entry/frontage facts rather than a duplicated authored coordinate.

This gives immediate proof that:

- System 20 placement is real;
- System 19 diner geometry is real;
- System 18 automatic door passage still works inside the area;
- the player can leave and explore the same persistent WHAT world.

## 7. Camera/UI behavior

System 21 remains authoritative:

- player-follow default;
- five existing zoom levels unchanged;
- detached two-finger/middle-drag inspection;
- CENTER returns to player follow;
- future focus/scripted seams unchanged.

The explicit camera control strip remains screen-space UI.

Safari phone controls use direct touch-release activation plus synthetic-mouse suppression. CENTER visibly reports FOLLOW/INSPECT state and reliably calls `recenter_player()` from detached/focus modes.

## 8. Performance

- no 256×256 draw scan per frame;
- only the bounded renderer window is planned/drawn;
- System 20 generation/materialization occurs once at critique startup;
- camera movement may shift the renderer window only when it crosses the configured buffer threshold;
- no simulation polling loop is added.

System 20 may increase semantic outdoor content (for example Candidate 002 vegetation) without changing the System 22 window contract; only entities inside the active renderer window are drawn.

## 9. Verification

Dedicated integration smoke proves:

1. the current Rural Crossroads plan generates and materializes into WHAT successfully;
2. all 12 existing-library building requests materialize and their doors are enrolled CLOSED;
3. roads/driveways/fields/outdoor props exist in WHAT;
4. player start is derived outside the generated diner door and is traversable;
5. System 18 can open/enter that diner door in the area world;
6. render window is bounded smaller than 256×256;
7. shifting render origin preserves world-cell global pixel coordinates;
8. detached pan can shift the render window without moving the player;
9. CENTER returns to player follow;
10. explicit touch CENTER emits exactly one recenter request under Safari-style touch + synthetic-mouse delivery;
11. System 19, System 20, System 21, startup, Web export and Pages remain green.

Dedicated workflow: `.github/workflows/large-area-critique.yml`.
Exact-head context: `verify/system22-area-critique`.

## 10. North-star fit

The generated countryside is one playable continuous world rather than isolated critique buildings. System 22 validates the open-world hierarchy using real persistent WHAT and existing gameplay systems while preserving generation/render/camera replaceability.

## 11. Approved decisions

On 2026-08-20 the user explicitly requested: **“Ok lets put it all together, that was still the diner. Also on safari the center button doesn't do anything.”**

That approved the large-area critique integration and Safari CENTER correction. Later System 20 candidate revisions are consumed through the same public plan/materialization contracts and do not reopen System 22 unless the viewer contract itself proves insufficient.
