# System 28 Weather P3 — GPU Presentation Revamp — 2026-08-24

## Why this pass happened

Phone/Safari playtesting after the P0/P1/P2 performance gate showed a much better general movement baseline but left one obvious Weather-specific problem: rain/fog appeared to stop during repeated movement and resume when the player stopped. The Weather art also looked too large relative to the tactical pixel art.

The old presentation path was heavier than it needed to be:

- active atmosphere ran a 20 Hz CPU presentation loop;
- rain could inspect up to 180 candidates each redraw;
- each surviving rain candidate converted screen position back to a world cell and consulted shelter truth;
- fog could draw up to 36 CPU rectangles;
- the minimum Weather pixel was forced to 4 screen pixels and could scale larger with the viewport;
- rain streaks were 1–3 of those blocks and the old lightning line inherited the same oversized multiplier.

Physical Weather itself was not the problem and has not been replaced.

## P3 implementation

- Added one persistent `WeatherAtmosphereSurface` with one CanvasItem shader.
- Rain/fog animation now uses shader `TIME` and `SCREEN_UV`; continuous atmosphere requires **zero CPU canvas redraw loop**.
- Reduced the base Weather art unit from the old forced 4 px minimum to **2 screen pixels**.
- Rain uses shorter/thinner 1–2 weather-pixel streaks at a deliberately pixelated 14 visual frames/sec.
- Fog uses the same 2 px base with smaller coherent blocks and a 4 visual frames/sec drift.
- Cosmetic leaf/paper/dust and the visible lightning bolt share the same single atmosphere surface instead of creating separate particle systems.
- Removed the CPU `draw_rain` / `draw_fog` primitive loops entirely.
- Replaced per-raindrop world/shelter queries with one cached nearest-neighbor exposure texture: one texel per current render-window tactical cell.
- Camera movement now changes only `mask_uv_origin` / `mask_uv_scale` shader uniforms. It does not rebuild the shelter texture, reseed rain/fog, advance a Weather phase or request a Weather redraw.
- Reduced remaining CPU presentation housekeeping to 10 Hz: at most three debris records, lightning lifetime and a cheap shelter-cache revision poll.
- Clear/ordinary overcast hides the atmosphere surface completely when there is no cosmetic debris or lightning, avoiding an unnecessary transparent fullscreen shader pass.

## Preserved physical contracts

P3 is presentation-only. It does not change:

- deterministic WHEN-driven Weather profiles/transitions;
- analytic wetness;
- System 27 physical lighting/shadows/portal behavior;
- System 23 atmosphere/light-aware acquisition;
- System 26 rain/wind hearing masking;
- deterministic physical lightning timing/intensity;
- shelter truth ownership or the future Roof/Shelter replacement seam;
- player movement, streaming or action timing.

## Verification

Focused branch verification passed Godot 4.7.1 import/shader compilation plus Weather A/P3, Weather B environment integration, Weather C lightning, System 27 lighting, illumination-aware perception, System 26 sound, System 23 fog/memory and canonical startup.

Representative outputs:

- `WEATHER_CPU_CONTINUOUS_REDRAWS=0`
- `WEATHER_OVERLAY_CAMERA_REDRAWS=0`
- `WEATHER_OVERLAY_MASK_REBUILDS=1` after forty camera changes in the fixture
- clear useful visual range: 12 cells
- representative fog range: 5 cells
- storm hearing threshold addition: +19
- lightning exterior: 0.025 -> 0.845
- lightning through real window portal: 0.356

Focused branch run: `32812289707`.

The canonical executable is the final `main` head carrying this change after the complete required exact-head suite and Pages deployment are green.

## P3B — visual de-tiling / density tuning — 2026-08-24

Post-P3 desktop playtesting confirmed the performance architecture worked, but the finer 2 px rain exposed a different visual flaw: the original shader still selected streaks from a repeating five-row band/phase pattern. At the smaller scale the pattern read as dense horizontal striping rather than irregular rainfall.

P3B keeps the P3 architecture intact and changes shader distribution only:

- **2 px base Weather scale remains unchanged**;
- rain no longer uses the old `floor(cell.y / 5)` / five-row phase lattice;
- rain now uses larger **jittered macro-cells**, with at most one independently phased streak candidate per patch;
- a still-coarser cluster hash biases neighboring patches wetter/drier so density varies across the screen instead of looking uniformly stamped;
- streak position, vertical phase, **1–2 weather-pixel length** and brightness are deterministically varied from the presentation seed;
- medium rain is intentionally much sparser while storm precipitation can still become visibly dense;
- fog replaces aligned rectangular patch selection with staggered rows and small diamond-like pixel clouds;
- no new textures, Nodes, particle systems, CPU redraws, screen-to-world conversions or shelter queries were introduced.

The performance bargain remains exactly P3: one fullscreen atmosphere shader, zero CPU continuous-rain/fog redraw loop, and camera movement changes only shelter-mapping uniforms.

P3B verification additionally locks out the old row-band expressions in Weather CI and requires the jittered-macro/cluster/staggered-fog shader structure to compile under Godot 4.7.1.

### P3B downward-motion correction

Human playtest showed that the first sign-only correction did **not** fix the apparent northward rain motion. The real problem was architectural inside the shader: time was translating the entire hashed rain lookup lattice vertically. As macro-cell identity changed, streaks were replaced/rehashed, so changing the sampling sign did not give a reliable visible fall direction.

The corrected implementation keeps the jittered macro grid fixed in screen space. Each accepted streak now owns an explicit `animated_anchor_y`, calculated as `anchor_y + frame * fall_step` with wrap inside its macro patch. Streak pixels are selected relative to that moving anchor, so the feature itself advances toward increasing screen Y instead of relying on a scrolling lookup-field convention. Horizontal wind still offsets the explicit X anchor.

Weather CI now requires this explicit moving-anchor structure and rejects any temporal `shifted.y +=/-= frame * fall_step` lattice scroll.

This correction changes no rain density, 2 px scale, 1–2 pixel streak length, shelter logic, physical Weather state or P3 performance architecture.

## P3C — deterministic per-cell motif variation — 2026-08-24

Human playtest accepted P3B's scale, density and downward motion but still exposed repetition inside the accepted macro-cells: every populated patch ultimately read as the same single-streak stamp.

P3C keeps the P3/P3B architecture and candidate-density decision intact while varying the local motif inside each accepted rain cell:

- each accepted macro-cell deterministically hashes into one of five local motif families: solo, staggered pair, close echo, long accent, or clustered pair;
- primary streak X/Y phase, 1–2 pixel length, brightness, fall-step variant and horizontal wind response vary per cell;
- pair motifs add one dim companion with its own stable X/Y phase, fall-step and wind response;
- the close-echo motif deliberately places its companion near/behind the primary instead of looking like a second copy elsewhere in the patch;
- only the clustered-pair motif in precipitation above 0.72 may add one faint one-pixel third accent;
- accepted macro-cell occupancy and cluster/candidate probability are unchanged; extra visual ink is bounded inside already-accepted cells and companion brightness is reduced;
- every animated streak still advances by explicit increasing screen-Y anchor motion; the hashed macro lattice remains fixed vertically.

P3C adds no CPU work, texture, Node, particle system, world/shelter query, shader pass or draw call. It remains one persistent CanvasItem atmosphere shader at the same 2 px Weather scale.

Weather CI now locks the motif hashes/helper structure as well as the explicit downward-anchor contract.

## P3D — vertical de-grid — 2026-08-24

Human screenshot review after P3C showed that left/right motif variation improved, but the screen still exposed a top-to-bottom cadence. The cause was structural rather than motif count: every macro-column still shared identical `macro_h` row boundaries, and primary X/Y placement was derived from the same detail hash.

P3D preserves all P3/P3B/P3C density and motion rules while breaking that vertical rhythm:

- each fixed macro-column receives a deterministic seed-derived **vertical phase offset** before macro rows are assigned;
- neighboring columns therefore no longer share horizontal macro-row boundaries;
- each macro-cell receives a separate `vertical_hash` for Y placement instead of deriving both X and Y anchors from the same `detail_hash`;
- secondary and tertiary Y anchors mix the independent vertical hash with their existing motif hashes so companion strokes do not recreate the same cadence;
- the column offset and per-cell vertical hash are stable presentation facts, not time-varying noise;
- explicit streak anchors still move toward increasing screen Y, so P3D does not reintroduce lattice scrolling or the old northward-motion bug;
- candidate occupancy, cluster bias, macro width/height, precipitation thresholds, 2 px scale and 1–2 pixel streak language remain unchanged.

P3D adds no CPU work, Nodes, particles, textures, shelter/world queries, loops, allocations, extra shader pass or draw call. It adds only two bounded deterministic hash evaluations to the existing rain fragment path: one for column phase and one for independent per-cell vertical phase.

Weather CI now requires the P3D column phase/staggered-row structure and independent `vertical_hash`, while rejecting the old primary `anchor_y` derivation from `detail_hash`.

## Remaining playtest question

P3D needs one human visual check because automated verification can prove the shader structure, compilation, preserved performance boundaries and downward-motion contract, but cannot judge whether the visible top-to-bottom cadence is sufficiently hidden.

The preferred comparison remains ordinary rain around **50–60% precipitation** at roughly the same zoom as the P3C screenshot. If the vertical rows are no longer obvious and movement remains smooth, Weather presentation is considered accepted. Further tuning should remain inside the existing deterministic shader vocabulary rather than add particles or CPU work.