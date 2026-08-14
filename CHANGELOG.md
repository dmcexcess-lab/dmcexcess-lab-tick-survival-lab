# Changelog

## Mobile Map Zoom / Clock Direction — 2026-08-14

- Increased tactical tile presentation from 28px to 31px for better mobile readability.
- Added an 18×16 player-following presentation window over the unchanged 20×18 physical map; the camera crops the outer ring but shifts near edges so exits and edge tiles remain reachable.
- Updated map tapping, weather particles, fog, lighting, props and light glows to use the cropped camera coordinates without changing simulation/world coordinates.
- Kept the current calendar-speed constant provisional; documented that action ticks and displayed calendar progression should be separate concepts so combat timing can stay second-scale while days remain playable.

## Snow / Fog / Survivor HUD Refinement — 2026-08-14

- Added `snow` as a fixed weather profile with its own snowfall intensity, cold temperature offset, visibility/light effects, wind, and silent sound-masking hook.
- Added animated snowflakes that continue moving while paused and respect the same outdoor/non-wall weather mask as rain and debris.
- Increased fog presentation density without changing the underlying fog gameplay profile.
- Refined the in-game HUD: replaced ambiguous `FAT %` with survivor-facing `STAMINA %`; raw fatigue remains an internal/deeper-info value.
- Weather is now shown in the in-game HUD only while outdoors.
- Indoor HUD temperature now shows only the local indoor temperature; it no longer exposes outside temperature or outdoor weather.
- Outdoor HUD keeps current temperature and wind speed alongside current weather.
- Expanded deterministic environment smoke coverage to validate the snow profile and cold-temperature behavior.

## Split HUD / Safari Input / Environment Readout — 2026-08-14

- Split the information display into a read-only in-game survivor/world HUD plus a separate `DEV` overlay.
- In-game HUD now shows survivor name, health, fatigue, carry weight/capacity, in-game time/date/weather, local temperature, indoor/outdoor status, outdoor wind speed, and a `Looking at:` readout for the object/tile directly ahead.
- Added HUD-ready base survivor fields to `PlayerActor.gd` without introducing inventory or body-system ownership early.
- Added developer-only world controls for HH:MM, MM/DD, and weather. HH:MM and MM/DD use native `LineEdit` controls so mobile Safari can summon the keyboard; weather remains a touch button and key `6` fallback.
- Added a lightweight deterministic temperature hook from date/time/current weather plus indoor thermal buffering and wind-speed display helpers in `TacticalWeather.gd`; this is not yet weather-pattern simulation.
- Fixed the returning 180-degree-turn / double-move mobile bug by suppressing Safari's synthesized mouse click after a handled touch event, so one physical tap commits one action.
- Weather VFX now reject indoor cells and wall cells. Rain and wind debris are filtered by their current map cell; fog and storm flashes are rendered per outdoor cell rather than across whole structures.
- Moved weather VFX beneath fog-of-war so masking indoor/unseen areas does not reveal room geometry.

## Weather Selector / True Control Grid — 2026-08-14

- Rebuilt the touch deck around shared row constants so `TURN L` and `TURN R` use the exact same middle-row Y coordinate and height.
- Preserved the intentional empty upper-left slot, with `CROUCH` below `TURN L`; the right column remains `FORWARD` / `TURN R` / `BACK`.
- Added an on-screen `WEATHER: <STATE>` touch control in the center column; developer key `6` remains available.
- Strengthened presentation-only weather animation with denser moving rain, broader drifting fog, more windblown debris, and a silent visual storm-flash effect.
- Weather VFX continue running from non-authoritative presentation time while the player is auto-paused or the pause menu is open; simulation weather state still does not advance while paused.

## Weather Foundation / Touch Layout Refinement — 2026-08-14

- Added `TacticalWeather.gd` as the deterministic owner for current weather state and gameplay-facing weather modifiers; no weather-pattern forecasting or transitions are simulated yet.
- Added fixed clear, rain, storm, fog, and wind profiles with precipitation, fog, wind, visibility, ambient-light, and future sound-masking values.
- Integrated weather into perception so poor weather can reduce outdoor/daylight illumination and effective visual range without changing flashlight behavior.
- Added presentation-only rain, drifting fog, and windblown debris VFX driven by real presentation time. They continue animating while the game tree is paused, while authoritative weather state remains frozen.
- Added developer key `6` to cycle weather profiles for testing; the current harness starts in rain so the VFX are immediately visible.
- Added weather invariants to the existing deterministic environment smoke test and made Pages CI require the new weather module.
- Refined mobile controls again: `TURN L` and `TURN R` are now identical size and exactly level; both are slightly shorter. The right column gives all remaining upper space to `FORWARD` and remaining lower space to `BACK`. `CROUCH` remains below `TURN L`, leaving the matching upper-left space intentionally empty.

## Touch Control Layout Correction — 2026-08-14

- Repositioned the FF-style mobile controls to match the intended layout: `FORWARD` above `TURN R`, `BACK` below `TURN R`, and `CROUCH` below `TURN L`.
- Kept all existing touch semantics, timing, perception, pause-menu behavior, and Safari-oriented large hit targets unchanged.

## Mobile Controls / Upright Player Pass — 2026-08-13

- Kept the tactical survivor paper-doll visually upright while facing continues to drive the vision cone, flashlight direction, interaction direction, and action logic.
- Added a small facing indicator so direction remains readable without rotating the body sprite.
- Expanded the logical Web/mobile viewport to 640×844 and centered a slightly smaller tactical board so a dedicated control strip fits cleanly below it.
- Restored FF-style touch controls with large `TURN L` / `TURN R` buttons and smaller `FORWARD`, `BACK`, and `CROUCH` buttons.
- Added forward/back movement that preserves facing; backing up no longer turns the survivor or perception cone.
- Added a timed crouch stance to `PlayerActor.gd`; crouched movement is slower and running is disabled while crouched.
- Added a real pause menu accessible by `MENU` or Escape. Opening it pauses the Godot tree; it can resume or exit to Google.
- Web exit uses same-tab browser navigation for Safari/mobile reliability; desktop falls back to `OS.shell_open`.
- Preserved map tapping and all existing keyboard/developer controls alongside the new touch layout.

## Milestone 0.3A — Visual Perception Restoration — 2026-08-13

- Restored the reusable First Fire tactical atlas presentation into Tick as a clean same-owner asset subset covering ground, walls, doors, windows, props, barrels, and a four-direction survivor sprite.
- Added `TacticalTiles.gd` as the Tick-native atlas renderer instead of continuing with programmer rectangles/text labels.
- Added `TacticalPerception.gd` to own line-of-sight, facing cone, opaque-prop rules, light integration, visible cells, and remembered-cell fog state.
- Wired existing authored light markers into actual per-cell lighting using the already-ported `TacticalLighting.gd` rules.
- Added powered/unpowered environment lights, indoor/outdoor ambient light, window daylight, and a directional flashlight test profile.
- Added real LOS occlusion: walls, closed doors, and tall/opaque obstacles block sight/light; windows transmit sight and daylight.
- Added actual four-direction vision cone plus darkness-limited recognition.
- Added two-state fog of war: unseen cells are nearly black; previously seen cells remain dimly remembered.
- Added developer toggles: `F` flashlight, `4` day/night, `5` power, while preserving existing scheduler proof controls.
- Added deterministic `PerceptionSmoke.gd` coverage for door occlusion, cone direction, directional flashlight lighting, and fog memory.
- Updated CI, roadmap/context, and First Fire reuse audit to make the restored visual/perception layer part of canonical Tick rather than a deferred candidate.

## Milestone 0.2 — Action Execution Model — 2026-08-13

- Replaced the immediate tick-jump prototype with an explicit player action execution state machine.
- Added player-ready auto-pause semantics: the player is ready only before/after an action, never during committed execution.
- Added action start/end ticks, elapsed/remaining progress, phases, status, payload, and deterministic event traces.
- Added committed, resumable, canceled, and forced-failure interruption behavior.
- Added damage interruption hooks; committed actions continue through ordinary damage while resumable actions preserve exact elapsed/phase state.
- Added `TimingDummy.gd`, a minimal autonomous scheduled actor used to prove multiple actors can advance during one player action.
- Added deterministic tie ordering by next action tick then actor ID.
- Expanded scheduler CI to prove a 10-tick action permits two 4-tick dummy actions while a 3-tick action permits none.
- Added a phased reload proof that interrupts at tick 5, preserves the `mag_in` phase, then resumes to completion.
- Added a committed axe-swing proof that ordinary damage does not cancel execution.
- Updated the Web developer harness with READY/status diagnostics and keys 1/2/3 for light/heavy/reload timing demonstrations.

## Design / First Fire Reuse Pass — 2026-08-13

- Added `DESIGN.md` as the durable long-form design document for Tick Survival Lab.
- Added `ROADMAP.md` with ordered milestones from the current tick foundation through persistent island/outbreak simulation.
- Added `FIRST_FIRE_REUSE.md` documenting which First Fire systems are safe to adapt and which architecture must stay out.
- Made player/world separation an explicit design rule: player death can leave the same persistent world available for a new playable survivor.
- Defined real-time-with-auto-pause action execution and committed/resumable/canceled/forced-failure interruption policies.
- Added use-based skills, occupations as starting knowledge, and physical books/manuals/recorded training media to the design.
- Added detailed-enough injury goals including deep wounds, sutures, fractures, splints, crutches, fatal trauma and time-sensitive extremity amputation.
- Defined the long-term large island world, destroyed/bombed bridge boundaries, outbreak epicenter/spread settings, family/occupation starts, autonomous survivors/animals, emergent settlements, patrols, logistics and infrastructure reclamation.
- Ported First Fire's dependency-free tactical lighting rules into `TacticalLighting.gd` without importing First Fire inventory/UI/camp dependencies.
- Ported First Fire's tactical sound/localization helpers into `TacticalSound.gd` without faking propagation or AI ownership early.
- Added deterministic environment-rule smoke coverage to permanent CI.
- Updated README and project context to point future development at the new design, roadmap and reuse audit.

## Milestone 0.1 — Authoritative Tick Movement — 2026-08-13

- Added a central authoritative tick scheduler with explicit committed-action costs.
- Added a single player actor timing model for walk, run, turn, and door actions.
- Added fatigue/encumbrance-ready action-cost modifiers without introducing inventory or body systems early.
- Added runtime local-world state for physical collision and mutable open/closed doors.
- Replaced the static map reroll harness with a playable developer slice using WASD/arrows plus click/tap directional controls.
- Turning now costs time independently before movement when facing changes.
- Walking and running use different tick costs; blocked movement and UI mode changes do not advance world time.
- Added a visible developer HUD for world tick, movement mode, facing, last action, and last action cost.
- Added deterministic scheduler/world smoke coverage to permanent Pages CI.

## Bootstrap 0.0 — Map Foundation — 2026-08-13

- Started clean Tick Survival Lab scaffold.
- Extracted the physical tactical-location format from First Fire without camp/menu/expedition/combat dependencies.
- Seeded seven location families with two variants each.
- Added structural map validation.
- Added a disposable rerollable map preview harness.
- Added human README, durable project context, and coding/GitHub SOPs.
- Added permanent Godot 4.7.1 import/map-smoke/startup/Web-export CI and GitHub Pages deployment.
