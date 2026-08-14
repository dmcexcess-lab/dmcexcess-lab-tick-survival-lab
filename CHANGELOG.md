# Changelog

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
