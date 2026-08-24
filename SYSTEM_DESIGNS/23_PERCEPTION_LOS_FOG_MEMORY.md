# Tick Survival Lab — System 23 Perception / LOS / Fog Memory

Status: **IMPLEMENTED — Candidate 001 + ambient remembered shading + auditory presentation + illumination-aware acquisition**

System 23 owns observer-specific visual knowledge and the presentation layer that enforces it.

Core visual rule:

> **Black = I know nothing. Dark = I remember this place. Full = I can currently acquire what is actually happening.**

Auditory information remains orthogonal:

> **Fog limits sight, not hearing.**

Exact-head context: `verify/system23-perception`.

---

## 1. Ownership

System 23 owns:

- deterministic geometric LOS candidate queries;
- neutral current-visual-acquisition gating after geometry;
- `UNSEEN / REMEMBERED / VISIBLE` observer knowledge classification;
- observer-keyed stale environmental memory;
- stale last-seen living-actor observations;
- deciding which actually acquired cells refresh memory;
- fog/memory presentation masking/redrawing;
- presentation-only broad ambient input for remembered shading;
- drawing supplied System 26 auditory descriptors above visual fog/memory.

System 23 reads but does not own:

- WHAT terrain/entities/placements;
- Door State;
- Art Catalog;
- System 25 broad ambient daylight;
- System 26 heard-sound descriptors;
- current visual-acquisition decisions supplied through the neutral `VisualAcquisitionProvider` seam.

System 23 does **not**:

- create/propagate/localize sound;
- calculate physical illumination;
- query rendered pixels for gameplay truth;
- decide Actor AI behavior;
- own Weather/time;
- mutate gameplay truth;
- poll hidden current WHAT to repair stale memory.

---

## 2. Candidate 001 geometric LOS

`VisionQuery` / `VisionProfile` define the maximum geometric candidate envelope:

- four-way facing;
- maximum range `12` cells;
- `120°` forward cone;
- radius-1 all-around near awareness;
- deterministic integer tracing;
- walls and CLOSED doors block;
- OPEN doors and windows transmit;
- malformed/unknown structure opacity fails closed.

The blocking structure itself may be acquired; opacity prevents sight beyond it.

Visual opacity remains independent from Collision and System 26 acoustic transmission.

Geometric LOS alone is no longer synonymous with `VISIBLE` in the live game. It is the first stage of observer acquisition.

---

## 3. Current visual acquisition pipeline

Implemented pipeline:

`geometric LOS candidates -> VisualAcquisitionProvider -> VISIBLE set -> memory refresh`

`VisualAcquisitionProvider.gd` is a neutral System 23 contract.

The default provider allows every geometric candidate. This preserves the historical geometry-only behavior for focused tests and compositions that do not inject another acquisition rule.

The live canonical game injects System 27's `IlluminationVisualAcquisitionProvider`.

That adapter evaluates the existing target-cell physical-light range policy, so current acquisition now depends on real illumination without System 23 importing System 27.

Consequences:

- darkness can reject a distant candidate that is geometrically unobstructed;
- physically lighting that target can admit it into `VISIBLE`;
- another actor/source may illuminate the target for this observer;
- bright light never bypasses opaque geometry because geometry is resolved first;
- radius-1 near awareness remains protected by the current System 27 range policy;
- only actually acquired cells refresh memory.

Future infected/survivor/animal perception can use the same provider boundary. System 23 does not grant AI direct access to hidden light emitters or framebuffer pixels.

---

## 4. Camera-independent lighting demand

Once lighting became a gameplay perception input, physical-light queries could no longer depend on whichever region the camera happened to render.

`IlluminationVisualAcquisitionProvider` therefore guarantees that the observer's complete geometric vision envelope is covered by the current bounded System 27 query field before evaluating candidates.

Candidate 001 fallback demand for a 12-cell maximum is a `25×25` observer-centered field.

Rules:

- if the current lighting field already contains that envelope, it is reused;
- if presentation/camera bounds do not contain it, the adapter requests the observer-centered field;
- camera pan/zoom therefore cannot change what the controlled survivor physically sees;
- this cache/query-bound adjustment advances zero WHEN ticks.

This keeps physical illumination camera-independent without forcing an unconditional duplicate lighting rebuild during ordinary camera-following play.

---

## 5. Visual knowledge states

### `UNSEEN`

- never actually visually acquired;
- fully opaque true black at every time of day;
- no terrain/current hidden world truth shown.

### `REMEMBERED`

- previously acquired but not currently acquired;
- redraws only stale stored observer facts;
- hidden current WHAT is never queried to correct it.

### `VISIBLE`

- currently passed both geometric LOS and the configured acquisition gate;
- normal live renderers show current truth;
- environmental/actor memory may refresh from that acquired current truth.

Precedence:

`VISIBLE > REMEMBERED > UNSEEN`.

A cell can therefore move from `VISIBLE` to `REMEMBERED` merely because illumination falls even when geometry did not change.

---

## 6. Environmental memory

Per observer/cell, Candidate 001 remembers:

- global cell and observed tick;
- terrain semantic;
- structure semantic/axis and observed door state;
- anchored static `prop.*` / `fixture.*` furniture/clutter with stable ID, semantic, anchor and facing.

Hidden movement/removal/state changes remain stale until the cell is actually re-acquired.

Seeing/acquiring the cell again refreshes or clears the stored snapshot.

Perception-memory snapshot schema remains **v2**.

Light itself is not currently persisted as historical per-cell memory. Broad globally knowable daylight may alter remembered presentation, but hidden local-light changes do not remotely update stored world facts.

---

## 7. Last-seen living actors

Living actors are stored separately from environmental memory.

Candidate living semantics currently include survivor/infected actor types recognized by the perception service.

When an actor is actually acquired, System 23 stores compact last-seen information including actor ID, semantic, cell, facing and observed tick.

If the last-seen cell becomes currently acquired and the actor is no longer there, the stale actor observation is cleared.

If darkness prevents reacquisition, the old last-seen actor observation stays stale. Darkness does not magically track or erase an unseen actor.

This is the intended knowledge substrate for later Actor AI as well as player presentation.

---

## 8. Remembered presentation / ambient daylight

System 25 supplies a broad normalized ambient-light presentation input for REMEMBERED fog.

Current memory luminance interpolation:

- full daylight remembered luminance: `0.30`;
- zero-ambient remembered luminance: `0.10`;
- Candidate System 25 night ambient `0.08` gives remembered luminance about `0.116`.

This changes presentation only. It does not update stale memory or reveal hidden current local lights.

`UNSEEN` remains true black at every ambient level.

System 27 physical visible-world lighting renders below the Perception overlay, so current hidden glow/light cannot leak through the observer-knowledge mask.

---

## 9. Auditory presentation

System 23 does not own physical sound.

System 26 supplies listener-specific auditory presentation descriptors. System 23 draws them as yellow words over any visual knowledge state, including completely black UNSEEN terrain.

Auditory cues:

- do not reveal/explore terrain;
- do not refresh visual memory;
- use perceived rather than hidden exact source location;
- may clamp to the viewport edge when offscreen.

Thus a survivor may hear `FOOTSTEPS` from darkness without visually learning what lies there.

---

## 10. Event-driven recomputation / time

Perception recomputation consumes zero WHEN ticks.

Relevant current triggers include:

- controlled observer placement/facing changes;
- nearby terrain/structure/actor placement changes;
- Door State changes;
- profile/acquisition-provider changes;
- explicit System 25 ambient-light changes in canonical composition because illumination can alter acquisition without movement.

System 23 has no wall-clock visual-simulation owner and does not advance during idle rendering.

---

## 11. Hidden-information invariants

Required invariants:

- newly materialized but unobserved world remains UNSEEN;
- technical streaming activation is never exploration;
- hidden current environment changes do not rewrite memory;
- hidden current local-light changes do not update REMEMBERED facts;
- light spill may matter only where current acquisition actually succeeds;
- seeing spill does not automatically disclose a hidden source identity/location;
- sound never marks visual exploration;
- renderer/camera state never determines physical observer truth.

---

## 12. Performance state

Legacy geometry-only focused benchmark on fully green System 27 Slice C executable head `09d1c059760c06ef9791c4d405746caddc107dcf`:

`PERCEPTION_FOV_BENCH_AVG_US=4058.41`

Focused illumination-aware perception benchmark on the same System 27 run:

`PERCEPTION_LIGHTING_RECOMPUTE_AVG_US=11838.67`

That is approximately **4.06 ms geometry-only** versus **11.84 ms lighting-aware** on those CI fixtures.

The user explicitly chose to keep the current behavior and monitor scaling as more systems/actors are added rather than pre-optimize now.

Before population-scale NPC/infected observers are introduced, profile multi-observer workloads against this baseline and optimize only if measured cost requires it.

---

## 13. Verification

Core smoke:

- `game/scripts/ci/PerceptionFogMemorySmoke.gd`

Ambient-memory smoke:

- `game/scripts/ci/PerceptionAmbientMemorySmoke.gd`

Lighting/acquisition smoke:

- `game/scripts/ci/IlluminationPerceptionSmoke.gd`

Permanent context:

- `verify/system23-perception`

Coverage includes:

- cone/range/near awareness;
- wall/door/window LOS;
- unknown opacity fail-closed behavior;
- UNSEEN/REMEMBERED/VISIBLE transitions;
- stale environment and actor memory;
- remembered furniture/clutter;
- ambient remembered shading;
- yellow-word auditory presentation without exploration;
- dark geometric targets rejected by illumination-aware acquisition;
- physically lit targets becoming current VISIBLE truth;
- third-party illumination;
- opaque geometry still blocking bright targets;
- no memory refresh for unacquired dark truth;
- stale actor memory surviving loss of light;
- camera-independent lighting demand;
- zero WHEN-tick consumption;
- geometry-only and illumination-aware performance markers;
- canonical startup.

On System 27 Slice C executable head `09d1c059760c06ef9791c4d405746caddc107dcf`, `verify/system23-perception` and all protected exact-head contexts including Pages were green.

---

## 14. Deferred perception refinements

Possible later observer-side refinements:

- `NONE / SILHOUETTE / DETAIL` acquisition tiers;
- dark adaptation;
- observer visual acuity/traits/injury;
- glare recovery;
- weather visibility extinction beyond light alone;
- smoke/particulate occlusion;
- special equipment/night vision;
- AI-specific interpretation of visual observations.

These should extend observer perception and provider contracts rather than move knowledge ownership into System 27 or Actor AI.
