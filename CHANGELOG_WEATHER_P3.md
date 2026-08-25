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

## Remaining playtest question

P3B needs a human visual check because automated tests can prove architecture and shader compilation but cannot judge whether rain *looks* naturally sparse. The preferred comparison is ordinary rain around **50–60% precipitation** with the DEV/performance panel visible, matching the screenshot that exposed the striping.

If movement remains smooth and the de-tiled distribution reads correctly, Weather presentation is considered accepted. If the whole scene still pauses during movement, the next measured suspect is synchronous action/streaming execution rather than additional Weather complexity.
