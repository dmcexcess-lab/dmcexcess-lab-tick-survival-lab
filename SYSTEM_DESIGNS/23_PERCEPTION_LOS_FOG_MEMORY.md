# Tick Survival Lab — System 23 Perception / LOS / Fog Memory

Status: **DRAFT — awaiting approval**

System 23 establishes the first canonical visual-perception model for the playable survival world: deterministic facing-based line of sight, true unexplored fog, stale remembered world memory, and last-seen actor information.

Core player-language rule:

> **Black = I know nothing. Dark = I remember this place. Full = I can see what is actually happening now.**

Auditory information is orthogonal to sight:

> **Fog limits sight, not hearing.**

A future spatial-sound system may place auditory indicators over visible, remembered, or completely unexplored black space. Hearing never reveals the terrain beneath the cue.

This is one perception system, not a shader trick and not an AI system. The LOS query is reusable by future AI/infected observers; player knowledge/memory is a separate persistent typed domain.

## 1. North-star fit

The North Star explicitly identifies perception/vision and spatial sound as identity-level systems that deserve more depth. System 23 creates uncertainty, facing vulnerability, room-clearing tension, stale information, and a truthful basis for later stealth without changing world truth.

It also naturally masks virgin streamed terrain until the player actually sees it: materialization may happen behind true fog, but unexplored world remains black until LOS reveals it.

## 2. Ownership

### System 23 owns

- deterministic visual-field queries for an observer cell + cardinal facing;
- visual occlusion interpretation for current structures/openings;
- the controlled observer's explored/remembered knowledge state;
- stale last-seen living-actor observations;
- conversion of `VISIBLE / REMEMBERED / UNSEEN` knowledge into fog/memory presentation;
- presentation layering rules for future auditory cues.

### System 23 reads but does not own

- WHERE global cells/facing/structure axis;
- WHAT terrain/entity/placement truth;
- Door State OPEN/CLOSED truth;
- 04 Art Catalog for remembered-world presentation;
- current controlled-survivor identity supplied by composition;
- current camera/visible-window state supplied through existing presentation seams;
- WHEN current tick for observation timestamps only.

### System 23 does not own

- world generation/materialization/streaming;
- collision or movement legality;
- door interaction/state mutation;
- AI decisions/pathfinding;
- sound propagation/hearing calculations;
- lighting/weather/smoke;
- actor appearance truth;
- rendering truth for currently visible live world layers;
- WHEN advancement;
- save-file orchestration.

## 3. Canonical three-state visibility model

Every queried cell for one observer resolves to exactly one presentation knowledge state:

### `UNSEEN`

- never successfully observed by this observer;
- rendered completely black;
- no terrain, structures, props, actors, items, doors, map hints, or other visual world truth is shown;
- an auditory indicator may still be drawn above the black fog;
- sound does **not** change the cell to REMEMBERED.

### `REMEMBERED`

- observed at least once previously;
- not currently inside the observer's live LOS;
- rendered from the observer's **last observed environmental snapshot**, darkened;
- current hidden WHAT/Door State changes must not leak through;
- last-seen actor markers may be shown here;
- auditory indicators may be shown here.

### `VISIBLE`

- currently inside live LOS;
- existing Ground/Structure/Prop/Actor renderers show live current truth normally;
- memory visuals and stale last-seen markers do not cover live truth;
- an appropriate auditory indicator may still be shown.

State precedence:

`VISIBLE > REMEMBERED > UNSEEN`

Sound cues do not participate in that precedence.

## 4. Observer model

System 23's visual query is generic and accepts any observer position/facing/profile.

Persistent memory is keyed by **observer stable actor ID**, not globally shared player knowledge. Candidate 001 only instantiates/maintains full persistent memory for the controlled survivor.

This preserves a future rule that changing control to another survivor does not magically grant that person everything another survivor personally saw. Shared maps/radios/conversation may later exchange knowledge explicitly if desired.

The controlled survivor's own cell is always currently visible.

## 5. Candidate 001 vision profile

Initial profile is deliberately simple and configurable rather than embedded in rendering:

- maximum visual range: **12 cells**;
- forward cone: **120 degrees total** (60 degrees either side of facing);
- near-field awareness: **Chebyshev radius 1** around the observer regardless of facing;
- authoritative facing: existing four-way N/E/S/W WHAT facing;
- range uses integer squared-distance comparison;
- cone membership uses deterministic integer math, not platform-dependent angle rounding.

For a candidate offset decomposed into `forward` and `lateral` components relative to facing, ordinary forward-cone membership is:

- `forward > 0`;
- `lateral² <= 3 * forward²`;
- distance² <= range².

The radius-1 near field bypasses the forward-cone test but not world existence/validity.

These numbers are gameplay configuration, not persistent world identity. Later lighting, injuries, traits, stance, weather, binoculars, etc. may modify an observer profile without rewriting LOS geometry or explored memory semantics.

## 6. Deterministic LOS / occlusion

Candidate 001 uses an integer supercover-style cell trace from observer to target.

Rules:

1. target cell must pass the observer profile's range/cone test;
2. cells crossed before the target are checked for visual occlusion;
3. an opaque target structure is itself visible, but blocks cells beyond it;
4. no ray may see through the zero-width diagonal crack between two mutually sealing opaque cells;
5. LOS does not use sprite alpha, atlas art, collision flags, or generator metadata.

### Initial structure opacity semantics

- `wall.*` — opaque;
- `door.*` CLOSED — opaque;
- `door.*` OPEN — transparent;
- `window.*` — transparent in Candidate 001;
- malformed/unknown STRUCTURE content — fail-closed for LOS and diagnostic;
- multiple conflicting STRUCTURE occupants — fail-closed and diagnostic.

Candidate 001 ground, actors, props, fixtures, and vegetation do not themselves block LOS. Foliage/vehicle/smoke opacity is a future explicit extension, not a semantic-name guess in this slice.

Opacity is owned by perception policy, not Collision. A thing can block movement but not sight, or sight but not movement, without the systems lying to one another.

## 7. Event-driven visibility recomputation

No per-frame world scan.

Recompute the controlled observer's current visible-cell set when a potentially relevant fact changes, including:

- observer cell changes;
- observer facing changes;
- relevant structure placement/removal inside potential visual range;
- relevant Door State change inside potential visual range;
- world reset;
- perception-profile change;
- newly materialized terrain/structures inside the potential visual field.

A WHEN tick advancing by itself does not require LOS recomputation.

Candidate 001's bounded 12-cell range allows straightforward deterministic ray tests; do not introduce complex visibility meshes or GPU truth solely for speed before profiling demonstrates a need.

## 8. Persistent perception memory

`PerceptionMemoryStore` is authoritative **knowledge state**, not world state.

For each enrolled observer it maintains sparse explored-cell records and last-seen actor records behind a replaceable storage contract. The initial representation may be sparse; callers must not depend on its dictionary/chunk implementation because long-term large-world/mobile memory may justify compression or persistence-backed residency.

Exploration/memory is never removed merely because a technical stream region becomes inactive.

### Remembered environmental cell

When a cell is VISIBLE and has valid materialized world truth, the observer's memory snapshot is refreshed from what was actually observable at that moment.

Candidate 001 remembers:

- global cell;
- observed tick;
- terrain semantic ID;
- structural shell snapshot when present:
  - stable structure entity ID;
  - semantic type;
  - H/V structure axis;
  - observed OPEN/CLOSED state for a door.

Candidate 001 intentionally does **not** persist remote live copies of ordinary props, loose items, vegetation, or actors in each cell memory. Those domains may gain explicit remembered-observation rules later if gameplay justifies them.

### Stale-memory rule

Once a cell is no longer visible, its remembered environment does not react to hidden current-world mutation.

Examples:

- a door remembered CLOSED remains visually remembered CLOSED if somebody opens it out of sight;
- a wall destroyed out of sight remains in memory until the player sees that location again;
- terrain altered out of sight remains remembered as last observed.

When the cell becomes visible again, live truth is shown and its memory snapshot is replaced with the new observation.

This is why System 23 must not implement remembered fog by merely darkening the live renderers.

## 9. Last-seen living actors

Candidate 001 tracks last-seen observations for other living ACTOR entities observed by the controlled survivor.

A last-seen record stores at minimum:

- observer ID;
- observed actor stable ID;
- observed actor family/semantic type;
- last observed global cell;
- last observed facing;
- observed tick.

Rules:

1. seeing an actor creates/refreshes its record;
2. while that actor is live-visible, the normal Actor renderer is authoritative and no last-seen marker is drawn over it;
3. once the actor leaves LOS, a visually distinct stale marker may remain at the last observed cell in REMEMBERED fog;
4. hidden actor movement/death does not move or delete the marker through remote knowledge;
5. if the remembered cell becomes visible and the actor is not there, that stale location is disproven and removed;
6. if the actor becomes visible elsewhere, the record moves to the newly observed location;
7. the controlled observer does not create a last-seen marker for itself.

Candidate 001 does not automatically expire correct-but-old observations. Presentation must visibly distinguish last-seen memory from a live actor; later gameplay may add age/uncertainty decay without changing the knowledge model.

## 10. Sound indicators and true fog

System 23 does **not** simulate sound propagation in this slice. Spatial Sound remains the next independent mechanic domain.

However the perception presentation contract is explicit now so later sound cannot accidentally turn into sight:

- auditory cues may render in `VISIBLE`, `REMEMBERED`, or `UNSEEN` cells;
- a cue over `UNSEEN` space is drawn over pure black with no underlying world reveal;
- a cue does not mark cells explored;
- a cue does not refresh environmental memory;
- a cue does not create/update a last-seen actor record;
- System 23 renders only the estimated cue information supplied to it and never secretly improves origin precision from hidden WHAT;
- uncertainty radius/direction/strength/category belong to the future auditory-perception output contract, not LOS.

CI may inject synthetic auditory cue descriptors to prove layering behavior. The live game must not fabricate sound events until a real Spatial Sound owner exists.

## 11. Presentation architecture

Existing live renderers remain current-world renderers and do not become memory stores.

Canonical draw order for System 23 composition:

1. existing live Ground/Structure/Prop/Actor layers draw current truth;
2. `PerceptionOverlayRenderer` paints **black over every non-VISIBLE cell**, completely hiding current hidden truth;
3. for `REMEMBERED` cells only, the same perception layer draws the stored environmental snapshot above black using 04 Art Catalog and a dark memory modulation;
4. last-seen markers draw above remembered environment;
5. auditory cues draw above fog/memory regardless of visual state.

This ordering guarantees that hidden live doors, moved actors, generated chunks, destroyed walls, etc. cannot leak through remembered fog.

Candidate 001 remembered presentation target:

- true fog: `Color.BLACK`, fully opaque;
- remembered terrain/structures: approximately **30% luminance** of normal art while remaining legible;
- last-seen actor marker: recognizable but clearly stale/ghosted, never visually identical to a live actor;
- visible cells: no perception darkening in Candidate 001.

Exact presentation constants remain centralized/configurable and have no mechanic meaning.

## 12. Materialization / chunk-load ordering

System 23 does not own streaming, but composition should preserve this order when entering new space:

`required materialization -> visibility recompute/observation -> presentation redraw`

A newly materialized but never-observed chunk therefore remains true black. Materialization pop-in outside LOS is not exposed as player knowledge.

System 23 never treats technical stream-region activation as exploration.

## 13. WHEN / turn behavior

LOS and memory updates consume **zero world ticks**. They are consequences/knowledge updates resulting from already-committed world state.

Observation timestamp uses current WHEN tick for stale-information age only.

Turning remains an existing committed action. When the actor's facing actually changes at the existing commit, perception recomputes and may reveal a different cone.

Walking/running similarly reveal from the actor's new committed cell rather than predicting future visibility during windup.

## 14. Performance / mobile

Candidate 001 is designed for phone/Safari:

- bounded 12-cell query radius;
- event-driven recomputation, no `_process()` FOV loop;
- sparse explored memory behind a replaceable store API;
- no per-world-entity render Nodes;
- existing live renderers remain unchanged and visible-window bounded;
- remembered presentation only plans cells intersecting the current camera window;
- future storage compression/residency can replace memory internals without changing observer knowledge semantics.

Performance acceptance should include repeated turn/move FOV updates on the current phone-sized visible window and prove no significant regression to the just-completed materialization performance razor.

## 15. Failure / fail-closed behavior

- missing observer placement/facing => no invented vision;
- missing/unmaterialized target terrain => never remembered as plausible terrain;
- unknown/malformed blocking STRUCTURE => blocks LOS rather than leaking information;
- missing Door State for a door => blocks LOS/diagnostic rather than assuming OPEN;
- invalid memory record => render no plausible remembered world for that record;
- auditory cue with invalid position/schema => omit/diagnose; never reveal world truth.

Perception failure should reduce information rather than grant magical sight.

## 16. Proposed implementation owners

Expected focused owners:

### Simulation / knowledge

- `game/scripts/simulation/perception/VisionProfile.gd`
- `game/scripts/simulation/perception/VisionOcclusionQuery.gd`
- `game/scripts/simulation/perception/VisionQuery.gd`
- `game/scripts/simulation/perception/PerceptionMemoryStore.gd`
- `game/scripts/simulation/perception/ObserverPerceptionService.gd`

### Presentation

- `game/scripts/render/PerceptionOverlayRenderer.gd`

Do not create separate files for every enum/snapshot/helper unless implementation complexity proves they have an independent reason to exist.

### Integration / test

- narrow composition wiring in the current canonical demo root;
- `game/scripts/ci/PerceptionFogMemorySmoke.gd`;
- one owning perception workflow/context rather than multiple candidate workflows.

## 17. Protected neighbors

Implementation must not change the ownership/contracts of:

- WHERE / WHAT / WHEN;
- Collision / Movement / Actor Locomotion;
- Door State mutation/interaction;
- Ground / Structure / Prop / Actor live renderers except an unavoidable narrow composition/redraw seam discovered during implementation;
- Art Catalog semantic mappings;
- System 00D/19/20/00F generation/materialization identity;
- Camera math;
- inventory/health/needs/skills;
- live world morphology.

If implementation requires current renderers to become perception-aware filters or memory owners, stop and reassess; the black-mask + remembered-redraw architecture exists specifically to avoid that coupling.

## 18. Future seams

System 23 intentionally leaves clean additions for:

- real Spatial Sound / hearing uncertainty;
- lighting/darkness altering effective visual range;
- weather/fog/smoke opacity;
- vegetation/vehicle visual occlusion profiles;
- crouch/traits/injuries/skills changing observer profile;
- AI/infected use of the same stateless LOS query;
- remembered props/items/vehicles where gameplay warrants them;
- map-sharing or communicated knowledge between survivors;
- compressed/persistence-backed perception-memory storage;
- last-seen age/uncertainty presentation;
- windows with future open/broken/covered states.

These extensions must not turn visual memory into hidden live-world polling.

## 19. Verification / acceptance plan

A dedicated System 23 contract should prove at minimum:

1. four-way facing rotates the same deterministic cone;
2. range/cone boundary math is integer/deterministic;
3. radius-1 near awareness works behind the actor;
4. walls and CLOSED doors block cells beyond while remaining visible themselves;
5. OPEN doors and windows transmit LOS;
6. sealed diagonal corners cannot be peeked through;
7. unknown opacity fails closed;
8. unseen cells render pure black despite live world content underneath;
9. synthetic sound cue remains visible over true black without exploring it;
10. first visual observation transitions UNSEEN -> VISIBLE and records memory;
11. turning/moving away transitions VISIBLE -> REMEMBERED;
12. remembered door/structure state remains stale when hidden live truth changes;
13. re-observation refreshes remembered environment;
14. seen actor becomes a last-seen marker after leaving LOS;
15. hidden movement/death does not magically update that marker;
16. re-seeing the old empty cell disproves/removes the stale marker;
17. seeing the same actor elsewhere updates its last-seen record;
18. visibility/memory changes spend zero WHEN ticks;
19. true technical streaming activation never marks space explored;
20. newly materialized unseen cells stay black;
21. no per-frame perception polling;
22. existing movement/door/render/camera/world-stack regressions remain green;
23. mobile-sized repeated FOV recomputation stays comfortably below a frame-scale budget in focused benchmarking.

Proposed exact-head context:

`verify/system23-perception`

## 20. Proposed approval decisions

Approval of this DRAFT authorizes these design decisions:

1. canonical visual states are `UNSEEN`, `REMEMBERED`, and `VISIBLE`;
2. UNSEEN is completely black visual world information;
3. REMEMBERED shows darkened **last-observed** environment, not darkened current truth;
4. VISIBLE uses current live world renderers;
5. sound indicators may appear over all three states, including completely unexplored black fog, without revealing/exploring the world;
6. observer memory is per stable actor ID;
7. Candidate 001 uses range 12, 120-degree forward cone, and radius-1 all-around near awareness;
8. LOS uses deterministic integer cell tracing and structure opacity, independent from Collision/art;
9. walls/CLOSED doors block; OPEN doors/windows transmit in Candidate 001;
10. remembered environment initially stores terrain + structural shell/observed door state only;
11. last-seen living actors are stale observations that persist until contradicted or re-observed;
12. hidden live changes never update remembered visual truth;
13. existing live renderers remain perception-agnostic; one overlay blacks hidden truth and redraws remembered snapshots;
14. spatial-sound generation, lighting, weather/smoke, AI and advanced opacity remain separate future systems;
15. perception updates are event-driven and consume zero WHEN ticks.
