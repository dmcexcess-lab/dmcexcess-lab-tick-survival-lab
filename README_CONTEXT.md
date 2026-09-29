# Tick Survival Lab — Compatibility Context Pointer

Status: **legacy bootstrap pointer; not project working memory**

## Load order

1. README_SOPS.md — repository execution procedure;
2. AI_OPERATING_MODEL.md — reasoning/decision contract;
3. PROJECT_NORTH_STAR.md — game identity;
4. ARCHITECTURE.md — settled ownership/invariants;
5. ROADMAP.md — current rewrite order;
6. CURRENT.md — exact active state and NEXT.

Do not reconstruct current state from this file or old commits.

## Current pointer

CURRENT.md is canonical working memory.

As of 2026-09-28 the project direction is the conventional turn-based survival rewrite while preserving the existing procedural persistent world and gameplay content.

Slices 1-14 are closed: simple-turn movement, combat, scavenging, inventory, survival, contextual interaction, crafting, first aid, repair, deconstruction, existing-opening fortification, and power/water utility interaction, corrected road hierarchy, vehicle interaction, authoritative world time, derived day/night, coarse weather progression, the bounded open-world simulation boundary, canonical durable persistence migration and legacy-execution demolition are canonical. Migrated actions mutate existing authoritative state directly, bounded local infected respond at most once, explicit elapsed survival time advances through the shared completion seam, and control returns promptly.

Existing content owners remain truth; the rewrite does not replace procedural world generation, persistence, exact items, skills, utility topology/state, generators/wells, fortification state or other mature domain data. The obsolete player-facing scheduled controller/action graph has been physically deleted. TickKernel remains only for explicitly documented compatibility seams: forage, older utility/sound/perception/UI clock APIs, and the infected cohort/opening-pressure path.

The production MENU/save/Continue and recent boot regressions remain repaired. The next rewrite slice is Slice 15: balance, performance and release acceptance. See CURRENT.md for exact checkpoint and constraints.

The previous verbose contents remain available in Git history and must not be copied back into active context.
