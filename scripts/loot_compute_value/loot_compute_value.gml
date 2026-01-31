function loot_compute_value(sim, item_type, tier, rarity, stats, use) {

    // Treasure stays a "gold payload" event
    if (item_type == "treasure") {
        var chunk = sim_rand_range(sim, 40, 120) + (tier * 20);

        var rarity_mul = 1.0;
        switch (rarity) {
            case "uncommon":  rarity_mul = 1.2; break;
            case "rare":      rarity_mul = 1.6; break;
            case "epic":      rarity_mul = 2.2; break;
            case "legendary": rarity_mul = 3.0; break;
            default:          rarity_mul = 1.0; break;
        }

        return floor(chunk * rarity_mul + loot_rarity_value_flat(rarity));
    }

    // Power is the main driver (rename var to avoid clobbering power() function)
    var pwr = loot_compute_power(item_type, tier, rarity, stats, use);

    // Tier curve: slightly super-linear so higher tiers feel pricier
    // (t=1 -> ~53, t=10 -> ~309 before multipliers)
    var tier_curve = floor(35 + power(tier, 1.18) * 18);

    // Power curve: value rises strongly with power but not absurdly
    var power_curve = floor(pwr * 14);

    // Rarity affects price more than it affects power
    var v = (tier_curve + power_curve);
    v = floor(v * loot_rarity_value_mult(rarity) + loot_rarity_value_flat(rarity));

    // Tiny market noise
    v += sim_rand_range(sim, -8, 8);

    if (v < 1) v = 1;
    return v;
}
