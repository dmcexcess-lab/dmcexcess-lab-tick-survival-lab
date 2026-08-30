# Tick Survival Lab — System 27 Physical Lighting / Illumination / Shadows

Status: **IMPLEMENTED — Slices A + B + C**

Slice A approval, 2026-08-23:

> **“ok lets start with A. the vision cone shrinks and grows with light level.”**

Slice B approval, 2026-08-23:

> **“Approved B.”**

Slice C approval / performance direction, 2026-08-23:

> **“we keep it for now, lets move on and see if it gets worse the more systems we add. approved for C.”**

First fully green executable heads:

- Slice A: `b43b9d02d206658ce8155e485a2ab72be454cc0e`
- Slice B: `a7a95466e70853d9abbd5de9ca1a1d5610672eaf`
- Slice C: `09d1c059760c06ef9791c4d405746caddc107dcf`

Exact-head context:

`verify/system27-physical-lighting`

Core rule:

> **Light is physical. Vision is observer-specific. Rendering visualizes lighting; gameplay and AI never read rendered pixels to decide what is illuminated.**

System 27 now provides the complete first vertical lighting contract: deterministic physical light truth, rich visible presentation, and illumination-aware observer acquisition through System 23.

---

## 1. System intent

Lighting is an identity system rather than a global tint.

The implemented contract supports:

- System 25 dawn/day/dusk/night;
- physical indoor/outdoor differences;
- daylight through windows and OPEN doors;
- local flashlight/lamp/streetlight/neon emitters;
- wall/door/window optical transmission and tactical shadows;
- atmosphere attenuation/scatter inputs for future Weather;
- visible darkness, tint, glow, portal light, scatter and wet-surface treatment;
- target-cell-light-dependent useful vision range;
- one observer-acquisition seam that the controlled survivor uses now and future NPC/infected observers can also use.

System distinction:

- **System 23 geometry** determines the maximum unobstructed candidate set;
- **System 27 physical simulation** determines how much useful light reaches each candidate;
- **System 23 acquisition** decides which candidates become current observer knowledge;
- **System 27 presentation** visualizes the same physical light below the final System 23 knowledge mask.

Canonical causal direction:

`WHEN -> System 25 + physical world/source providers -> System 27 illumination -> System 23 acquisition/memory -> player/NPC knowledge`

Rendering branches downstream and never becomes gameplay authority.

---

## 2. Slice A — authoritative physical illumination

Implemented simulation files include:

- `AtmosphericOptics.gd`;
- `LightEmitterProfile.gd`;
- `LightEmitter.gd`;
- `IlluminationSample.gd`;
- `VisionLightRangePolicy.gd`;
- `PhysicalLightingService.gd`;
- `PhysicalLightingSmoke.gd`.

`PhysicalLightingService.illumination_at(cell)` returns deterministic world-space light truth independent of camera/GPU.

`IlluminationSample` carries:

- sky diffuse;
- direct/celestial light;
- portal light;
- local/artificial light;
- normalized useful luminance `[0,1]`;
- broad tint;
- dominant incoming direction where meaningful;
- glare;
- atmospheric scatter;
- world/door/lighting provenance.

Useful luminance is a gameplay-relative scale, not fake calibrated lux.

### 2.1 Daylight / atmosphere

System 25 remains the clock/daylight owner.

Candidate clear full-day shares:

- diffuse sky `0.72`;
- direct celestial `0.28`.

System 25 night baseline `0.08` remains low outdoor ambient rather than zero light.

`AtmosphericOptics` is a neutral future-Weather input carrying diffuse/direct transmission, local-light extinction, scatter, tint, wet-surface factor and visibility-extinction pressure.

Important physical rule:

> **Fog can make a beam visually more obvious through scatter while reducing its useful distant illumination.**

Overcast suppresses direct sunlight much more strongly than diffuse sky.

### 2.2 Interior / portal light

Until explicit Roof/Shelter truth exists, Candidate 001 derives enclosed cells from the current structure envelope inside the bounded query field. Door/window cells remain envelope cells for roof classification regardless of door OPEN/CLOSED state.

Windows and OPEN doors then act as separate light portals.

Candidate transmission:

- window `0.72`;
- OPEN door `0.95`;
- CLOSED door no direct portal transmission;
- wall/unknown structure no direct portal transmission.

Portal influence decays through enclosed space rather than making the entire building inherit outdoor brightness.

### 2.3 Local light / shadows

Initial semantic emitter profiles:

- flashlight;
- lamp;
- streetlight;
- neon.

Direct local light uses source shape/range/falloff, atmosphere extinction and current optical geometry.

Rules:

- wall blocks direct local light;
- CLOSED door blocks;
- OPEN door transmits strongly;
- window transmits at reduced strength;
- unknown/malformed structure fails dark;
- direct light does not bend around corners like System 26 sound.

A small diffuse spill softens nearby darkness with the invariant:

> **An opaque wall/closed-door surface may be illuminated but may not relay diffuse light through itself.**

Current physical shadow geometry is structure/door/window truth. Arbitrary furniture/prop optical classification remains a later refinement rather than a fake presentation-only shadow.

---

## 3. Light-driven useful vision range

User requirement:

> **“the vision cone shrinks and grows with light level.”**

Candidate 001 remains:

- geometric System 23 maximum: `12` cells;
- zero-light useful-range floor: `2` cells;
- radius-1 near awareness protected;
- response: `sqrt(luminance)` between floor and maximum;
- luminance `1.0` restores the full geometric maximum.

Crucial rule:

> **Useful range is based on the illumination of the candidate/target cell, not merely the light at the observer's feet.**

Standing under a lamp therefore does not grant long-range vision into darkness. A flashlight expands useful range only toward cells it physically illuminates. Another actor/source can illuminate a target for the observer.

Public physical queries remain:

- `effective_vision_range_at(target_cell, geometric_max_range, near_awareness_radius)`;
- `target_within_light_range(origin, target, geometric_max_range, near_awareness_radius)`.

---

## 4. Slice B — physical-light presentation

Implemented presentation files include:

- `PhysicalLightingPresentationRenderer.gd`;
- `physical_lighting_multiply.gdshader`;
- `physical_lighting_glow.gdshader`;
- `PhysicalLightingPresentationSmoke.gd`.

Canonical layer order:

- Ground `z=0`;
- Structures `z=10`;
- Props `z=20`;
- Actors `z=30`;
- Physical Lighting `z=40`;
- Perception `z=100`.

This ordering is mandatory. Current physical light affects the live world, while System 23 remains the final observer-knowledge mask. Hidden current lamps/glow cannot shine through UNSEEN or silently update REMEMBERED facts.

The presentation renderer builds two bounded tactical maps from authoritative samples:

1. a multiplicative darkness/tint map;
2. an additive local/portal/glare/scatter map.

Edge-aware smoothing allows soft gradients while preserving large physical illumination discontinuities so wall/door shadows do not visually bleed away.

Presentation consumes zero WHEN ticks and never determines gameplay visibility.

### 4.1 DEV source boundary

The current critique build still uses explicit `DemoLightingSourceAdapter.gd` because equipment toggles, batteries, electrical switches/grid state and Weather do not yet exist.

It supplies:

- player-following DEV flashlight;
- fixed diner lamp;
- fixed blue neon;
- fixed streetlight.

These sources exist to exercise the real solver/renderer and do not claim real power/battery state. Future source owners replace the adapter at the existing `LightEmitter` / `AtmosphericOptics` seams.

---

## 5. Slice C — illumination-aware observer acquisition

Slice C is implemented.

New/changed contracts:

- `VisualAcquisitionProvider.gd` — neutral System 23 acquisition gate;
- `IlluminationVisualAcquisitionProvider.gd` — System 27 adapter using physical target illumination;
- `ObserverPerceptionService.gd` — geometry-first, acquisition-second, memory-last flow;
- `IlluminationPerceptionSmoke.gd` — focused physical-light/perception contract;
- canonical demo injects the System 27 provider into the controlled survivor's System 23 observer.

### 5.1 Geometry first, light second

System 23 still computes its normal 120-degree / 12-cell geometric candidate set and radius-1 near awareness.

For every geometric candidate, `ObserverPerceptionService` then asks the configured `VisualAcquisitionProvider` whether current conditions allow acquisition.

Only accepted candidates enter `VISIBLE`.

Only accepted candidates refresh environmental memory or current actor observations.

Therefore:

- a distant target inside geometric LOS can remain UNSEEN in darkness;
- lighting that target can make it VISIBLE;
- removing the light makes a previously observed cell REMEMBERED rather than magically current;
- a last-seen actor remains stale knowledge when darkness hides it again;
- third-party light can expose a target;
- opaque geometry still wins: bright light never grants sight through a wall.

### 5.2 Neutral provider seam

System 23 does not import System 27.

Its default `VisualAcquisitionProvider` is pass-through, preserving geometry-only behavior for focused historical tests/compositions.

The live game explicitly injects `IlluminationVisualAcquisitionProvider` from composition.

This is the intended future AI seam: survivor/infected/animal observer services can consume the same acquisition contract without receiving hidden emitter coordinates or framebuffer pixels.

No Actor AI behavior is implemented by System 27.

### 5.3 Camera independence / bounded query demand

Slice C caught an important initialization/ownership issue during verification: Slice B's presentation renderer previously established the active `PhysicalLightingService` field from the camera window. That was harmless while lighting was presentation-only, but gameplay perception may not depend on camera position.

The final adapter therefore guarantees that the observer's complete geometric vision envelope is inside the active physical-light query field before evaluating candidates.

For Candidate 001 this fallback envelope is `25×25` cells around a 12-cell observer range.

Rules:

- if the current presentation field already contains the full observer envelope, C reuses it;
- if camera panning has moved the presentation field elsewhere, the acquisition adapter requests its own observer-centered field;
- camera panning therefore cannot make the survivor blind or grant visibility;
- this is cache/query-bound management only and consumes zero WHEN ticks.

This avoids both gameplay dependence on presentation initialization and an unconditional second lighting rebuild during ordinary camera-following play.

### 5.4 Ambient changes

The canonical System 25 ambient callback now refreshes physical presentation and recomputes observer acquisition, because time-of-day light changes can change what is physically visible even when nobody moved.

Local emitter/world/door changes remain event-driven through their existing physical/perception seams.

---

## 6. Memory / hidden-light rule

System 27 must never become an information leak through System 23.

- UNSEEN remains true black;
- only actually acquired current truth refreshes memory;
- hidden local-light changes do not remotely update stale REMEMBERED facts;
- broad globally knowable daylight may still affect remembered presentation;
- physical spill onto a currently acquired cell may be observed there;
- observing spill does not automatically disclose a hidden source identity/location.

---

## 7. Determinism / time / performance

System 27 simulation and presentation:

- consume zero WHEN ticks themselves;
- have no simulation `_process()` / `_physics_process()` advancement;
- derive daylight from System 25 current tick;
- sort emitters by stable ID;
- use event/revision-driven cache invalidation;
- keep gameplay truth out of GPU textures.

Current measured CI baselines from fully green Slice C executable head `09d1c059760c06ef9791c4d405746caddc107dcf`:

- representative 17×17 changing-flashlight physical rebuild: `4230.32 µs` average (~4.23 ms);
- legacy geometry-only System 23 FOV smoke on the same run: `4058.41 µs` average (~4.06 ms);
- original focused illumination-aware perception recompute: `11838.67 µs` average (~11.84 ms);
- after the 2026-08-29 bounded LOS opacity/structure cache follow-up: approximately `2507-2889 µs` average (~2.5-2.9 ms) across repeated local runs on the same focused fixture.

User direction is to **keep the current implementation for now and monitor whether cost worsens as more systems/actors are added**, rather than pre-optimizing the lighting architecture now.

This is not a claim that population-scale lighting is free. Before many simultaneous infected/NPC observers or many moving emitters, profile again against these baselines and optimize caching/batching only when the measured workload justifies it.

---

## 8. Verification

Dedicated tests:

- `PhysicalLightingSmoke.gd`;
- `PhysicalLightingPresentationSmoke.gd`;
- `IlluminationPerceptionSmoke.gd`;
- System 23's existing perception/memory regressions.

Permanent contexts:

- `verify/system27-physical-lighting`;
- `verify/system23-perception`.

Slice C proves:

- dark distant geometric candidates do not become VISIBLE;
- radius-1 near awareness remains acquired;
- unacquired dark truth does not refresh memory;
- physically lighting a target expands actual acquired vision;
- lit actors create observer-specific last-seen knowledge;
- losing light returns observed cells to REMEMBERED rather than current truth;
- stale last-seen actors are not magically tracked/erased by darkness;
- another physical source can illuminate a target for the observer;
- opaque geometry blocks acquisition even when the target is brightly lit;
- observer-light demand is independent from camera initialization/position;
- illumination-aware perception consumes zero WHEN ticks;
- canonical demo boots with A+B+C integrated.

All twelve required exact-head contexts were green on executable Slice C head `09d1c059760c06ef9791c4d405746caddc107dcf`, including standalone System 23 and Pages.

---

## 9. Future refinement seams

System 27 remains ready for:

- real Weather feeding `AtmosphericOptics`;
- explicit Roof/Shelter/Construction truth;
- curtains/blinds/boards/broken windows;
- prop/furniture optical-material classification;
- real electrical grid/switch/generator state;
- battery-powered portable lights;
- fire/flares/glow sticks;
- vehicle headlights;
- smoke/particulates;
- lightning events;
- season/latitude solar profiles;
- observer-side `NONE / SILHOUETTE / DETAIL` acquisition tiers;
- dark adaptation, acuity, eye injury and equipment modifiers;
- population-scale multi-observer lighting/perception caching after profiling demonstrates the need.

---

## 10. North-star fit

The implementation follows the reduced-complexity survival rule:

- no photon/path-traced global simulation;
- no hidden full 3D physics world;
- no sprite-pixel lighting physics;
- but time, enclosure, openings, local emitters, shadows, physical illumination, observer acquisition and memory have real causal relationships.

The gameplay question is now genuinely:

> **What is actually illuminated here, what can this observer physically make out, and what tactical risk does creating light introduce?**
