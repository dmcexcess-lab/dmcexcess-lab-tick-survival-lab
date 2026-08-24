# Tick Survival Lab — System 23 Perception / LOS / Fog Memory

Status: **IMPLEMENTED — Candidate 001**

System 23 is the canonical visual-perception/observer-knowledge system for the playable survival world.

Core player-language rule:

> **Black = I know nothing. Dark = I remember this place. Full = I can see what is actually happening now.**

Auditory information is orthogonal to sight:

> **Fog limits sight, not hearing.**

A future Spatial Sound system may place auditory indicators over visible, remembered, or completely unexplored black space. Hearing never reveals the terrain beneath the cue and never marks a cell explored.

## 1. Ownership

System 23 owns:

- deterministic visual-field queries for an observer cell + cardinal facing;
- current visual occlusion policy for structures/openings;
- per-observer explored/remembered knowledge state;
- stale last-observed environmental snapshots, including static furniture/clutter;
- stale last-seen living-actor observations;
- `VISIBLE / REMEMBERED / UNSEEN` presentation semantics;
- the fog/memory overlay and its future auditory-cue layering seam.

System 23 reads but does not own:

- WHERE cells, facing and structure axis;
- WHAT terrain/entity/placement truth;
- Door State OPEN/CLOSED truth;
- Art Catalog mappings used to redraw remembered terrain, structures and static props/fixtures;
- controlled-survivor identity supplied by composition;
- camera visible-window state;
- current WHEN tick for observation timestamps only.

System 23 does not own world generation/materialization, collision, movement, door mutation, AI/pathfinding, sound propagation, lighting, weather/smoke, actor appearance truth, WHEN advancement, or save-file orchestration.

Existing live renderers remain current-world renderers. Perception does not move visual truth into rendering and does not make renderers into memory stores.

## 2. Three-state observer knowledge model

Every queried cell for one observer resolves to exactly one visual knowledge state.

### `UNSEEN`

- never successfully observed by this observer;
- rendered completely black;
- no terrain, structures, props, actors, items, doors, map hints or other visual world truth is shown;
- an auditory cue may be drawn above the black fog;
- sound does not convert the cell to REMEMBERED.

### `REMEMBERED`

- observed at least once previously;
- not currently in live LOS;
- rendered from the observer's **last observed environmental snapshot**, darkened;
- remembered environment includes terrain, structural shell/door state, and last-observed static furniture/clutter owned by `prop.*` or `fixture.*` semantics;
- hidden current WHAT/Door changes do not update the visual memory;
- stale last-seen actor markers and auditory cues may be shown.

### `VISIBLE`

- currently inside live LOS;
- normal live Ground/Structure/Prop/Actor renderers show current truth;
- remembered environment and stale actor markers do not cover live truth;
- auditory cues may still be shown.

Precedence:

`VISIBLE > REMEMBERED > UNSEEN`

Sound cues are independent of that precedence.

## 3. Observer model

The stateless LOS query accepts any observer position/facing/profile.

Persistent perception memory is keyed by **stable observer actor ID**, not globally shared player knowledge. Candidate 001 maintains full persistent memory for the controlled survivor.

Changing control to another survivor must not automatically grant that survivor everything someone else personally saw. Future maps/radios/conversation may explicitly exchange knowledge if desired.

The observer's own cell is always visible.

## 4. Candidate 001 vision profile

Candidate 001 uses:

- maximum visual range: **12 cells**;
- forward cone: **120 degrees total**;
- near awareness: **Chebyshev radius 1** in all directions;
- authoritative four-way N/E/S/W WHAT facing;
- integer squared-distance/range checks;
- deterministic integer cone math.

For a target offset decomposed into `forward` and `lateral` components relative to facing, ordinary forward-cone membership is:

- `forward > 0`;
- `lateral² <= 3 * forward²`;
- `distance² <= range²`.

Radius-1 near awareness bypasses the forward-cone test but not world existence/validity.

These values are gameplay configuration rather than persistent world identity. Future lighting, injuries, traits, stance, weather or equipment may modify observer profiles without rewriting LOS geometry or memory semantics.

## 5. Deterministic LOS and opacity

`VisionQuery.gd` owns deterministic integer cell tracing and structure opacity interpretation.

Candidate 001 rules:

1. target must pass range/cone membership;
2. crossed cells before the target are tested for opacity;
3. an opaque target structure is itself visible but blocks cells beyond it;
4. zero-width diagonal cracks between two mutually sealing opaque cells cannot be peeked through;
5. LOS never uses sprite alpha, atlas art, collision flags or generator metadata.

Structure opacity:

- `wall.*` — opaque;
- CLOSED `door.*` — opaque;
- OPEN `door.*` — transparent;
- `window.*` — transparent in Candidate 001;
- malformed/unknown STRUCTURE content — fail closed;
- conflicting multiple STRUCTURE occupants — fail closed;
- missing required Door State — fail closed.

Ground, actors, props, fixtures and vegetation do not block sight in Candidate 001. Foliage, vehicles and smoke are future explicit extensions.

Opacity belongs to Perception policy, not Collision. Movement blocking and sight blocking remain independent concepts.

## 6. Recompute model

Perception is event-driven. There is no per-frame world FOV scan.

Relevant recompute triggers include:

- observer cell change;
- observer facing change;
- relevant structure placement/removal;
- relevant Door State change;
- relevant static prop/fixture placement/removal;
- world reset;
- perception-profile change;
- newly materialized terrain/structures/objects inside the potential field.

A WHEN tick advancing by itself does not require LOS recomputation.

Perception/memory updates consume **zero world ticks**. They observe already-committed world state.

## 7. Persistent perception memory

`PerceptionMemoryStore` is authoritative **knowledge state**, not world state.

For each enrolled observer it stores sparse explored environmental records and stale last-seen actor records behind a replaceable storage contract. Callers do not depend on its internal dictionary/chunk representation.

Exploration/memory is not removed because a technical stream region becomes inactive.

### Environmental memory

When a valid materialized cell is VISIBLE, memory is refreshed from what was actually observable at that moment.

Candidate 001 remembers:

- global cell;
- observed tick;
- terrain semantic ID;
- structural shell when present:
  - stable structure entity ID;
  - semantic type;
  - H/V structure axis;
  - observed OPEN/CLOSED door state;
- static furniture/clutter anchored in that observed cell when represented as `prop.*` or `fixture.*`:
  - stable entity ID;
  - semantic type;
  - anchor cell;
  - observed facing.

The static-object snapshot is deliberately observer knowledge, not a remote reference to the current live object. If furniture is moved, removed or replaced while hidden, the remembered copy stays stale until the cell is seen again.

Candidate 001 still does **not** copy loose items, vehicles, vegetation or actors into the environmental cell snapshot. Actors continue to use the separate last-seen record described below.

Perception-memory snapshot schema is now **v2** so static prop/fixture observations serialize deterministically with the rest of observer knowledge. System 23 still does not own save-file orchestration.

### Stale-memory rule

Once a cell is no longer visible, its remembered environment does not poll hidden live truth.

Examples:

- a remembered CLOSED door remains remembered CLOSED if someone opens it out of sight;
- a wall destroyed out of sight remains remembered until re-observed;
- terrain changed out of sight remains remembered as last observed;
- a remembered sofa remains where it was last seen if it is moved or removed out of sight.

Re-observation replaces the stale environmental snapshot with the newly observed truth, including clearing remembered furniture/clutter that is now visibly absent.

## 8. Last-seen living actors

Candidate 001 tracks last-seen observations for other living ACTOR entities.

A record stores at minimum:

- observer ID;
- observed actor stable ID;
- observed actor family/semantic type;
- last observed global cell;
- last observed facing;
- observed tick.

Rules:

1. seeing an actor creates/refreshes its record;
2. while live-visible, the normal Actor renderer is authoritative;
3. after leaving LOS, a clearly stale marker may remain at the last observed cell in REMEMBERED fog;
4. hidden movement/death does not move or erase the marker;
5. seeing that old cell empty disproves/removes the stale location;
6. seeing the actor elsewhere moves the record to the new observed location;
7. the controlled observer does not create a last-seen record for itself.

Candidate 001 does not automatically expire correct-but-old observations. Future age/uncertainty presentation can extend this without changing the underlying knowledge model.

## 9. Sound-cue presentation seam

System 23 does **not** generate or propagate sound.

Its presentation contract allows future auditory descriptors to appear in `VISIBLE`, `REMEMBERED` or `UNSEEN` cells.

A cue over UNSEEN space:

- draws over pure black;
- reveals no terrain;
- marks nothing explored;
- refreshes no environmental memory;
- creates no last-seen actor record;
- is rendered only at the uncertainty/position supplied by the future auditory system.

CI uses synthetic auditory descriptors solely to prove this layering contract. The live game must not fabricate sound events before a real Spatial Sound owner exists.

## 10. Presentation architecture

Canonical draw order:

1. live Ground/Structure/Prop/Actor layers draw current truth;
2. `PerceptionOverlayRenderer` paints black over every non-VISIBLE cell;
3. REMEMBERED cells redraw the stored terrain, structural shell and static furniture/clutter snapshots above black using the Art Catalog with dark memory modulation;
4. stale last-seen markers draw above remembered environment;
5. auditory cues draw above fog/memory regardless of visual state.

Remembered props/fixtures reuse the same semantic Art Catalog and prop-orientation rules as the live Prop renderer, but they draw only from stored memory records. The overlay never asks hidden WHAT what furniture currently exists.

This guarantees that generated hidden chunks, moved furniture, moved actors, opened doors, destroyed walls and similar current hidden facts cannot leak through remembered fog.

Candidate 001 targets:

- true fog: fully opaque `Color.BLACK`;
- remembered terrain/structures/furniture/clutter: approximately 30% normal luminance while remaining legible;
- last-seen actors: recognizable but clearly stale/ghosted;
- visible cells: no Candidate 001 perception darkening.

Presentation constants are centralized/configurable and have no mechanic meaning.

## 11. Materialization ordering

Composition preserves:

`required materialization -> visibility recompute/observation -> presentation redraw`

Newly materialized but never-observed world remains true black. Technical stream activation is never exploration.

## 12. Performance / mobile

Candidate 001 is designed for phone/Safari:

- bounded 12-cell query radius;
- event-driven recomputation;
- sparse observer memory behind a replaceable API;
- remembered static objects store only compact stable ID/semantic/anchor/facing records;
- no per-world-entity render Nodes;
- live renderers remain visible-window bounded;
- remembered presentation plans only cells intersecting the current camera window.

The owning smoke contract benchmarks 100 repeated FOV recomputations and requires average recompute time below one 60 Hz frame-scale budget on the CI fixture.

## 13. Failure behavior

Perception fails by reducing information, never by granting magical sight:

- missing observer placement/facing => no invented vision;
- missing/unmaterialized target terrain => no plausible remembered terrain;
- malformed/unknown blocking structure => blocks sight;
- missing Door State => blocks sight;
- invalid memory/prop record => no plausible remembered rendering;
- invalid auditory cue descriptor => omitted/diagnosed without revealing world truth.

## 14. Implemented owners

Simulation / knowledge:

- `game/scripts/simulation/perception/VisionProfile.gd`
- `game/scripts/simulation/perception/VisionQuery.gd`
- `game/scripts/simulation/perception/PerceptionMemoryStore.gd`
- `game/scripts/simulation/perception/ObserverPerceptionService.gd`

Presentation:

- `game/scripts/render/PerceptionOverlayRenderer.gd`

Integration / verification:

- narrow wiring in the canonical demo composition root;
- `game/scripts/ci/PerceptionFogMemorySmoke.gd`;
- `.github/workflows/perception.yml`;
- exact-head context `verify/system23-perception`.

The draft's proposed separate `VisionOcclusionQuery.gd` was not needed; cohesive tracing/opacity logic remains inside `VisionQuery.gd` rather than adding a one-purpose wrapper solely to match a proposed file list.

## 15. Protected boundaries

System 23 implementation preserves the ownership/contracts of:

- WHERE / WHAT / WHEN;
- Collision / Movement / Actor Locomotion;
- Door State mutation/interaction;
- Ground / Structure / Prop / Actor live renderers;
- Art Catalog semantic mappings;
- System 00D/19/20/00F generation/materialization identity;
- camera math;
- inventory/health/needs/skills;
- live world morphology.

Existing live renderers remain perception-agnostic current-truth renderers.

## 16. Future seams

Clean future extensions remain for:

- real Spatial Sound / hearing uncertainty;
- lighting/darkness altering effective visual range;
- weather/fog/smoke opacity;
- vegetation/vehicle visual occlusion profiles;
- crouch/traits/injuries/skills changing observer profile;
- AI/infected use of the stateless LOS query;
- remembered loose items, vehicles and vegetation where gameplay warrants them;
- communicated/shared knowledge between survivors;
- compressed/persistence-backed perception-memory storage;
- last-seen age/uncertainty presentation;
- future window open/broken/covered states.

These extensions must never turn remembered visual knowledge into hidden live-world polling.

## 17. Verification / acceptance

The dedicated `PerceptionFogMemorySmoke.gd` contract proves the implemented Candidate 001 behaviors, including:

- four-way deterministic cone rotation and integer boundaries;
- radius-1 near awareness;
- wall/CLOSED-door blocking and OPEN-door/window transmission;
- sealed diagonal corner blocking;
- unknown opacity fail-closed behavior;
- true black UNSEEN presentation;
- UNSEEN -> VISIBLE -> REMEMBERED transitions;
- stale remembered door/structure truth;
- static furniture/clutter capture while visible;
- hidden furniture removal leaving the stale remembered object unchanged;
- re-observation clearing furniture/clutter that is now visibly absent;
- remembered furniture/clutter presentation planning above dark fog;
- stale last-seen actor behavior under hidden movement/death;
- stale-marker contradiction and actor re-observation elsewhere;
- auditory cue layering over true fog without exploration;
- materialization without exploration;
- deterministic perception-memory snapshot/restore using schema v2;
- zero WHEN-tick consumption;
- repeated-FOV performance budget.

Exact-head context:

`verify/system23-perception`

First fully green executable implementation head after the final collinear LOS fixture correction:

`87fb517265ba1defc395068d09ccb7059e16d114`

First fully green executable head with remembered static furniture/clutter:

`a08ccf8064f318e283acab6a3f73aa10e59f2acf`

On `a08ccf8064f318e283acab6a3f73aa10e59f2acf`, `verify/system23-perception` and all seven protected gates — System 00D, 00F, 19, 20, 21, 22 and Pages — were green.

## 18. Locked implementation decisions

1. Visual knowledge states are `UNSEEN`, `REMEMBERED`, and `VISIBLE`.
2. UNSEEN is completely black visual world information.
3. REMEMBERED shows stale **last-observed** environment, not darkened current truth.
4. VISIBLE uses current live world renderers.
5. Sound indicators may appear over all three visual states without revealing/exploring terrain.
6. Observer memory is keyed by stable actor ID.
7. Candidate 001 uses range 12, 120-degree forward cone, and radius-1 all-around near awareness.
8. LOS is deterministic integer cell tracing with Perception-owned structure opacity, independent from Collision/art.
9. Walls/CLOSED doors block; OPEN doors/windows transmit in Candidate 001.
10. Environmental memory stores terrain + structural shell/observed door state + last-observed anchored `prop.*`/`fixture.*` furniture/clutter. Loose items, vehicles and vegetation remain separate future extensions.
11. Last-seen living actors are stale observations, not hidden tracking.
12. Hidden live changes never update remembered visual truth, including hidden furniture/clutter changes.
13. Existing live renderers remain current-truth renderers; the perception overlay hides non-visible truth and redraws stored memory.
14. Spatial Sound generation, lighting, weather/smoke, AI and advanced opacity remain separate future systems.
15. Perception updates are event-driven and consume zero WHEN ticks.
