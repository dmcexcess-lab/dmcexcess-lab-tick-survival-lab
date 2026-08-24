# Tick Survival Lab — System 27 Physical Lighting / Illumination / Shadows

Status: **IMPLEMENTED — Slices A + B; Slice C pending**

Slice A approval, 2026-08-23:

> **“ok lets start with A. the vision cone shrinks and grows with light level.”**

Slice B approval, 2026-08-23:

> **“Approved B.”**

First fully green Slice A executable head:

`b43b9d02d206658ce8155e485a2ab72be454cc0e`

First fully green Slice B executable head:

`a7a95466e70853d9abbd5de9ca1a1d5610672eaf`

Exact-head context:

`verify/system27-physical-lighting`

Core rule:

> **Light is physical. Vision is observer-specific. Rendering visualizes lighting; gameplay and AI never read rendered pixels to decide what is illuminated.**

System 27 owns authoritative physical illumination. Slice A provides deterministic headless physical truth and the light-to-useful-vision-range policy. Slice B visualizes that same truth. Slice C will make System 23 observer acquisition consume it.

---

## 1. System intent

Lighting is an identity system rather than a global tint.

The complete System 27 direction supports:

- System 25 dawn/day/dusk/night;
- weather/atmosphere attenuation and scatter;
- physical indoor/outdoor light differences;
- daylight through windows/open doors;
- artificial light through openings;
- flashlights/headlamps as directional physical sources;
- lamps, streetlights and neon;
- tactical shadows;
- visible darkness, tint, glow and scatter;
- illumination-dependent visual acquisition;
- one physical-light contract shared by player and future NPC/infected observers.

System distinction:

- **System 23 geometry** answers whether a candidate is in unobstructed observer LOS;
- **System 27 simulation** answers how much useful physical light reaches each world cell;
- **System 27 presentation** visualizes those samples without becoming authority;
- **observer perception** later combines geometry + illumination + observer capability into acquired knowledge.

---

## 2. Slice status

### Slice A — IMPLEMENTED

Authoritative headless physical lighting:

- `AtmosphericOptics.gd`;
- `LightEmitterProfile.gd`;
- `LightEmitter.gd`;
- `IlluminationSample.gd`;
- `VisionLightRangePolicy.gd`;
- `PhysicalLightingService.gd`;
- `PhysicalLightingSmoke.gd`.

### Slice B — IMPLEMENTED

Rich visible-world presentation from Slice A truth:

- `PhysicalLightingPresentationRenderer.gd`;
- `physical_lighting_multiply.gdshader`;
- `physical_lighting_glow.gdshader`;
- renderer-stack integration below Perception;
- canonical-demo integration;
- `DemoLightingSourceAdapter.gd` as an explicitly DEV-only source provider until real source-owning systems exist;
- `PhysicalLightingPresentationSmoke.gd`.

### Slice C — NOT IMPLEMENTED

System 23 illumination-aware current visual acquisition and the neutral observer seam future AI consumes.

Slice C remains a bounded later implementation slice under this System 27 contract.

---

## 3. Ownership

System 27 simulation owns:

- deterministic bounded illumination fields;
- normalized useful luminance;
- broad physical light tint;
- dominant incoming light direction summary;
- glare/scatter summaries;
- semantic emitter profiles/descriptors;
- sky/direct/local composition downstream of System 25;
- current structure/door/window optical transmission;
- enclosure/sky-exposure approximation;
- window/open-door outdoor-light portal transfer;
- deterministic direct local-light shadow/occlusion truth;
- small diffuse local spill approximation;
- atmospheric-optics input contract;
- target-light-derived useful-vision-range policy.

System 27 presentation owns:

- converting current illumination samples into visible darkness/tint maps;
- soft additive glow/halo/scatter treatment;
- wet-surface reflection presentation cheat;
- emissive-core emphasis;
- presentation-only smoothing while preserving hard physical discontinuities;
- renderer ordering relative to current-truth world layers and System 23 knowledge masking.

System 27 reads but does not own:

- WHERE coordinates/facing/footprints/structure geometry;
- WHAT terrain/entities/placements;
- Door State;
- System 25 time/daylight;
- future Weather state;
- future power/battery/fuel/switch truth;
- future item/equipment state that determines whether portable lights are active.

System 27 does **not** own:

- System 23 memory/observer knowledge;
- actor AI decisions;
- Weather simulation;
- electrical/grid simulation;
- item toggle/use actions;
- battery/fuel quantities;
- save-file orchestration.

Dependency direction:

`WHEN -> System 25 + physical world/source providers -> System 27 physical truth -> observer perception -> player/NPC knowledge`

Rendering branches downstream from System 27 physical truth and never enters that authority chain.

---

## 4. Physical sample contract

`PhysicalLightingService.illumination_at(cell)` returns deterministic world-space light truth independent of camera/GPU.

`IlluminationSample` includes:

- global cell;
- diffuse sky contribution;
- direct/celestial contribution;
- portal contribution;
- local/artificial contribution;
- normalized useful luminance `[0,1]`;
- broad tint;
- dominant incoming direction where meaningful;
- glare;
- atmospheric scatter;
- world tick;
- WHAT revision;
- Door State revision;
- lighting revision.

Useful luminance is gameplay-relative rather than fake calibrated lux. Presentation is allowed to exaggerate bloom/halo without changing that gameplay scale.

---

## 5. Outdoor daylight and atmosphere

System 25 remains the clock/daylight owner.

Candidate clear full-day composition:

- diffuse sky share `0.72`;
- direct celestial share `0.28`.

System 25 night baseline `0.08` remains low outdoor ambient rather than zero illumination.

`AtmosphericOptics` is a neutral provider-shaped input. Controlled profiles currently cover clear, overcast, rain, fog and storm behavior. The contract carries:

- diffuse-sky transmission;
- direct-light transmission;
- local-light transmission/extinction;
- scatter strength;
- tint;
- wet-surface presentation factor;
- visibility-extinction pressure;
- revision.

Important physical rule:

> **Fog may make a beam visually more apparent through scatter while simultaneously reducing its useful distant illumination.**

Overcast suppresses direct sunlight much more strongly than diffuse sky.

---

## 6. Interior / sky exposure

Until an explicit Roof/Shelter owner exists, Candidate 001 uses a replaceable structure-envelope approximation inside the bounded field:

1. perimeter terrain seeds exterior space;
2. flood fill travels through non-envelope terrain;
3. structures form enclosure boundaries;
4. unreachable ordinary cells become enclosed/roofed baseline cells.

Door/window cells remain part of the envelope regardless of door open state; opening a door does not make a roof disappear.

Known limitation: a roofless enclosed courtyard cannot yet be distinguished from a roofed room using structure envelope alone.

---

## 7. Portal light

Windows and OPEN doors transmit outdoor light into enclosed space.

Candidate transmission:

- window `0.72`;
- OPEN door `0.95`;
- CLOSED door no direct portal transmission;
- wall/unknown structure no direct portal transmission.

Portal influence decays through enclosed space rather than making a whole building inherit outdoor brightness.

Proven ordering:

`clear exterior > window/open-door interior > deep enclosed interior`.

Door state changes invalidate the field and visibly alter portal presentation.

---

## 8. Local emitters

`LightEmitter` is exact active-source truth supplied to System 27. It contains stable emitter ID, origin, facing, semantic profile, active state and revision.

Source owners remain responsible for whether a light is actually active. System 27 does not invent batteries, switches or grid power.

Supported profile shapes:

- `OMNI`;
- `CONE`.

Initial profile constructors:

- flashlight;
- lamp;
- streetlight;
- neon.

Profiles define useful range, base luminance, tint, falloff, cone width and diffuse-spill fraction.

---

## 9. Tactical physical shadows

Direct local-light shadows are deterministic grid truth.

For a candidate cell, the solver checks source range/shape, traces an optical path, applies falloff and atmosphere extinction, applies structure/opening transmission, and stores surviving local-light contribution.

Rules:

- wall blocks direct local light;
- CLOSED door blocks;
- OPEN door transmits strongly;
- window transmits at reduced strength;
- malformed/unknown structure fails dark;
- direct light does not bend around corners as sound does.

A small local diffuse spill may soften neighboring darkness, with the invariant:

> **An opaque wall/closed-door surface may be illuminated but may not relay diffuse light through itself.**

Current shadow occluders are the optical geometry Slice A actually models: structures, doors and windows. Arbitrary prop/furniture optical occlusion remains a later refinement; Slice B does not fake prop shadows that the simulation backend does not own.

---

## 10. Light-driven useful vision range

User requirement:

> **“the vision cone shrinks and grows with light level.”**

Candidate 001:

- geometric System 23 maximum remains 12 cells;
- zero-light useful range floor is 2 cells;
- radius-1 near awareness remains protected;
- target luminance uses a `sqrt(luminance)` response;
- increasing target illumination monotonically expands useful range;
- luminance 1.0 restores full geometric range.

Crucial rule:

> **Useful range is based on the illumination of the candidate/target cell, not merely the light at the observer's feet.**

Standing under a lamp therefore does not grant long-range vision into darkness. A flashlight expands useful range only toward cells it physically illuminates.

Public queries:

- `effective_vision_range_at(target_cell, geometric_max_range, near_awareness_radius)`;
- `target_within_light_range(origin, target, geometric_max_range, near_awareness_radius)`.

Slice C will make System 23 consume this policy. Slice B does not mutate observer knowledge.

---

## 11. Slice B presentation architecture

### 11.1 Renderer ordering

Canonical layer order is:

- Ground `z=0`;
- Structures `z=10`;
- Props `z=20`;
- Actors `z=30`;
- Physical Lighting `z=40`;
- Perception `z=100`.

This ordering is intentional. Lighting affects the current visible world, while System 23 remains the final observer-knowledge mask. UNSEEN stays true black and REMEMBERED stays stale even if a hidden current light changes behind it.

### 11.2 Physical light maps

`PhysicalLightingPresentationRenderer` builds two compact images over the current tactical render window:

1. **multiply map** — physical useful luminance in alpha and light tint in RGB;
2. **glow map** — local/artificial, portal, glare and scatter energy with physical tint.

The images become `ImageTexture`s scaled by cell pixel size. This is a presentation representation of headless samples; no gameplay query reads these textures.

### 11.3 Darkness/tint shader

`physical_lighting_multiply.gdshader` uses multiplicative blending to darken/tint existing world art.

It uses edge-aware four-neighbor smoothing:

- similar luminance can blend softly;
- large luminance differences reduce cross-edge blending;
- physical wall/door shadow discontinuities therefore remain tactical rather than becoming blurred light leaks.

Darkness has a low blue-black floor instead of flattening the entire image to featureless black. System 23 still owns actual UNSEEN black.

### 11.4 Glow/scatter/reflection shader

`physical_lighting_glow.gdshader` uses additive blending for:

- local-light halo;
- portal glow;
- glare;
- atmospheric scatter;
- a restrained vertical wet-surface reflection sample driven by atmosphere wetness.

Emitter-origin pixels receive profile-tinted emissive-core emphasis. This lets warm lamps/streetlights, blue neon and flashlight energy read differently while remaining derived from physical descriptors.

### 11.5 Event-driven updates

Presentation owns no frame-time clock. It refreshes from relevant world/door/light input changes and the canonical System 25 ambient callback. Both physical and presentation rebuilds consume zero WHEN ticks.

There is no second presentation-only time-of-day cycle.

---

## 12. DEV source provider boundary

The current critique build needs active lights to exercise Slice B before the eventual source-owning systems exist.

`DemoLightingSourceAdapter` is therefore explicitly DEV-only and allowed by the repository no-fake-completion rule.

It supplies:

- `dev.light.player_flashlight` following the controlled survivor's current WHAT cell/facing;
- fixed diner lamp;
- fixed blue diner neon;
- fixed streetlight.

It does **not** claim:

- a flashlight item is equipped;
- a battery has charge;
- a diner has electrical service;
- a switch is on;
- the regional grid is alive;
- Weather currently exists.

Future equipment/power/weather providers replace this adapter at the `LightEmitter` / `AtmosphericOptics` seams without changing the physical solver or Slice B renderer.

---

## 13. Hidden-light memory rule

System 27 must never leak hidden current world truth through System 23.

- globally known daylight/weather may affect broad remembered presentation;
- hidden local lights do not remotely refresh REMEMBERED facts;
- true-black UNSEEN remains black because Perception renders above lighting;
- visible spill onto an actually acquired cell may be observed there;
- observing spill does not automatically disclose the hidden source identity/location.

---

## 14. Determinism / time / performance

System 27 simulation:

- consumes zero WHEN ticks;
- has no `_process()` / `_physics_process()` simulation advancement;
- sorts emitters by stable ID;
- rebuilds from relevant revisions/inputs;
- keeps camera/GPU out of physical queries.

Slice B presentation:

- also consumes zero WHEN ticks;
- builds bounded current-window image maps;
- performs visual smoothing in GPU canvas shaders;
- keeps gameplay truth in Slice A.

Slice B green-run Slice A benchmark:

`PHYSICAL_LIGHTING_REBUILD_AVG_US=4085.20`

Approximately **4.09 ms average** for the representative 17×17 changing-flashlight physical rebuild on the GitHub runner.

The full 80×96 canonical critique runtime passed startup with Slice B enabled. That is not a claim that arbitrary population-scale many-light scenes are free; many moving emitters remain a profiling/caching seam before large NPC/infected populations.

---

## 15. Verification

Dedicated smokes:

- `game/scripts/ci/PhysicalLightingSmoke.gd`;
- `game/scripts/ci/PhysicalLightingPresentationSmoke.gd`.

Dedicated workflow/context:

- `.github/workflows/physical-lighting.yml`;
- `verify/system27-physical-lighting`.

Slice A coverage includes enclosure/daylight, portals, structure/opening transmission, flashlight shadows, atmosphere behavior, source determinism, zero-tick physical queries and light-driven useful-range behavior.

Slice B coverage proves:

- both shaders import under Godot 4.7.1;
- multiply and glow light maps build at tactical-field size;
- luminance contrast from the physical backend reaches presentation;
- local/portal energy reaches glow presentation;
- rain wetness reaches the shader input;
- fog scatter reaches the shader input;
- a real backend wall shadow produces lower visual local-light/glow energy behind the wall;
- presentation refresh consumes zero WHEN ticks;
- DEV flashlight origin/facing follows the controlled actor's real WHAT placement;
- System 25 and System 23 regressions remain green;
- canonical demo boots with the full Slice B stack.

On executable head `a7a95466e70853d9abbd5de9ca1a1d5610672eaf`, all twelve required exact-head contexts were green, including standalone System 23 and Pages.

---

## 16. Slice C — observer acquisition

Future Slice C applies the existing target-light contract to current visual acquisition.

Required behavior:

- geometric LOS remains the maximum candidate envelope;
- darkness prevents sufficiently distant geometric candidates from becoming current acquired truth;
- increasing physical illumination expands useful range toward the lit target;
- local light cannot reveal through opaque geometry;
- another source/actor can illuminate a target for an observer;
- only actually acquired current truth refreshes System 23 memory;
- hidden local-light changes do not update stale REMEMBERED facts;
- future NPC/infected observers consume the same physical-light/perception contract rather than night-vision cheats.

Potential later refinements such as `NONE / SILHOUETTE / DETAIL`, dark adaptation and observer-specific acuity belong to observer perception rather than physical light truth.

---

## 17. Future provider/refinement seams

System 27 is ready for later truth from:

- Weather / atmosphere;
- explicit Roof/Shelter/Construction;
- curtains/blinds/boards/broken windows;
- prop/furniture optical-material classification;
- electrical grid / switches;
- generators;
- portable battery lights;
- fire/flares/glow sticks;
- vehicle headlights;
- smoke/particulates;
- lightning events;
- season/latitude solar profiles.

Those providers determine source/environment state. They do not replace System 27 as illumination owner.

---

## 18. North-star fit

The implementation follows the mini-Zomboid rule:

- no photon/path-traced global simulation;
- no hidden full 3D physics world;
- no sprite-pixel lighting physics;
- causal physical illumination, occlusion and presentation remain interconnected.

The core gameplay question remains:

> **What is actually illuminated here, how far can this observer physically make things out, and what tactical risk does creating light introduce?**
