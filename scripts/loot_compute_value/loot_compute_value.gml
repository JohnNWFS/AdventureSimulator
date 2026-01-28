function loot_compute_value(sim, item_type, tier, rarity, stats, use) {
    var base = tier * 25;

    var rarity_bonus = 0;
    switch (rarity) {
        case "uncommon":  rarity_bonus = 50; break;
        case "rare":      rarity_bonus = 140; break;
        case "epic":      rarity_bonus = 350; break;
        case "legendary": rarity_bonus = 900; break;
        default:          rarity_bonus = 0; break;
    }

    var stat_value = 0;
    stat_value += stats.atk * 60;
    stat_value += stats.def * 55;
    stat_value += stats.hp * 3;
    stat_value += stats.mp * 4;

    var use_value = 0;
    use_value += use.heal * 3;
    use_value += use.mp * 4;
    use_value += use.wound_heal * 300;

    // Treasure should feel like "gold payload" and be a compelling event.
    // Make it scale with tier and rarity, with a solid random chunk.
    if (item_type == "treasure") {
        var chunk = sim_rand_range(sim, 40, 120) + (tier * 20);
        var rarity_mul = 1;
        switch (rarity) {
            case "uncommon":  rarity_mul = 1.2; break;
            case "rare":      rarity_mul = 1.6; break;
            case "epic":      rarity_mul = 2.2; break;
            case "legendary": rarity_mul = 3.0; break;
            default:          rarity_mul = 1.0; break;
        }
        return floor((chunk + rarity_bonus) * rarity_mul);
    }

    return base + rarity_bonus + stat_value + use_value;
}
