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

As of 2026-09-27 the project direction deliberately changed from the experimental tick/WHERE/WHAT/WHEN execution model to a conventional turn-based survival game while preserving the existing procedural persistent world and gameplay content.

Slices 1-6 now establish the canonical simple-turn spine for movement, combat, scavenging, inventory, survival and contextual interaction: actions mutate existing authoritative state directly, bounded local infected respond at most once, elapsed survival time advances once through the shared completion seam, and control returns promptly. Exact item/equipment identity, Health/injury/corpse state, condition/moodlet state, doors/windows and existing action-from-thing affordances remain authoritative.

Contextual EAT/DRINK, REST/SLEEP and door/window OPEN/CLOSE are now migrated without TickKernel/WHEN/timed-action execution. Loot/pickup remain on the migrated Slice 4 route, while crafting workstations preserve their contextual entry point for Slice 7 rather than faking migrated crafting.

The old execution architecture remains only as migration debt for bootstrap, durable-session compatibility and still-unmigrated gameplay routes. It is no longer protected project identity. The production MENU/save regression remains repaired. The next rewrite slice reconnects crafting, cooking, healing, repair and deconstruction.

The previous verbose contents remain available in Git history and must not be copied back into active context.
