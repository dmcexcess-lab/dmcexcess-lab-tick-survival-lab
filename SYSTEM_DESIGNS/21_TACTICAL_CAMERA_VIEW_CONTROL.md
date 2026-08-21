# Tick Survival Lab — System 21 Tactical Camera / View Control

Status: **APPROVED — implementation authorized**

Date: 2026-08-20

## 1. Goal

Own tactical camera presentation independently from simulation, rendering, generation and player movement.

Normal gameplay keeps the camera centered on the controlled survivor. The same camera must also support temporary detached inspection and future cutscene/reveal focus without moving the survivor or changing world truth.

## 2. Non-goals

System 21 does **not** own:

- player/world movement or facing;
- WHAT placement truth;
- WHEN/tick advancement or pause policy;
- tactical map rendering or art selection;
- System 19/20 generation;
- streaming/materialization;
- cutscene scripting/story sequencing;
- world bounds/clamping policy;
- large-area DEV viewer composition.

A future viewer/cutscene system may command this camera only through its public presentation API.

## 3. Owners

- `camera/TacticalCameraState.gd` — camera mode/target/zoom state and one-level restore snapshot.
- `camera/ZoomController.gd` — five discrete named zoom presets and clamped step logic.
- `camera/TacticalCameraController.gd` — owns `Camera2D` presentation, follows/focuses world placements, pans, recenters and performs optional scripted presentation tweens.
- `input/CameraInputAdapter.gd` — converts desktop/touch gestures into semantic camera requests only.
- `ui/CameraControls.gd` — phone-friendly zoom-out / center / zoom-in controls and current camera presentation label.

`CanonicalDemoMain.gd` remains composition only and wires signals/dependencies.

## 4. Public modes

`TacticalCameraState` exposes these presentation modes:

1. `FOLLOW_PLAYER` — default normal gameplay mode. Camera follows the configured controlled actor placement.
2. `DETACHED` — manual inspection/pan mode. Player movement does not pull the camera back until recenter is requested.
3. `FOCUS_CELL` — camera is centered on a specified world cell.
4. `FOCUS_ACTOR` — camera follows another placed actor/entity without changing control ownership.
5. `SCRIPTED` — temporary presentation transition toward a cell/actor target. Simulation truth remains untouched.

A focus/scripted command may remember the previous camera state. `restore_previous()` returns to that state; if none exists, it safely returns to `FOLLOW_PLAYER`.

## 5. Five zoom levels

Zoom is discrete, never arbitrary persistent state:

| Level | Label | Camera2D zoom |
|---:|---|---:|
| 0 | Very Close | 1.75× |
| 1 | Close | 1.35× |
| 2 | Normal | 1.00× |
| 3 | Far | 0.75× |
| 4 | Area | 0.50× |

`Normal` / level 2 is the default.

Zoom in steps toward level 0; zoom out steps toward level 4. Attempts beyond either limit are harmless no-ops.

The exact numeric preset table is System 21 presentation policy. Gameplay/generation/render code must never branch on these values.

## 6. Spatial presentation contract

The controller is configured with:

- public `WorldState` read access;
- controlled actor stable ID;
- a `Camera2D` node;
- the rendered world-view `Node2D`;
- current render-window global cell origin;
- pixels per tactical cell.

World cell -> rendered pixel center is derived only from those presentation facts. System 21 never changes the actor placement to center the view.

For the current small canonical demo the renderer still draws its complete fixture window. A future System 20 large-area critique viewer may update the renderer's visible-window contract separately and then call System 21's render-window configuration seam. Camera implementation must not make the renderer or System 20 depend on camera internals.

## 7. Follow / focus behavior

### Follow player

- default after configure;
- centers immediately on the controlled actor;
- reacts when that actor's WHAT placement changes;
- retains current zoom level while following.

### Detached inspection

- any manual pan enters `DETACHED`;
- pan is expressed as screen-pixel delta and converted using current zoom;
- detached inspection changes no simulation state;
- `recenter_player()` immediately returns to `FOLLOW_PLAYER`.

### Focus target

- `focus_cell(cell)` centers a world cell;
- `focus_actor(entity_id)` follows another currently placed entity;
- optional zoom override uses one of the same five discrete levels;
- focus mode remains presentation-only.

### Scripted presentation

The controller exposes a small future-cutscene seam to tween camera position/zoom toward a cell or actor using wall-clock presentation time. The tween does not advance WHEN and must be safe while simulation is tactically or hard paused.

After the transition, the camera remains focused on the requested target until another command or restore/recenter occurs.

## 8. Input contract

`CameraInputAdapter` emits requests only:

- `zoom_in_requested`;
- `zoom_out_requested`;
- `pan_requested(screen_delta)`;
- `recenter_requested`.

Desktop baseline:

- mouse wheel: discrete zoom steps;
- middle/right mouse drag: detached pan;
- `Home`: recenter;
- `[` / `]` also provide keyboard zoom-out / zoom-in.

Touch/mobile baseline:

- two-finger pinch accumulates until a discrete zoom threshold is crossed, then emits exactly one zoom step and resets its accumulator;
- two-finger centroid drag emits pan requests;
- one-finger gameplay touches are not consumed by System 21;
- explicit CanvasLayer buttons provide reliable zoom-out / CENTER / zoom-in access without relying on gestures.

When an existing modal player shell blocks interaction, composition disables the camera input/buttons along with gameplay inputs.

## 9. Data ownership / dependencies

Allowed dependencies:

- `WorldState` public reads / placement change signal;
- `WorldPlacement` public copies;
- Godot presentation types (`Camera2D`, `Node2D`, `Tween`, input events);
- camera-owned state/zoom modules.

Forbidden dependencies:

- mutation services;
- movement/action controllers;
- generator internals;
- renderer internals/art catalogs;
- door/inventory/health logic;
- camera logic inside `Main`.

## 10. Performance

- no world scan;
- follow/focus reacts to relevant placement changes rather than polling every cell every frame;
- `_process`/Tween work is permitted only while a scripted presentation transition is active;
- normal idle follow performs no simulation work.

## 11. Failure behavior

- missing/invalid configure dependency -> configure fails without becoming current camera;
- controlled actor missing/unplaced -> follow/recenter fails safely without mutating world;
- focus actor missing/unplaced -> request fails and existing camera state remains;
- invalid zoom level -> rejected/clamped through `ZoomController` contract;
- canceled/interrupted tween -> next explicit camera command wins;
- restore with no remembered state -> `FOLLOW_PLAYER`.

## 12. Verification / acceptance criteria

Dedicated camera smoke must prove:

1. five exact zoom levels/names and Normal default;
2. zoom step boundaries are deterministic;
3. controller config centers on controlled actor without changing WHAT;
4. actor placement change moves camera only in `FOLLOW_PLAYER`;
5. manual pan enters `DETACHED` and subsequent actor motion does not recenter it;
6. `recenter_player()` returns to player follow;
7. cell focus and actor focus work and do not change player placement;
8. actor focus follows its target placement;
9. previous-state restore returns to the earlier mode/zoom/target;
10. scripted focus completes at requested target/zoom without advancing WHEN;
11. input adapter ignores one-finger touch while supporting two-finger pan/pinch requests;
12. canonical demo boots with Camera2D current and Normal default;
13. existing System 19, System 20 and Pages/startup regressions remain green.

## 13. Future extension seams

Without changing System 21 ownership, future systems may add:

- cutscene/reveal sequencing using focus/scripted/restore calls;
- large-area DEV inspection using detached pan + Area zoom;
- camera bounds/clamping supplied by a viewer/world-presentation owner;
- smooth player-follow presentation if later desired;
- screen shake as a presentation effect layered around the camera target;
- viewport-cell calculation for streaming/visible-window orchestration, owned outside simulation/generation.

## 14. North-star fit

A player-centered tactical camera preserves the readable Ultima-like presentation while discrete zoom and inspection make a continuous open world practical on phone and desktop. The cutscene seam adds presentation flexibility without letting camera state become simulation truth.

## 15. User-approved decisions — 2026-08-20

The user explicitly approved:

- camera centered on the player by default;
- camera architecture reusable for possible future cutscenes;
- five zoom levels rather than three;
- the described follow / detached inspect / focus target / scripted move / restore model;
- desktop wheel and mobile pinch snapping to discrete levels;
- recenter behavior returning to player-follow.
