# Slice 15 — Balance, Performance + Release Acceptance — 2026-09-29

## Outcome

Slice 15 closes the rewrite on the real player path rather than another architecture pass.

The release-acceptance route boots a fresh script cache through:

`main.tscn -> StartupMenu -> NEW GAME -> gameplay.tscn -> ProductionGameMain`

and exercises a representative survival loop at a phone-sized 390x844 host viewport before returning through real SAVE & MENU and real StartupMenu Continue.

## Balance acceptance

The deterministic production start used by release verification produced:

- 24 active local infected and 44 known persistent infected;
- 13 searchable containers within the near expedition range;
- 23 real contained items;
- 5 food/drink consumables;
- 2 medical items;
- 1 construction-material item;
- 18 consumables within the wider expedition range.

Canonical generated loot search/take, exact-item consumption, melee combat, generated door interaction and crafting all completed through production owners.

Existing survival rates were retained rather than tuned speculatively. All six condition channels begin at 60/100. After the representative loop plus an eight-hour elapsed action, the observed condition state remained viable: satiety 43, hydration 69 after drinking, rest 46, engagement 55, comfort 60 and calm 57. Long elapsed time remained one bounded actor-response opportunity rather than repeated zombie catch-up simulation.

## Performance acceptance

The measured durable snapshot was highly redundant:

- initial canonical snapshot: 11,314,060 raw bytes -> 364,238 DEFLATE bytes;
- post-expedition/far-region snapshot: 43,880,424 raw bytes -> 1,340,871 DEFLATE bytes.

DurableSessionStore now compresses the existing payload at the file-envelope boundary with DEFLATE when it is smaller. Session schema and canonical persistence truth are unchanged. The current store continues to load old uncompressed envelope files.

The real post-expedition primary save measured approximately 1.34 MB on disk instead of writing the approximately 43.9 MB raw Variant payload.

Streaming remained bounded: the release start had one active region, local actor work stayed bounded by the active infected roster, far infected stayed dormant through an eight-hour jump and idle render frames advanced neither world time nor actor simulation.

## Phone/Safari acceptance

The production project retains its 640x844 logical canvas with canvas-item stretching. Player movement controls are touch-first and the camera controls explicitly suppress synthetic mouse events after touch. Release verification boots the real app while the host viewport is set to 390x844, exercises the gameplay loop and survives SAVE & MENU / Continue.

No visual redesign or speculative renderer rewrite was introduced.

## Release lifecycle verified

The focused verifier proves:

- fresh script-class resolution;
- real StartupMenu NEW GAME;
- ProductionGameMain session boot;
- movement;
- generated scavenging;
- exact item transfer/consumption;
- melee combat;
- generated contextual door interaction;
- crafting;
- bounded local infected responses;
- dormant far infected;
- eight-hour world-time progression;
- critical system-owner availability;
- real SAVE & MENU;
- compressed durable primary file;
- compatibility with pre-Slice-15 uncompressed envelopes;
- real StartupMenu Continue;
- restored location/facing, Health, time, seed and dormant infected state;
- idle-frame stability;
- absence of deleted Slice-14 controller architecture.

Fresh prompt-local verification:

- `game/scripts/ci/verify_slice15.gd`
- `.github/workflows/slice15.yml`

The rewrite is complete after exact-head verifier and Pages closure.
