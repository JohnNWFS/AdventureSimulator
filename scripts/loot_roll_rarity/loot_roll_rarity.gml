function loot_roll_rarity(sim, context) {
    // Basic rarity roll. Later: bias by source/zone/tier.
    var r = loot_roll_pct(sim);

    if (r >= 99) return "legendary";
    if (r >= 95) return "epic";
    if (r >= 85) return "rare";
    if (r >= 65) return "uncommon";
    return "common";
}
