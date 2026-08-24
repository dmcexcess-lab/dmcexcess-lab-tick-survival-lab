# Tick Survival Lab — System 23 Perception / LOS / Fog Memory

Status: **IMPLEMENTED — Candidate 001 + ambient remembered shading + auditory presentation**

System 23 owns visual perception, observer-specific visual knowledge and the presentation layer that enforces it.

Core visual rule:

> **Black = I know nothing. Dark = I remember this place. Full = I can see what is actually happening now.**

Auditory information is orthogonal:

> **Fog limits sight, not hearing.**

Exact-head context: `verify/system23-perception`.

## 1. Ownership

System 23 owns:

- deterministic observer LOS / visible-cell queries;
- `UNSEEN / REMEMBERED / VISIBLE` visual knowledge classification;
- observer-keyed stale environmental memory;
- stale last-seen living-actor observations;
- fog/memory presentation masking/redrawing;
- presentation-only ambient input for remembered shading;
- drawing supplied auditory descriptors above visual fog/memory.

System 23 reads but does not own WHAT placements/terrain, Door State, Art Catalog, System 25 ambient daylight, or System 26 auditory descriptors.

System 23 does **not** create/propagate/localize sound, decide AI hearing, own world time/weather, mutate gameplay truth or poll hidden WHAT for remembered content.

## 2. Candidate 001 LOS

- four-way facing;
- maximum range 12 cells;
- 120-degree forward cone;
- radius-1 all-around near awareness;
- deterministic integer tracing;
- walls and CLOSED doors block;
- OPEN doors and windows transmit;
- malformed/unknown structure opacity fails closed.

Visual opacity remains independent from Collision and acoustic transmission.

## 3. Visual knowledge states

### `UNSEEN`

- never visually observed;
- fully opaque black at every time of day;
- no terrain/current world truth is shown.

### `REMEMBERED`

- previously observed but not currently visible;
- renders stale stored observation only;
- hidden current WHAT is never queried to correct it.

### `VISIBLE`

- currently inside live LOS;
- normal live renderers show current truth;
- environmental memory refreshes from what is actually observed.

Precedence: `VISIBLE > REMEMBERED > UNSEEN`.

## 4. Environmental memory

Per observer/cell, Candidate 001 remembers:

- global cell and observed tick;
- terrain semantic;
- structure semantic/axis and observed door state;
- anchored static `prop.*` / `fixture.*` furniture/clutter with stable ID, semantic, anchor and facing.

Hidden movement/removal/state changes remain stale until re-observation. Seeing the cell again refreshes or clears the stored snapshot.

Perception-memory snapshot schema: **v2**.

Loose items, vehicles and vegetation are not currently copied into environmental memory.

## 5. Last-seen living actors

Living actors use separate stale observations. A last-seen marker is an observer memory, not hidden tracking. Hidden movement/death does not update it until new visual information contradicts or refreshes the observation.

## 6. Ambient-responsive remembered presentation

System 23 exposes:

`set_ambient_light_level(level_0_to_1)`

The canonical provider is System 25 `OutdoorAmbientLightService`.

Candidate environmental-memory luminance:

- ambient `1.0` -> `0.30`;
- ambient `0.0` -> `0.10`;
- interpolate between.

System 25 night ambient `0.08` therefore gives remembered luminance ~= `0.116`.

Ambient changes presentation only. They never mutate memory, LOS, WHAT or exploration state. UNSEEN remains black.

## 7. Live System 26 auditory presentation

System 26 now generates real listener-specific auditory observations. System 23 receives only observer-facing descriptors such as:

- perceived cell;
- yellow display word;
- perceived strength/certainty;
- category/timing metadata.

System 23 never receives/needs the exact hidden physical source coordinate to draw the cue.

Yellow words may appear above:

- VISIBLE terrain;
- REMEMBERED terrain;
- completely black UNSEEN space.

They never:

- reveal the terrain beneath them;
- mark a cell visually explored;
- refresh environmental memory;
- create a last-seen actor record;
- reveal a hidden actor/entity sprite.

Current words include `NOISE`, `MOVEMENT`, `FOOTSTEPS`, `IMPACT` and `THUD`. Off-screen cues clamp to the viewport edge from the **perceived** position supplied by System 26.

The old synthetic crosshair is no longer the live Candidate 001 presentation; the overlay now draws textual auditory cues. The descriptor API remains tolerant of older test descriptors so System 23's independent layering contract stays regression-tested.

## 8. Presentation architecture

Canonical draw order:

1. live Ground / Structure / Prop / Actor layers render current truth;
2. Perception overlay masks every non-VISIBLE cell black;
3. REMEMBERED cells redraw stored environmental snapshots above black;
4. stale last-seen actor observations draw above remembered environment;
5. supplied auditory yellow words draw above all visual knowledge states.

The overlay never asks hidden WHAT what should be visible in memory or what produced a sound.

## 9. Time / performance

Perception recomputation is event-driven and consumes zero WHEN ticks. There is no per-frame FOV scan.

Ambient changes are scalar redraws. Auditory observation creation/aging belongs to System 26; System 23 merely redraws the currently supplied descriptors.

The bounded repeated-FOV benchmark remains part of the System 23 contract.

## 10. Persistence boundary

System 23 owns deterministic visual perception-memory snapshot data but not save-file orchestration. Restoring observer memory must not silently reconcile it against hidden current WHAT.

System 26 separately owns snapshot-capable active auditory listener observations; they are not embedded into System 23 visual-memory schema.

## 11. Verification

Dedicated workflow: `.github/workflows/perception.yml`.

Primary smoke: `game/scripts/ci/PerceptionFogMemorySmoke.gd`.

Ambient smoke: `game/scripts/ci/PerceptionAmbientMemorySmoke.gd`.

Coverage includes LOS geometry/opacity, true-black UNSEEN, stale remembered environment/static furniture, re-observation refresh, stale actors, deterministic schema-v2 restore, zero tick use, auditory layering without exploration, and ambient remembered shading.

System 26 separately proves real sound propagation/hearing/localization and live yellow-word integration.

First green remembered-furniture head: `a08ccf8064f318e283acab6a3f73aa10e59f2acf`.

First green ambient-memory head: `6b6680c5b8eb4d8db2c4097df093abace661d5c7`.

First green live spatial-sound integration head: `2d3dcfa6fc8646cda62a5e775beb1ac7c8d04d08`.

## 12. Future seams

- visible-world physical lighting / darkness-dependent visual range;
- weather/fog/smoke visual attenuation;
- vegetation/vehicle visual opacity;
- observer visual-skill/status modifiers;
- AI visual use;
- remembered loose items/vehicles/vegetation;
- shared survivor knowledge;
- memory age/uncertainty;
- richer window state/damage.

System 26 owns future sound/hearing extensions; they must not weaken System 23's rule that remembered visual knowledge is stale observer knowledge, not hidden-current-world polling.
