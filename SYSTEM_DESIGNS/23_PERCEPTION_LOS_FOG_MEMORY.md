# Tick Survival Lab — System 23 Perception / LOS / Fog Memory

Status: **IMPLEMENTED — Candidate 001 + ambient remembered shading**

System 23 owns visual perception and observer-specific visual knowledge.

Core player-language rule:

> **Black = I know nothing. Dark = I remember this place. Full = I can see what is actually happening now.**

Auditory information is orthogonal:

> **Fog limits sight, not hearing.**

Exact-head context: `verify/system23-perception`.

## 1. Ownership

System 23 owns:

- deterministic observer LOS / visible-cell queries;
- visual knowledge classification: `UNSEEN`, `REMEMBERED`, `VISIBLE`;
- observer-keyed stale environmental memory;
- stale last-seen living-actor observations;
- presentation masking/redrawing needed to enforce visual knowledge;
- the presentation-only ambient-light input used to shade REMEMBERED environmental snapshots.

System 23 reads but does not own:

- WHAT placements/terrain/current entities;
- Door State;
- Art Catalog / prop orientation;
- current System 25 ambient daylight scalar.

System 23 does **not** own:

- hidden current-world truth;
- movement/collision;
- AI sight decisions beyond the reusable LOS seam;
- sound creation/propagation;
- lighting simulation;
- world time;
- weather;
- save-file orchestration.

## 2. Candidate 001 vision profile

- four-way facing;
- maximum LOS range: **12 cells**;
- forward cone: **120 degrees**;
- radius-1 all-around near awareness.

The profile is explicit configuration rather than hardcoded renderer behavior.

## 3. Occlusion

Candidate 001:

- walls block sight;
- closed doors block sight;
- open doors transmit sight;
- windows transmit sight;
- malformed/unknown structure opacity fails closed.

Occluding cells themselves may be visible; sight does not continue through them.

System 23 does not depend on Collision to decide visual opacity.

## 4. Visual knowledge states

For each observer/cell:

### `UNSEEN`

- no visual knowledge has ever been recorded;
- terrain and all live visual truth are masked by fully opaque black;
- time of day / ambient light never brightens UNSEEN.

### `REMEMBERED`

- the cell was observed previously but is not currently visible;
- presentation uses stale stored observation only;
- hidden current WHAT is never queried to refresh or correct it.

### `VISIBLE`

- the cell is currently in LOS;
- normal live renderers show current truth;
- environmental memory refreshes from what is actually observed now.

## 5. Environmental memory

Per observer/cell, Candidate 001 memory records compact last-observed facts:

- global cell;
- observed world tick;
- terrain semantic;
- structural shell / observed door state when present;
- anchored static `prop.*` / `fixture.*` furniture/clutter observed in the cell.

Remembered static furniture/clutter stores:

- stable entity ID;
- semantic type;
- anchor;
- facing.

Memory snapshot schema: **v2**.

System 23 does not currently snapshot loose items, vehicles or vegetation as environmental memory.

## 6. Stale-memory rule

> **Hidden live changes never update remembered visual truth.**

Examples:

- see a closed door, turn away, door opens -> memory still shows the last-observed closed door;
- see a sofa, turn away, sofa is moved/removed -> memory still shows the stale sofa;
- re-observe the cell -> memory refreshes to current visible truth and stale objects clear/update.

This rule prevents memory from becoming remote surveillance of WHAT.

## 7. Last-seen actors

Living actors use separate stale observations rather than being embedded into environmental snapshots.

A last-seen actor marker is:

- an observation, not a hidden live tracker;
- unchanged by hidden movement/death until new information is acquired;
- visually distinct from current visible actor truth.

## 8. Auditory seam

System 23 may present supplied auditory descriptors over visible, remembered or completely unexplored black fog.

Auditory cues:

- never reveal terrain beneath themselves;
- never mark a cell visually explored;
- do not imply exact hidden visual truth.

A future Spatial Sound owner will generate/propagate the events; System 23 only presents the observer-facing result.

## 9. Ambient-responsive REMEMBERED presentation

System 23 exposes a presentation-only seam:

`set_ambient_light_level(level_0_to_1)`

The canonical live provider is System 25 `OutdoorAmbientLightService`.

Ambient light changes **only** the presentational luminance of remembered environmental snapshots. It does not mutate memory records, LOS, WHAT, or exploration state.

Candidate 001 environmental memory luminance:

- ambient `1.0` -> **0.30** luminance (the original daytime remembered appearance);
- ambient `0.0` -> **0.10** luminance;
- values between interpolate linearly.

System 25 Candidate 001 uses an outdoor night baseline of `0.08`, giving remembered luminance ~= `0.116` at deepest baseline night.

Rules:

- UNSEEN stays fully black regardless of ambient level;
- VISIBLE current-world renderers are not globally tinted by System 23;
- memory does not store the historical light level from when the cell was seen;
- current ambient light therefore changes how the same stale snapshot is displayed as day/night changes;
- last-seen actor marker styling remains independently readable;
- auditory cue styling remains independently readable.

This is intentionally simpler and more correct than pretending System 23 owns a full physical lighting model.

## 10. Presentation architecture

Existing Ground / Structure / Prop / Actor renderers remain live-current-truth renderers.

`PerceptionOverlayRenderer` sits above them and:

1. masks all non-visible visual world truth;
2. leaves UNSEEN black;
3. redraws only stored REMEMBERED snapshots over black;
4. redraws remembered static props/fixtures through normal Art Catalog/orientation rules;
5. draws stale actor observations and auditory cues as separate observer-information channels.

The overlay never asks hidden WHAT what should be shown in remembered space.

`TacticalRendererStack` provides the composition seam `set_perception_ambient_light_level()`.

## 11. Time / cost / performance

Perception recomputation is event-driven and consumes **zero WHEN ticks**.

There is no `_process()` / `_physics_process()` FOV scan.

Memory is sparse and observer-keyed. Static remembered objects are compact records. Ambient daylight changes require only a scalar presentation update/redraw, not a world scan or LOS recomputation.

The existing FOV benchmark remains part of the System 23 contract.

## 12. Persistence boundary

System 23 owns deterministic perception-memory snapshot data but not the save file.

Restored memory remains observer knowledge; it must not be silently reconciled against hidden current WHAT during load.

## 13. Verification

Dedicated workflow: `.github/workflows/perception.yml`.

Primary smoke: `game/scripts/ci/PerceptionFogMemorySmoke.gd`.

Ambient presentation smoke: `game/scripts/ci/PerceptionAmbientMemorySmoke.gd`.

Coverage includes:

- LOS cone/range/near awareness;
- closed/open door and wall/window occlusion;
- true-black UNSEEN;
- stale remembered terrain/structure/doors;
- stale static furniture hidden-change behavior and re-observation refresh;
- deterministic schema-v2 snapshot roundtrip;
- last-seen living actor observations;
- auditory descriptors not revealing terrain;
- zero WHEN-tick consumption;
- repeated-FOV performance budget;
- ambient input clamping;
- 0.30 day / 0.20 mid / 0.10 zero-ambient remembered luminance;
- ambient changes never brightening true fog.

The upstream System 25 contract separately proves real tick-to-time/daylight behavior and integration.

First fully green executable head for remembered furniture/clutter: `a08ccf8064f318e283acab6a3f73aa10e59f2acf`.

First fully green executable head with System 25 ambient-responsive remembered presentation: `6b6680c5b8eb4d8db2c4097df093abace661d5c7`.

## 14. Future seams

- weather/fog/smoke attenuation;
- full visible-world ambient/local lighting;
- flashlights/fire/electrical lights;
- vegetation/vehicle visual occlusion;
- observer skill/status modifiers;
- AI LOS use;
- remembered loose items/vehicles/vegetation;
- shared survivor knowledge;
- memory age/uncertainty;
- window state/damage;
- real Spatial Sound.

None of those should weaken the central rule that remembered information is stale observer knowledge, not hidden current truth.
