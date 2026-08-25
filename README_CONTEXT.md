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

## Current playable world

The canonical DEV/playable composition is the **complete streamed island**.

- Global bounds: 1792×1792 tactical cells (`Rect2i(232,1232,1792,1792)`).
- System 00D `temperate.island.region` v1 adds deterministic LAND / SHORE / OCEAN over the proven rural-v6 settlement/road/hydrology skeleton.
- Five globally connected sites remain deliberately proven: one `rural.crossroads`, one `smalltown.center`, and three `rural.scattered` hamlets.
- System 00F materializes settlement sites, exact river/watercourse corridors and island-surface sources as non-overlapping logical source families.
- Technical streaming uses 128×128 regions with active radius 1 and follows the controlled survivor. Technical regions are performance configuration, never world identity.
- Ocean and ordinary river water are non-traversable; only explicit globally planned bridge crossings become traversable road deck.

The complete-island composition was first proven on `3f1a98c3daea879cf7ffdbea717d88461e39438f`.

---

## Current canonical stack

- **00A WHERE** — global integer-cell spatial truth.
- **00B WHAT** — authoritative persistent current world.
- **00C WHEN** — deterministic variable-duration tick/action/pause kernel.
- **00D Global World Planning** — rural v6 + complete island v1.
- **01–18** — collision, movement, locomotion, art/rendering, doors, hands, inventory, timed transfer, actor-status scaffolds, carry, HUD/player shell, run/exertion and door passage.
- **19 Building Generation** — finalized 24-archetype one-story library.
- **20 Local Area Generation** — ten area profiles / seven environment palettes, including real river/bridge physicalization.
- **00F Streaming / Materialization** — settlement + countryside + island surface + watercourse logical sources; materialization one-way, activation reversible.
- **21 Camera / 22 Large-Area DEV Critique** — implemented.
- **23 Perception / LOS / Fog Memory** — observer-specific VISIBLE / REMEMBERED / UNSEEN truth with physical-light/atmosphere-aware acquisition.
- **24 World Loot / Searchable Containers** — persistent virgin loot, timed search/TAKE/STORE; shared System-29 reach.
- **25 World Time / Ambient Daylight** — authoritative-tick-derived scenario clock/daylight.
- **26 Spatial Sound / Hearing** — physical propagation, listener-specific uncertain hearing, Weather background masking.
- **27 Physical Lighting** — headless illumination/shadows/portals, Weather optics/wetness and transient physical lightning.
- **28 Weather / Atmosphere** — **IMPLEMENTED: Slices A+B+C + P3 GPU presentation revamp**.
- **29 World Interaction Affordance / Reach** — **IMPLEMENTED Candidate 001**, Roadmap Phase 1A.
- **Performance Architecture Gate** — **IMPLEMENTED P0/P1/P2 + Weather P3**: domain revisions/batching, dependency-correct invalidation, telemetry and GPU Weather presentation.

System-29 first green playable head: `5b88d9172df51561ea760913873f62bd2cdc422a`.

P0/P1/P2 first fully green performance executable: `0398a2a49d84e6067f7610727aecacf4c05fe41f`.

Weather P3 final exact executable is the canonical `main` head carrying this context after full verification.

---

## Core rules

1. System 00D owns global coherence; local/stream partitions do not invent world-spanning truth.
2. System 20 turns global facts into local physical areas; System 19 owns building interiors.
3. Generation creates virgin truth once. WHAT and typed mechanic stores own current reality afterward.
4. Technical streaming activation is not world existence.
5. Materialization is one-way; activation is reversible.
6. Art/rendering is presentation, never physics.
7. Phone/Safari is first-class.
8. Perception knowledge is observer-specific and never substitutes hidden current truth for stale memory.
9. WHEN owns integer simulation ticks only; System 25 interprets them as scenario-local time.
10. **Sound is physical; hearing is an estimate.**
11. **Light is physical; vision is observer-specific.** Gameplay/AI never read rendered pixels as lighting truth.
12. **Weather is simulation truth; weather animation is presentation.**
13. Weather feeds Lighting/Hearing through neutral environment seams; it is not a second light/perception/sound engine.
14. **Continuous Weather graphics are one screen-space GPU atmosphere surface. Camera movement is not Weather animation work.**
15. Rain shelter rejection may read cached world truth only to decide where rain appears; it does not make rain animation world-driven.
16. Lightning is a real WHEN event; its physical flash feeds System 27 while its visible bolt is presentation tied to the same event.
17. Current lightning has no strike cell, therefore there is no fake spatial thunder/damage/fire.
18. **Fatigue is the stamina/endurance concept. There is no separate stamina meter.**
19. **Interaction highlights explain real available actions; they never create action truth.**
20. **A world mutation may update truth many times; expensive consumers wake only for the domains and completed batches they actually depend on.**

---

## Current System 28 Weather truth

Physical Weather remains unchanged by P3:

- clear / overcast / rain / storm / fog are deterministic WHEN-driven physical states with continuous values underneath;
- wetness is analytic from authoritative world ticks;
- quantized environment revisions feed System 27 optics/visibility and System 26 hearing masking;
- decision/hard pause freezes physical Weather automatically;
- storm lightning is a deterministic real WHEN event with one-tick physical flash and real System-27 portal/shadow consequences;
- thunder/damage/fire remain deferred until honest strike geography exists.

P3 changes **presentation only**:

- one `WeatherPresentationRenderer` owns exactly one `WeatherAtmosphereSurface`;
- one CanvasItem shader renders cosmetic rain/fog/debris/lightning;
- rain/fog animation uses shader `TIME`, not a CPU redraw loop;
- base Weather art scale is **2 screen pixels**, down from the former forced 4 px minimum;
- rain cadence is 14 visual frames/sec; fog drift cadence is 4 visual frames/sec;
- the former CPU loops for up to 180 rain candidates and 36 fog rectangles are removed;
- rain no longer performs a screen→world conversion and `SkyExposureQuery` call per candidate;
- shelter is one cached nearest-neighbor texture, one texel per current render-window tactical cell;
- camera movement updates only shelter-mapping shader uniforms: **0 Weather redraws, 0 shelter-texture rebuilds, 0 WHEN ticks**;
- CPU presentation housekeeping is 10 Hz and limited to <=3 debris records, lightning lifetime and a cheap shelter-revision poll;
- clear/ordinary overcast hides the atmosphere surface when no debris/lightning is active.

Focused P3 proof:

- `WEATHER_CPU_CONTINUOUS_REDRAWS=0`;
- `WEATHER_OVERLAY_CAMERA_REDRAWS=0` after forty camera changes;
- `WEATHER_OVERLAY_MASK_REBUILDS=1` for the fixture's single initial mask;
- clear useful visual range 12 cells / representative fog range 5;
- representative storm hearing mask +19;
- lightning physical fixture remains 0.025 → 0.845 exterior and 0.356 through a real window portal.

Exact-head owner: `verify/system28-weather`.

---

## Current performance architecture truth

P0/P1/P2 remain implemented:

- WHAT retains global authoritative revision plus terrain/per-placement-channel revisions;
- explicit bulk WHAT transactions publish compact completed `WorldChangeBatch` summaries;
- System 00F brackets rollback-safe materialization with those notification batches;
- System 27 lighting geometry and `SkyExposureQuery` key to terrain + STRUCTURE truth rather than every WHAT mutation;
- ACTOR and ordinary OBJECT churn do not invalidate static lighting/shelter geometry;
- Systems 23/29 coalesce explicit streaming bursts into bounded local refresh decisions;
- System 24 suppresses intermediate offer-provider broadcasts inside those batches;
- live DEV telemetry exposes streaming, lighting, perception, interaction, Weather CPU housekeeping/mask work and shelter rebuilds.

P0/P1/P2 first fully green executable `0398a2a49d84e6067f7610727aecacf4c05fe41f` completed 42/42 associated workflow runs and all 15 required exact-head contexts.

P3 now removes the remaining Weather-specific CPU/canvas presentation path. If human Safari testing shows Weather remains visually continuous but player movement still starves render frames, the next measured target is the synchronous action/streaming path—not additional Weather complexity. P5 predictive/amortized streaming remains deferred unless measurements justify it.

Exact performance context: `verify/performance-architecture`.

---

## Active roadmap work — Phase 1

1A. **Interaction affordance + reach** — COMPLETE: System 29 Candidate 001.

1B. **Item freshness/spoilage** — NEXT DESIGN TARGET: typed per-instance freshness, analytic authoritative-time aging, future refrigeration-rate seam, no per-item tick loop.

1C. **Semantic inventory/menu icons** — low-resolution deterministic icon vocabulary.

1D. **Large/multi-cell object visual geometry** — presentation-owned draw span/pivot/overhang independent from collision footprint.

1E. **Content expansion/integration** — more perishables, ordinary items and world props/fixtures/vegetation.

**Current gate: human iPhone/Safari acceptance of the P3 Weather/performance build. After acceptance, the next bounded work is DESCRIBE Phase 1B. 1B implementation is not pre-authorized.**

---

## Physical-survival correction

Roadmap Phase 4 final physical set is hunger, thirst, sleep pressure/exhaustion, health/injury and **fatigue**.

**Fatigue is the stamina/endurance concept. Do not add a parallel stamina state.** Fatigue is short-horizon exertion/endurance pressure; sleep pressure/exhaustion is the separate long-horizon need.

---

## Canonical roadmap through Beta

1. Items/readability — 1A complete; 1B–1E ahead.
2. Crafting.
3. Three-tier Power + Water; standalone wastewater gameplay removed.
4. Physical survival/health — hunger, thirst, sleep/exhaustion, health, fatigue.
5. Moodlets — comfort, fear, boredom and escalating need-state consequences.
6. Skills/interactions — Awareness, Sneak, First Aid, Cooking, Carpentry, Mechanical, Electrical, Fishing, Farming; real powered-object state/interactions.
7. Vehicles — cars, trucks, motorcycles, bicycles, skateboards; later physical vehicle modification.
8. Actor/NPC AI + combat + causal outbreak.
9. Final graphics/UI overhaul → Beta.

Save/load, schema handling, profiling and persistence-backed streaming eviction remain cross-cutting engineering gates inserted when required.

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
- `verify/system29-interaction-affordance`
- `verify/performance-architecture`
- `verify/pages-deploy`
