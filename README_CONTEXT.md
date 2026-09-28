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

Slices 1-7 now establish canonical simple-turn movement, combat, scavenging, inventory, survival, contextual interaction, crafting, first aid, repair and deconstruction. Actions mutate existing authoritative state, bounded local infected respond at most once, explicit elapsed survival time advances through the shared completion seam, and control returns promptly.

Existing recipes, exact ingredient/tool identities, skills, workstations, Health/injury records, repair profiles, broken state and deconstruction salvage remain the content truth. Cooking uses the same migrated recipe route but still respects existing powered-workstation availability; utilities are not faked or prematurely migrated.

The old execution architecture remains only as migration debt for bootstrap, durable-session compatibility and still-unmigrated routes. The production MENU/save regression remains repaired. The next rewrite slice is existing-house fortification/base use.

The previous verbose contents remain available in Git history and must not be copied back into active context.
