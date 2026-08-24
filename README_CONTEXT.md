# Tick Survival Lab — Current Context

> Read `PROJECT_NORTH_STAR.md`, `ROADMAP.md`, `README_SOPS.md`, `SYSTEM_DESIGNS/README.md`, current `main`, and the relevant system design before repository changes.

## Game

> **Ultima-style turn-based mini Zomboid.**
>
> **Mini means reduced complexity, not reduced consequence or mood.**

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Live build: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

Golden archaeology commit: `1763958f44eb7f855fd49944c00d1ffe608c0abe`.

Canonical roadmap: `ROADMAP.md`.

---

## Current canonical stack

- **00A WHERE** — global integer-cell spatial truth.
- **00B WHAT** — authoritative persistent current world.
- **00C WHEN** — deterministic variable-duration tick/action/pause kernel.
- **00D** — `temperate.rural.region` v6 global planning.
- **01–18** — collision, movement, locomotion, art/rendering, doors, hands, inventory, timed item transfer, actor status scaffolds, carry, HUD/player shell, run/exertion and door passage.
- **19 Building Generation** — finalized 24-archetype one-story library.
- **20 Local Area Generation** — ten area profiles / seven environment palettes.
- **00F Streaming / Materialization** — settlement + dry-countryside logical sources; one-way materialization, reversible activation.
- **21 Camera** / **22 Large-Area DEV Critique Runtime** — implemented.
- **23 Perception / LOS / Fog Memory** — geometric facing LOS, physical-light/atmosphere-aware current acquisition, true-black unexplored fog, stale remembered environment/static furniture, last-seen actors and auditory presentation.
- **24 World Loot / Searchable Containers / Scavenging** — persistent virgin loot, timed search, timed TAKE/STORE and playable scavenging UI.
- **25 World Time / Ambient Daylight** — authoritative-tick-derived scenario clock and smooth outdoor daylight baseline.
- **26 Spatial Sound / Hearing** — physical acoustic propagation, listener-specific hearing/localization, yellow onomatopoeia cues and Weather masking seam.
- **27 Physical Lighting / Illumination / Shadows** — headless physical illumination, rich presentation, illumination-aware observer acquisition, bounded-query optimization, Weather optics and transient lightning input.
- **28 Weather / Atmosphere** — **Slices A+B+C implemented**: deterministic WHEN-driven Weather, analytic wetness, screen-space low-res atmosphere, real lighting/visibility/hearing consequences and deterministic physical lightning.

---

## Core rules

1. System 00D owns global coherence; local/stream partitions do not invent world-spanning truth.
2. System 20 turns global facts into local physical areas; System 19 owns building interiors.
3. Generation owns virgin creation only. WHAT and typed mechanic stores own current reality afterward.
4. Technical streaming activation is not world existence.
5. Materialization is one-way; activation is reversible.
6. Art/rendering is presentation, not physics.
7. Phone/Safari remains first-class.
8. Perception knowledge is observer-specific and never substitutes hidden current truth for stale memory.
9. WHEN owns integer simulation ticks only; System 25 interprets them as scenario-local clock time.
10. **Sound is physical; hearing is an estimate.**
11. **Light is physical; vision is observer-specific.** Gameplay/AI never reads rendered pixels as lighting truth.
12. Geometric LOS is a maximum candidate envelope; physical illumination/atmosphere may reduce current acquisition inside it.
13. Player sound presentation never gains exact hidden source truth.
14. **Weather is simulation truth; weather animation is presentation.**
15. Weather feeds Lighting/Hearing through neutral environment seams; it does not become a second light/perception/sound engine.
16. **Weather graphics are screen-space atmosphere. Camera movement itself is not Weather work.**
17. Lightning is a real WHEN event; its physical flash feeds System 27, while its bolt is presentation tied to the same event.
18. Current lightning has no strike cell, therefore there is no fake spatial thunder/damage/fire yet.

---

## Current System 23 perception truth

Visual states:

- `UNSEEN` — true black, never acquired;
- `REMEMBERED` — stale last-acquired observer facts;
- `VISIBLE` — current truth that passed geometric LOS and physical acquisition.

Candidate geometry remains a 12-cell, 120-degree forward cone plus radius-1 all-around near awareness. Memory schema remains v2.

System 23 exposes neutral `VisualAcquisitionProvider`; the live composition injects System 27's `IlluminationVisualAcquisitionProvider`.

Only acquired cells refresh environment/actor memory. A target may be geometrically clear yet remain UNSEEN/REMEMBERED because it is too dark or too strongly extinguished by atmosphere. Opaque geometry still blocks first.

Representative Weather fixture: clear bright range 12 cells; representative fog reduces the same bright-condition useful range to 5 cells.

Roadmap Phase 6 Awareness/Sneak must extend observer/signal contracts rather than bypass them. Roadmap Phase 8 NPC AI must consume observer knowledge rather than hidden truth.

Exact-head owner: `verify/system23-perception`.

---

## Current System 24 loot truth

> **Loot exists before you search for it.**

Searchable furniture is real System 11 container truth. Deterministic `item.*` entities are created once during virgin source initialization; System 24 owns provenance while System 11 owns current contents. Search and TAKE/STORE spend WHEN time and external acquisition respects System 13E carry limits.

Roadmap Phase 1 adds spoilage, icons, proximity interaction highlighting and broader object content. Phase 2 adds crafting from real items.

Exact-head owner: `verify/system24-loot`.

---

## Current System 25 world-time / daylight truth

Candidate 001 uses 5 ticks/second, starts day 0 at 08:00:00, dawn 05:30–07:30, day 07:30–18:30, dusk 18:30–20:30 and night baseline 0.08. Time derives directly from `world_tick`; hard pause freezes it automatically.

System 27 consumes daylight downstream. System 28 uses the same WHEN clock and modulates it through Weather optics/lightning without owning a second physical clock.

Exact-head owner: `verify/system25-world-time-light`.

---

## Current System 26 spatial-sound truth

> **Sound is physical. Hearing is an estimate.**

Exact transient sound truth is separated from listener observations. Material-aware propagation reads current WHAT + Door State; survivor hearing derives from existing skills/needs; localization uncertainty cannot flip true actor-relative front/rear/left/right signs; observation age uses WHEN ticks only.

Recognized player-facing sounds prefer onomatopoeia:

- Walk: `NOISE -> *scuff* -> *step step*`;
- Run: `NOISE -> *thump thump* -> *step step step*`;
- normal door: `NOISE -> *thunk* -> *creak*`;
- loud door: `NOISE -> *BANG* -> *SLAM*`.

Weather rain/wind is competing background noise: propagation-cost addition remains 0, detection threshold rises, localization degrades modestly, and ordinary rain pixels create no `SoundEmission`.

Representative storm fixture: +19 detection-threshold addition.

Current lightning intentionally creates no thunder because the implemented event has no honest strike cell. A future geographic strike can feed ordinary System 26 propagation/delay/localization.

Exact-head owner: `verify/system26-spatial-sound`.

---

## Current System 27 physical-lighting truth

> **Light is physical. Vision is observer-specific. Rendering visualizes lighting; gameplay and AI never read rendered pixels to decide what is illuminated.**

Implemented physical facts include semantic flashlight/lamp/streetlight/neon emitters; per-cell sky/direct/portal/local luminance, tint, direction, glare and scatter; enclosure/portal treatment; structure light transmission/shadows; and target-condition useful-range policy.

Weather feeds continuous optics:

- cloud/overcast suppresses direct sky harder than diffuse sky;
- rain adds moderate loss/scatter/extinction;
- storm strongly suppresses direct sky;
- fog produces strong scatter/extinction;
- real Weather wetness drives restrained wet-surface response.

Slice C adds transient `AtmosphericOptics.transient_sky_light` from the real LightningEvent.

Verified physical lightning fixture:

- storm-night exterior before flash: **0.025**;
- same exterior during flash: **0.845**;
- roofed interior through real window portal: **0.356**.

The bounded 80×96 / four-light regression remains 7,680 field cells, 1,676 emitter candidates and 688 optical-ray candidates.

Roadmap Phase 3/6 powered fixtures must feed actual emitter state into this owner; emissive art alone remains non-physical.

Exact-head owner: `verify/system27-physical-lighting`.

---

## Current System 28 Weather / Atmosphere truth

> **Weather is simulation truth; weather animation is presentation.**

Slices A+B+C are implemented.

### Physical Weather

`WeatherService` owns scenario-wide clear/overcast/rain/storm/fog state, continuous precipitation/cloud/fog/wind fields, analytic wetness, quantized environment revision, deterministic transitions and deterministic lightning.

There is no per-tick Weather loop. One meaningful profile transition is scheduled through WHEN; state/wetness are analytically derived from authoritative tick position.

Weather snapshot schema is **v2**, including scheduled/active lightning state.

### Screen-space presentation

`WeatherPresentationRenderer` remains one low-overhead owner with no per-particle child Nodes.

Caps:

- 20 Hz / 50 ms active atmosphere cadence;
- max four cosmetic catch-up steps;
- virtual axis <=256;
- max 180 rain candidates;
- max 36 fog patches;
- max 3 cosmetic debris records.

Rain/fog/debris are now explicitly a **screen-space overlay**. Camera movement does not redraw, clear, phase-shift or reseed Weather. Origin-only render-window movement also leaves the atmosphere alone.

Focused regression: `WEATHER_OVERLAY_CAMERA_REDRAWS=0` after forty rapid camera-position updates.

Rain may still map a current screen sample to a world cell for shelter rejection. Weather remains below System 23, so shelter suppression cannot reveal hidden structure truth.

### Physical environment integration

Weather drives:

- System 27 atmospheric optics;
- real wetness into wet-surface lighting response;
- physical visibility extinction in observer acquisition;
- System 26 rain/wind detection/localization masking.

Cosmetic animation causes zero physical Lighting/Perception recomputes.

### Lightning

Storms schedule deterministic lightning through WHEN. Candidate normal delay is 30–120 ticks. Physical flash duration is one WHEN tick.

The same event supplies:

- stable ID;
- start/end tick;
- normalized intensity;
- deterministic bolt seed;
- transient physical System 27 sky light;
- stable-seeded low-res bolt presentation.

The visual bolt has a short ~0.32 s cosmetic envelope and may visually outlast the one-tick physical flash without extending physical illumination.

DEV `STRIKE` schedules a real future lightning event and is valid in storm Weather.

No thunder/damage/fire is faked until lightning gains real strike geography and those real owners exist.

### DEV controls

Rural Crossroads intentionally begins in RAIN for critique. DEV controls expose CLR, OVR, RAIN, STM, FOG, STRIKE and BLOW LEAF.

The panel now sits below the existing STATS / INVENTORY / MENU header row so it is not hidden by the player-shell buttons.

### Verification

First fully green executable Weather C head:

`21014fe5915e47344b4b8d5f48e52fa69c386254`

Focused outputs:

- `WEATHER_B_CLEAR_RANGE=12`;
- `WEATHER_B_FOG_RANGE=5`;
- `WEATHER_B_STORM_HEARING_MASK=19`;
- `WEATHER_OVERLAY_CAMERA_REDRAWS=0`;
- `WEATHER_C_LIGHTNING_BEFORE=0.025`;
- `WEATHER_C_LIGHTNING_FLASH=0.845`;
- `WEATHER_C_LIGHTNING_PORTAL=0.356`;
- `WEATHER_C_LIGHTNING_SEED=629519319`.

All 13 required executable-head contexts were green on that exact head, including `verify/pages-deploy`.

Exact-head owner: `verify/system28-weather`.

---

## Canonical roadmap through Beta

`ROADMAP.md` supersedes older informal ordering.

1. **Items/readability** — spoilage, icons, usable-object/container proximity highlighting, more/multi-cell world objects.
2. **Crafting** — physical recipes, time, real inputs/outputs/workstations.
3. **Power + Water** — three-tier causal infrastructure; standalone wastewater gameplay removed.
4. **Player physical survival/health** — hunger, thirst, sleep/exhaustion, health, stamina; reconcile current fatigue rather than duplicating it.
5. **Moodlets** — comfort, fear, boredom and escalating hunger/thirst/sleep states with real capability/speed consequences.
6. **Skills/interactions** — Awareness, Sneak, First Aid, Cooking, Carpentry, Mechanical, Electrical, Fishing, Farming; migrate away from current generic skill scaffold; ordinary powered objects such as TVs gain real state/light/sound-word interactions.
7. **Vehicles** — cars, trucks, motorcycles, bicycles, skateboards; later Mad-Max-style car/truck modification.
8. **Actor/NPC AI + combat + outbreak** — infected/survivor/follower/raider behavior, all combat, mood/context idle conversations, causal outbreak/population behavior.
9. **Final graphics/UI overhaul** — final button placement, art/readability, item/prop shadows, mobile/desktop polish. **Completion begins Beta.**

Save/load, schema handling, profiling and persistence-backed streaming eviction remain cross-cutting engineering gates inserted when required; they do not change the numbered gameplay order.

---

## Major deferred/migration seams

- Roadmap Phase 1 spoilage/item-content/UI-interaction work;
- crafting;
- three-tier power/water utilities;
- current wastewater global-planning data cleanup/inert status;
- Phase-4 stamina/exhaustion design versus current fatigue scaffold;
- full lethal hunger/thirst/sleep/health consequences;
- Phase-5 comfort/fear/boredom and consequential mood modifiers;
- Phase-6 final skill catalog migration;
- first aid treatment/infection;
- cooking/carpentry/mechanical/electrical/fishing/farming actions;
- powered appliance/TV interactions;
- vehicles/cargo/modification;
- NPC/infected/follower/raider AI;
- combat and firearm/ammunition mechanics;
- 00E population/household/causal outbreak/player story;
- corpse loot/decay;
- persistence-backed streaming eviction;
- lightning strike geography -> thunder/damage/fire;
- calendar date/season/latitude beyond System 25;
- final Beta graphics/UI pass.

---

## Required executable-head contexts

- `verify/system00d-global-world`
- `verify/system00f-streaming-materialization`
- `verify/system19-local-building`
- `verify/system20-local-area`
- `verify/system21-camera-view`
- `verify/system22-area-critique`
- `verify/system23-perception`
- `verify/system24-loot`
- `verify/system25-world-time-light`
- `verify/system26-spatial-sound`
- `verify/system27-physical-lighting`
- `verify/system28-weather`
- `verify/pages-deploy`
