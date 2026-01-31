function loot_compute_power(item_type, tier, rarity, stats, use) {
    // Power points: the real "how good is this" metric.
    // Type-aware so the system doesn't overvalue weird off-stats.
    var p = 0;

    // Core stat weights (tuned to your current combat feel: ATK/DEF are king, HP/MP are meaningful but softer)
    var w_atk = 10.0;
    var w_def = 9.0;
    var w_hp  = 0.85;
    var w_mp  = 1.00;

    // Use weights (consumables)
    var w_heal = 0.65;
    var w_mpuse = 0.85;
    var w_wound = 60.0;

    // Type shaping: keeps trinkets/consumables from crowding out weapons/armor at equal tier.
    var type_mult = 1.0;
    switch (item_type) {
        case "weapon":     type_mult = 1.10; break;
        case "armor":      type_mult = 1.05; break;
        case "trinket":    type_mult = 0.90; break;
        case "consumable": type_mult = 0.85; break;
        case "treasure":   type_mult = 0.00; break; // treasure handled elsewhere
    }

    // Stat contribution
    p += stats.atk * w_atk;
    p += stats.def * w_def;
    p += stats.hp  * w_hp;
    p += stats.mp  * w_mp;

    // Consumable contribution
    p += use.heal * w_heal;
    p += use.mp * w_mpuse;
    p += use.wound_heal * w_wound;

    // Tier adds a small baseline power expectation so tier always matters a little
    p += tier * 2.5;

    // Rarity lightly boosts power expectations (value boosts more than power does)
    var rarity_mult = 1.0;
    switch (rarity) {
        case "uncommon":  rarity_mult = 1.05; break;
        case "rare":      rarity_mult = 1.12; break;
        case "epic":      rarity_mult = 1.22; break;
        case "legendary": rarity_mult = 1.35; break;
        default:          rarity_mult = 1.00; break;
    }

    return floor(p * type_mult * rarity_mult);
}
