# Tick Survival Lab — System 27 Physical Lighting / Illumination / Shadows

Status: **IMPLEMENTED — Slice A physical illumination backend; Slices B/C remain future implementation**

Slice A approval, 2026-08-23:

> **“ok lets start with A. the vision cone shrinks and grows with light level.”**

First fully green Slice A executable head:

`b43b9d02d206658ce8155e485a2ab72be454cc0e`

Exact-head context:

`verify/system27-physical-lighting`

Core rule:

> **Light is physical. Vision is observer-specific. Rendering visualizes lighting; gameplay and AI never read rendered pixels to decide what is illuminated.**

System 27 is the authoritative physical-lighting domain. It deliberately separates deterministic headless illumination truth from rich visual presentation.

---

## 1. System intent

Lighting is an identity system rather than a global tint.

The complete System 27 direction is intended to support:

- smooth dawn/day/dusk/night from System 25;
- weather/atmosphere affecting useful light and presentation;
- physical indoor/outdoor differences;
- daylight through windows/open doors;
- artificial light spilling through openings;
- flashlights/headlamps as physical directional sources;
- lamps, streetlights, neon, vending machines and later fire/vehicles;
- physical tactical shadows;
- later rich 2D shadow/glow/beam presentation;
- illumination-dependent visual perception;
- the same physical lighting truth for player and future NPC/infected observers.

System distinction:

- **System 23 geometry** answers whether a candidate lies in unobstructed observer LOS;
- **System 27 lighting** answers how much useful physical light reaches a world cell;
- **observer perception** later combines geometry + illumination + observer capability into acquired knowledge.

---

## 2. Slice status

### Slice A — IMPLEMENTED

Authoritative headless illumination backend:

- `AtmosphericOptics.gd`;
- `LightEmitterProfile.gd`;
- `LightEmitter.gd`;
- `IlluminationSample.gd`;
- `VisionLightRangePolicy.gd`;
- `PhysicalLightingService.gd`;
- `PhysicalLightingSmoke.gd`;
- `.github/workflows/physical-lighting.yml`.

Slice A is simulation truth only. It does **not** add visible darkness, Godot lights, glow, shadow sprites/shaders, live flashlight item use or live System 23 illumination gating yet.

### Slice B — NOT IMPLEMENTED

Rich visual lighting/shadow/glow presentation.

### Slice C — NOT IMPLEMENTED

System 23 illumination-aware current visual acquisition and the neutral observer seam future AI consumes.

These remain bounded later implementation slices under this one System 27 contract.

---

## 3. Ownership

System 27 owns:

- deterministic bounded illumination fields;
- normalized useful luminance queries;
- broad physical light tint;
- dominant incoming light direction summary;
- glare/scatter summaries;
- semantic local-emitter profiles;
- sky/direct/local light composition downstream of System 25;
- current structure/door/window optical transmission;
- Candidate 001 enclosure/sky-exposure derivation;
- outdoor-light portal transfer into enclosed space;
- deterministic direct local-light shadow/occlusion truth;
- small diffuse local spill approximation;
- atmospheric-optics input contract;
- light-derived useful-vision-range policy;
- future presentation descriptors/seams.

System 27 reads but does not own:

- WHERE coordinates/facing/footprints/structure geometry;
- WHAT terrain/entities/placements;
- Door State;
- System 25 time/daylight;
- future Weather state;
- future power/battery/fuel/switch truth;
- future equipment/use state that determines whether portable lights are active.

System 27 does **not** own:

- System 23 visual memory/observer knowledge;
- actor AI decisions;
- weather simulation;
- electrical/grid simulation;
- item-use/toggle actions;
- battery/fuel quantities;
- construction/roof persistence generally;
- rendering as simulation authority;
- save-file orchestration.

Dependency direction:

`WHEN -> System 25 + physical world/source providers -> System 27 -> observer perception -> player/NPC knowledge`

Rendering is downstream of System 27 and never sits in the gameplay truth chain.

---

## 4. `IlluminationSample`

`PhysicalLightingService.illumination_at(cell)` returns deterministic world-space physical light truth independent of camera/GPU.

Candidate fields:

- global cell;
- diffuse sky contribution;
- direct/celestial contribution;
- portal contribution;
- local/artificial contribution;
- normalized useful luminance;
- broad light tint;
- dominant incoming direction where meaningful;
- glare;
- atmospheric scatter;
- world tick;
- WHAT revision;
- Door State revision;
- lighting revision.

Useful luminance is gameplay-relative, not fake calibrated lux, and is clamped to `[0,1]`.

Presentation may later use energy beyond that normalized gameplay scale for bloom/HDR-looking effects without changing physical acquisition rules.

---

## 5. Candidate 001 backend composition

### 5.1 Outdoor light

System 25 remains the clock/daylight owner.

System 27 splits current outdoor light into:

- diffuse sky light;
- direct celestial light.

Candidate shares at full clear daylight:

- diffuse: `0.72`;
- direct: `0.28`.

System 25's night baseline `0.08` remains a low outdoor ambient baseline rather than zero illumination.

### 5.2 Atmosphere

`AtmosphericOptics` is a neutral provider-shaped input. System 27 does not own Weather.

Candidate snapshots currently exist for controlled tests:

- clear;
- overcast;
- rain;
- fog;
- storm.

The contract includes:

- diffuse-sky transmission;
- direct-light transmission;
- local-light transmission/extinction;
- scatter strength;
- tint;
- wet-surface presentation factor;
- visibility-extinction pressure;
- revision.

Important physical distinction:

> Fog can make a beam's scatter more visible while simultaneously reducing the beam's useful distant illumination.

Overcast suppresses direct sunlight much more strongly than diffuse sky light.

---

## 6. Interior / sky exposure

Candidate 001 uses a replaceable structure-envelope approximation until an explicit Roof/Shelter owner exists.

Within a bounded lighting field:

1. perimeter terrain seeds exterior space;
2. flood fill travels through non-structure terrain;
3. structure cells form the enclosure boundary;
4. unreachable ordinary cells are treated as enclosed/roofed baseline cells.

Door/window cells remain part of the envelope for roof classification regardless of whether a door is currently OPEN. Opening the front door therefore does not make the house roof disappear.

This heuristic is intentionally replaceable. A future explicit Roof/Shelter provider may supersede it without changing illumination consumers.

Known limitation: a deliberately roofless enclosed courtyard cannot be distinguished from a roofed room using structure envelope alone.

---

## 7. Portal daylight

Windows and OPEN doors transmit outdoor light into enclosed space.

Candidate transmission:

- window: `0.72`;
- OPEN door: `0.95`;
- CLOSED door: no direct portal transmission;
- wall/unknown structure: no direct portal transmission.

Portal influence decays through an enclosed area with a bounded diffuse transfer pass rather than making the entire building inherit outdoor brightness.

Expected physical ordering is proven:

`clear exterior > window/open-door interior > deep enclosed interior`.

Closing an exterior door removes its open-door portal contribution on the next lighting query/rebuild.

---

## 8. Local emitters

`LightEmitter` is exact active-source truth supplied to System 27.

It contains:

- stable emitter ID;
- origin cell;
- facing;
- semantic `LightEmitterProfile`;
- active state;
- revision.

Source systems remain responsible for whether an emitter is truly active. System 27 does not invent power, battery charge or switch state.

Candidate profile shapes:

- `OMNI`;
- `CONE`.

Initial semantic profile constructors include:

- flashlight;
- lamp;
- streetlight;
- neon.

Profiles define useful range, base luminance, tint, falloff, directional cone width and a small diffuse-spill fraction.

---

## 9. Direct local light / tactical shadows

Physical local-light shadows are deterministic grid truth.

For a candidate cell the solver:

1. checks source range/shape;
2. traces an optical path from source to candidate;
3. applies source falloff;
4. applies atmosphere distance extinction;
5. applies wall/door/window transmission;
6. stores physical local-light contribution if energy remains.

Rules:

- wall blocks direct local light;
- CLOSED door blocks direct local light;
- OPEN door transmits strongly;
- window transmits at reduced strength;
- unknown/malformed structure fails dark/conservatively;
- direct light does not bend around corners like System 26 sound.

A small one-cell diffuse spill approximation may soften nearby darkness.

A bug caught by the first System 27 contract established an important invariant:

> **An opaque wall/closed-door surface may itself be illuminated, but it may not relay diffuse spill through itself into the space behind it.**

That correction is part of the first fully green executable head.

---

## 10. Light-driven useful vision range

User requirement:

> **“the vision cone shrinks and grows with light level.”**

Slice A implements the physical policy consumed by later observer integration.

Crucial rule:

> **Useful range is based on the physical illumination of the candidate/target cell, not merely the light level at the observer's feet.**

Standing under a lamp therefore does not grant long-distance vision into an unlit room.

Candidate 001 policy:

- current geometric maximum remains `12` cells;
- zero-light useful range floor is `2` cells;
- System 23 radius-1 near awareness remains protected;
- normalized target luminance is converted with a `sqrt(luminance)` response;
- increasing target illumination monotonically expands useful range;
- luminance `1.0` restores the full geometric maximum;
- local light can expand useful range only toward cells that it actually illuminates.

Public Slice A queries:

- `effective_vision_range_at(target_cell, geometric_max_range, near_awareness_radius)`;
- `target_within_light_range(origin, target, geometric_max_range, near_awareness_radius)`.

Slice A does **not** yet mutate System 23's live visible-cell set. That is Slice C so observer knowledge/memory stays owned by Perception.

---

## 11. Why the vision cone is not the flashlight cone

The geometric System 23 FOV and physical light are separate facts.

Future acquisition will conceptually be:

`geometric LOS candidate -> target illumination -> observer capability -> current visual acquisition`

A flashlight is therefore a physical directional source inside/across the larger potential visual field. Another actor's light may illuminate a target for the player, and later the same fact may help an infected observer acquire that target.

No observer or AI should query rendered pixels or receive hidden emitter identity merely because System 27 knows it.

---

## 12. Determinism / time / caching

System 27:

- consumes zero WHEN ticks itself;
- has no `_process()` or `_physics_process()` simulation advancement;
- uses System 25 current tick-derived daylight;
- rebuilds cached topology/light results on relevant revisions/inputs;
- sorts emitter descriptors by stable ID so caller ordering does not change results;
- keeps camera/GPU out of physical queries.

Current detailed field is explicitly bounded. Future active-world/AI orchestration may request fields outside the camera, while distant coarse simulation may later use region summaries.

Technical stream-region boundaries must never become physical darkness boundaries.

---

## 13. Performance

Focused CI fixture:

- 17×17 detailed field;
- enclosed room;
- window + stateful door;
- repeatedly moving/revision-changing flashlight.

First fully green executable head measured:

`PHYSICAL_LIGHTING_REBUILD_AVG_US=4297.78`

That is approximately **4.30 ms average** for the representative bounded rebuild on the GitHub runner, below the current 50 ms regression ceiling.

This is not a claim that arbitrary full-world lighting is free. Large actor populations and many moving lights require later profiling/caching before scale assumptions are made.

---

## 14. Slice A verification

Dedicated smoke:

`game/scripts/ci/PhysicalLightingSmoke.gd`

Dedicated workflow/context:

`.github/workflows/physical-lighting.yml`

`verify/system27-physical-lighting`

The contract proves:

- project parses under Godot 4.7.1;
- clear daytime exterior is bright;
- enclosed interior is materially darker;
- window portal increases interior daylight;
- OPEN door portal increases interior daylight;
- closing a door reduces that portal contribution;
- a wall creates a direct flashlight shadow;
- window transmits flashlight at reduced strength;
- CLOSED door blocks flashlight transmission;
- OPEN door restores flashlight transmission;
- opaque surfaces do not leak diffuse light through themselves;
- fog reduces useful distant local light;
- fog increases scatter descriptor;
- overcast suppresses direct sunlight strongly;
- multiple emitters compose deterministically regardless of caller ordering;
- lighting queries/rebuilds spend zero WHEN ticks;
- useful vision range grows monotonically with target luminance;
- zero light gives Candidate 001 range 2;
- full light restores range 12;
- lighting a target can expand useful range toward it;
- System 25 regression remains green;
- System 23 regression remains green;
- canonical demo still boots.

On executable head `b43b9d02d206658ce8155e485a2ab72be454cc0e`, all twelve required exact-head contexts were green, including System 27, standalone System 23 and Pages.

---

## 15. Slice B — rich physical-light presentation

Future Slice B should visualize System 27 rather than invent separate light truth.

Target presentation includes:

- live-world darkness/light composite;
- semantic `LightOccluder2D`-style shadow geometry or equivalent custom shader/SDF path;
- flashlight cone/hotspot/spill;
- moving shadows behind major props;
- window/open-door light shafts/spill;
- lamps/streetlights;
- emissive cores;
- neon color wash + soft halo;
- fog beam/halo scatter;
- rain/wet-surface colored reflection cheats;
- stylized time-dependent outdoor shadows;
- Web/mobile culling/performance controls.

Semantic world geometry remains the shadow source. Sprite alpha pixels are not physics.

---

## 16. Slice C — System 23 / observer integration

Future Slice C applies the implemented range/illumination contract to current visual acquisition.

Required behavior:

- geometric LOS remains the maximum candidate envelope;
- darkness can prevent a distant candidate inside LOS from becoming current acquired truth;
- increasing physical illumination expands useful range toward that lit target;
- local light cannot reveal through opaque geometry;
- another source/actor can illuminate a target for an observer;
- UNSEEN presentation remains true black;
- only actually acquired current truth refreshes System 23 memory;
- hidden local-light changes do not update stale REMEMBERED facts by themselves;
- future NPC/infected observers consume the same physical-light/perception contract rather than night-vision cheats.

Potential later refinement: `NONE / SILHOUETTE / DETAIL` acquisition tiers and observer dark adaptation. Those are perception mechanics, not Slice A physical-light state.

---

## 17. Hidden-light memory rule

System 27 must not become an information leak through System 23.

- globally known daylight/weather may affect broad remembered presentation;
- an unseen local lamp turning on/off must not remotely refresh stale remembered room truth;
- if hidden light physically spills onto a currently acquired visible cell, that spill is observable there;
- observing spill does not automatically reveal the hidden source entity/location.

---

## 18. Future provider seams

System 27 is ready to receive later truth from:

- Weather / atmosphere;
- explicit Roof/Shelter/Construction;
- curtains/blinds/boards/broken windows;
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

## 19. North-star fit

Lighting is explicitly an identity-depth system in the North Star.

The implementation follows the mini-Zomboid rule:

- no photon/path-traced global simulation;
- no hidden full 3D physics world;
- no sprite-pixel lighting physics;
- but causal physical relationships remain.

The core gameplay question is:

> **What is actually illuminated here, how far can this observer physically make things out, and what tactical risk does creating light introduce?**
