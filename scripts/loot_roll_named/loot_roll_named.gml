function loot_roll_named(sim, context) {
    // Jackpot rule: d100 == 100
    // Later we can bias odds by source (boss higher), but start simple.
    return loot_roll_pct(sim) == 100;
}
