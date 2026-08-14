# First Fire Reuse Audit

Tick Survival Lab is a clean project, but First Fire is an original project by the same owner and contains tactical/world work worth adapting. The goal is **reuse without architectural contamination**.

Audit source: current `dmcexcess-lab/first-fire` `main` inspected during Tick development.

## Reused now

### `FFTacticalEnvironments.gd` → `TacticalMapGenerator.gd`

Extracted physical place families, authored variants, ground/indoor regions, walls, doors, windows/glass, obstacles/props, barrels, light markers, player spawn/exits, and structural validation. First Fire zone/encounter/objective/camp assumptions were removed.

### `FFTacticalLighting.gd` → `TacticalLighting.gd`

Ported as a dependency-free lighting helper: theme/day-night ambient levels/tints, source presets, powered source checks, radial falloff, window daylight, directional/radial carried light, darkness/visibility helpers, and visual flicker. No `FFData`, inventory, encounter UI, or camp dependency.

### `FFTacticalSound.gd` → `TacticalSound.gd`

Ported surface footstep labels, localization accuracy, uncertain source estimates, display labels, and ambient profiles. Real Tick-owned emission/propagation/occlusion remains Milestone 0.3B.

### `FFTacticalTiles.gd` + `tactical_atlas` → `TacticalTiles.gd` + Tick atlas subset

The deferred visual work is now restored. Tick carries a same-owner tactical atlas subset containing the physical tiles needed by the current maps plus a four-direction survivor sprite. `TacticalTiles.gd` renders ground, theme walls, open/closed doors, windows, barrels, props, and the player sprite.

The asset is intentionally a subset rather than importing unrelated First Fire UI art or unused game assets.

### `FFCombat.gd` perception concepts → `TacticalPerception.gd`

Ported the coherent physical-perception rules instead of copying the encounter runtime:

- Bresenham-style LOS;
- walls, opaque/tall obstacles, and closed doors block sight;
- windows transmit sight/light;
- four-direction facing cone;
- lighting-gated distance recognition;
- visible cell set;
- remembered cell state for fog of war;
- light recalculation after physical/facing state changes.

Not imported from `FFCombat.gd`: encounter objectives, `Game` singleton coupling, camp/survivor roster logic, companion encounter control, combat UI, escape flow, or First Fire runtime persistence.

## Reuse as concepts, not copy-paste runtime

### `FFTacticalTime.gd`

Useful concepts remain equipment load, fatigue, injury, skill effects on action time, varying infected pace, and breathing noise. Tick owns timing in `PlayerActor.gd`/`TickScheduler.gd`, so these should be adapted into Tick-native actor/body systems rather than transplanted.

### First Fire survivor/social systems

Keep the ambitions—autonomous survivors, personality/relationships, morale/stress, useful work while the player is elsewhere—but not the camp/menu layer. Tick's version must happen through physical autonomous world actors whose jobs are goals rather than puppet controls.

## Explicitly do not import

- camp UI and camp orchestration;
- expedition menu/rules;
- encounter wrapper/scenario completion flow;
- First Fire `Game.gd` state facade;
- First Fire save schema/migrations;
- release/ads/platform glue;
- survivor panel/inspector UI as runtime architecture;
- legacy field-event abstraction;
- companion code that assumes a separate tactical encounter.

## Reuse rule going forward

Before implementing a major tactical/world subsystem from scratch, inspect current First Fire source for same-owner reusable work. Port only the smallest coherent rule set, remove First Fire-specific dependencies, give it a Tick-native owner, and add deterministic smoke coverage where practical.
