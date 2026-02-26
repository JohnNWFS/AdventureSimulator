# AdventureSimulator

A GameMaker-based procedural adventure simulation focused on:
- Cinematic, replayable dungeon runs
- Deterministic, logged events for future animation playback
- Procedural loot with rare named artifacts
- Lightweight combat and party simulation

## Project Status
Early prototype. Core simulation, combat, logging, and event tagging are in place.

## Key Concepts
- One-room simulation controller
- Text-first logging with tagged events (for future rendering)
- Procedural loot with jackpot named items
- Git-backed development for safety and iteration

## How to Run
Open `AdventureSimulator.yyp` in GameMaker Studio and run room `rm_sim`.

## Repo Notes
- `.gitignore` excludes build/cache artifacts
- `.gitattributes` normalizes line endings
