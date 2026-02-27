function loot_roll_rarity(sim, context) {
    // Basic rarity roll. Later: bias by source/zone/tier.
    var r = loot_roll_pct(sim);
    var source = (is_struct(context) && variable_struct_exists(context, "source")) ? context.source : "";

    if (source == "chest" || source == "treasure" || source == "treasure_cache") {
        if (r >= 99) return "legendary";
        if (r >= 93) return "epic";
        if (r >= 78) return "rare";
        if (r >= 60) return "uncommon";
        return "common";
    }

    if (r >= 99) return "legendary";
    if (r >= 95) return "epic";
    if (r >= 85) return "rare";
    if (r >= 65) return "uncommon";
    return "common";
}
