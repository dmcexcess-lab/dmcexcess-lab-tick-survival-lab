# Tick Survival Lab — System 21 Tactical Camera / View Control

Status: **IMPLEMENTED — exact-head CI contract required**

Date: 2026-08-20

## 1. Goal

Own tactical camera presentation independently from simulation, rendering, generation and player movement.

Normal gameplay keeps the camera centered on the controlled survivor. The same camera also supports temporary detached inspection and future cutscene/reveal focus without moving the survivor or changing world truth.

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
- the large-area DEV viewer itself.

A future viewer/cutscene system commands this camera only through its public presentation API.

## 3. Implemented owners

- `game/scripts/camera/TacticalCameraState.gd` — camera mode/target/zoom state and one-level restore snapshot.
- `game/scripts/camera/ZoomController.gd` — five discrete named zoom presets and clamped step logic.
- `game/scripts/camera/TacticalCameraController.gd` — owns `Camera2D` presentation, follows/focuses WHAT placements, pans, recenters and performs optional scripted presentation tweens.
- `game/scripts/input/CameraInputAdapter.gd` — converts desktop/touch gestures into semantic camera requests only.
- `game/scripts/ui/CameraControls.gd` — phone-friendly zoom-out / CENTER / zoom-in controls and current zoom label.
- `game/scripts/ci/CameraViewControlSmoke.gd` — deterministic contract smoke.

`GameMain.gd` remains composition only: it injects world/view facts and wires camera input/UI signals.

## 4. Public camera modes

`TacticalCameraState` exposes:

1. `FOLLOW_PLAYER` — default normal gameplay mode; follows the configured controlled actor placement.
2. `DETACHED` — manual inspection/pan mode; player movement does not pull the camera back.
3. `FOCUS_CELL` — centers a specified world cell.
4. `FOCUS_ACTOR` — follows another currently placed entity without changing control ownership.
5. `SCRIPTED` — temporary presentation transition toward a cell/actor target.

A focus/scripted command may remember the previous camera state. `restore_previous()` returns to it; if no state is stored, the safe fallback is `FOLLOW_PLAYER`.

## 5. Five zoom levels

Zoom is discrete presentation state:

| Level | Label | Camera2D zoom |
|---:|---|---:|
| 0 | Very Close | 1.75× |
| 1 | Close | 1.35× |
| 2 | Normal | 1.00× |
| 3 | Far | 0.75× |
| 4 | Area | 0.50× |

`Normal` / level 2 is the default.

Zoom in steps toward level 0. Zoom out steps toward level 4. Attempts beyond the ends are harmless no-ops. Gameplay/generation/render code must not branch on these numeric scales.

## 6. Spatial presentation contract

The controller is configured with:

- public `WorldState` read access;
- controlled actor stable ID;
- a `Camera2D` node;
- the rendered world-view `Node2D`;
- current render-window global cell origin;
- pixels per tactical cell.

World cell -> rendered pixel center is derived only from those presentation facts. System 21 never changes actor placement to center the view.

`set_render_window(origin, cell_pixels, world_view)` is the future seam for a large-area viewer whose renderer changes its visible global window. System 21 does not tell the renderer which cells to draw and therefore does not become a streaming/render owner.

## 7. Follow / detached / focus behavior

### Follow player

- default after configure;
- centers immediately on the controlled actor;
- reacts to relevant WHAT placement changes;
- preserves the current discrete zoom level.

### Detached inspection

- any manual pan enters `DETACHED`;
- pan receives screen-pixel delta and converts it using current zoom;
- detached inspection changes no simulation state;
- `recenter_player()` returns immediately to `FOLLOW_PLAYER`.

### Focus target

- `focus_cell(cell)` centers a world cell;
- `focus_actor(entity_id)` follows another placed entity;
- optional zoom override must be one of the same five levels;
- focus never changes player control or placement.

### Scripted presentation

`scripted_focus_cell(...)` and `scripted_focus_actor(...)` tween camera position/zoom using wall-clock presentation time. They never advance WHEN. On completion the camera settles into the corresponding focus mode until another command, restore, or recenter.

This is the reusable seam for future cutscenes, explosions, reveals and similar presentation events; System 21 does not author those sequences.

## 8. Input contract

`CameraInputAdapter` emits only:

- `zoom_in_requested`;
- `zoom_out_requested`;
- `pan_requested(screen_delta)`;
- `recenter_requested`.

Desktop baseline:

- mouse wheel = discrete zoom step;
- **middle mouse drag** = detached pan;
- `Home` = recenter;
- `[` / `]` = zoom-out / zoom-in keyboard convenience.

Right-click remains unclaimed because System 18 reserves it for a future interaction menu.

Touch/mobile baseline:

- two-finger pinch accumulates until a discrete threshold is crossed, emits one zoom step, then resets;
- two-finger centroid drag emits pan;
- one-finger gameplay touches are ignored by the camera gesture adapter;
- explicit `ZOOM - / CENTER / ZOOM +` CanvasLayer buttons provide reliable phone access.

## 9. Door-pointer coexistence

A current `Camera2D` changes the canvas transform, so direct `screen - WorldView.position` pointer math is no longer valid.

`DoorPointerInputAdapter` now converts screen coordinates back through the active viewport canvas transform before mapping to the existing visible cell window. This keeps direct door taps correct at every camera zoom/position without teaching Door Interaction about camera internals.

Touch door selection is also resolved on short-touch release and canceled by drag/multitouch. Therefore the first finger of a two-finger camera gesture cannot accidentally become a door action.

Door legality/timing/state remain unchanged.

## 10. Data ownership / dependencies

Allowed camera dependencies:

- `WorldState` public placement reads and mechanic-agnostic change signal;
- Godot presentation types (`Camera2D`, `Node2D`, `Tween`, input events);
- camera-owned state/zoom modules.

Forbidden camera dependencies:

- mutation services;
- movement/action controllers;
- System 19/20 internals;
- render/art internals;
- door/inventory/health logic;
- implementation inside `Main`.

## 11. Modal / pause interaction

Existing player-shell modal behavior remains authoritative for hard pause. When that shell blocks interaction, composition disables camera input and camera buttons alongside movement/pointer input.

Camera state itself is presentation-only and may remain where it is while simulation is paused.

## 12. Performance

- no world scan;
- follow/focus reacts to relevant placement-change signals rather than polling world cells every frame;
- Tween/frame work exists only during an explicit scripted presentation transition;
- normal idle follow performs no simulation work.

## 13. Failure behavior

- invalid configure dependency -> configure fails and does not become a usable camera;
- controlled actor missing/unplaced -> follow/recenter fails safely;
- focus actor missing/unplaced -> request fails without mutating world;
- invalid zoom -> request rejected by the zoom contract;
- interrupted tween -> latest explicit camera command wins;
- restore with no remembered state -> player follow.

## 14. Verification contract

`CameraViewControlSmoke.gd` proves:

1. exactly five preset levels/names/scales and Normal default;
2. deterministic zoom boundaries;
3. configure centers on controlled actor without changing WHAT;
4. player placement changes move camera only in follow mode;
5. manual pan enters detached mode and ignores later player motion;
6. recenter restores player follow;
7. cell and actor focus do not change player placement;
8. actor focus follows its target placement;
9. previous-state restore restores mode/zoom/target;
10. scripted focus reaches target/zoom while WHEN advances zero ticks;
11. one-finger touch does not become a camera gesture;
12. two-finger drag/pinch emits pan/discrete zoom intent;
13. Door Interaction smoke remains green after pointer transform/touch changes;
14. System 20 planner remains green;
15. canonical demo startup, Web export and Pages deployment remain green.

Dedicated workflow: `.github/workflows/camera-view-control.yml`.

Exact-head status context: `verify/system21-camera-view`.

## 15. Future extension seams

Without changing System 21 ownership, later systems may add:

- cutscene/reveal sequencing using focus/scripted/restore;
- the System 20 large-area DEV viewer using detached pan + Area zoom;
- camera bounds/clamping supplied by a viewer/world-presentation owner;
- optional smooth follow;
- presentation-only screen shake;
- viewport-cell calculation/renderer-window orchestration outside simulation and generation.

## 16. North-star fit

A player-centered tactical camera preserves readable Ultima-like play while discrete zoom and inspection make a continuous open world practical on phone and desktop. Cutscene flexibility is gained without turning camera state into simulation truth.

## 17. Approved decisions — 2026-08-20

The user explicitly approved:

- camera centered on player by default;
- architecture reusable for future cutscenes;
- five zoom levels rather than three;
- follow / detached inspect / focus target / scripted move / restore behavior;
- discrete desktop wheel and mobile pinch zoom;
- recenter returning to player follow.
