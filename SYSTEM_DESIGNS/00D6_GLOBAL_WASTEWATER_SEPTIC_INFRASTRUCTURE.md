# Tick Survival Lab — System 00D6 Wastewater / Septic Infrastructure

Status: **RETIRED — NOT AN ACTIVE GAME SYSTEM OR PLANNING REQUIREMENT**

Retired contract confirmed: **2026-08-30**

## Current authority

Tick Survival Lab has **no active wastewater/sewer/septic system**.

The former Slice 006 design is historical only. Current world generation does not invoke wastewater planning or validation, generated-world validity does not require wastewater arrays, System 20 does not require or inject wastewater constraints, and the active global-world-planning workflow does not require wastewater sources or this document.

Do not restore wastewater behavior to satisfy old tests, old profile versions, old projection assumptions or historical documentation.

## Historical note

An earlier implementation experimented with municipal wastewater intent for the small town and decentralized septic intent for rural settlements. That direction was later removed from the game. Git history preserves the old implementation and design if archaeology is ever explicitly requested.

Some legacy source files/data fields may remain in the repository for historical compatibility while inert. Their existence is **not** proof of active ownership and they must not be called from live generation/runtime paths.

## Current potable-water relationship

Potable water is governed by `00D5_GLOBAL_POTABLE_WATER_INFRASTRUCTURE.md` and `33_POWER_WATER_UTILITIES.md`:

- one island-wide municipal treatment facility;
- no municipal service radius or long-distance pipe simulation;
- deterministic real private wells for a minority of generated rural homes;
- no wastewater counterpart.

## Reintroduction rule

Wastewater may return only through a new explicit DESCRIBE -> APPROVE -> IMPLEMENT lifecycle. It must not be inferred from this historical file or silently resurrected as a dependency of water, settlement generation or utility verification.
