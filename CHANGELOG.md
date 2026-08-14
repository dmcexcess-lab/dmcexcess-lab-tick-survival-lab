# Changelog

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
