function loot_roll_stats(sim, item_type, tier, rarity) {
    // FIX: enforce "minimum viable stats" so armor/weapons/trinkets don't roll blank.
    var atk = 0, def = 0, hp = 0, mp = 0;
    var heal = 0, mp_use = 0, wound_heal = 0;

    var rarity_mult = 1;
    switch (rarity) {
        case "uncommon": rarity_mult = 1.2; break;
        case "rare": rarity_mult = 1.5; break;
        case "epic": rarity_mult = 2.0; break;
        case "legendary": rarity_mult = 3.0; break;
        default: rarity_mult = 1.0; break;
    }

    switch (item_type) {

        case "weapon":
            atk = floor((tier * 1.2 + sim_rand_range(sim, 0, 2)) * rarity_mult);
            // Minimum: weapons always add at least 1 ATK
            if (atk < 1) atk = 1;
            break;

        case "armor":
            def = floor((tier * 0.8 + sim_rand_range(sim, 0, 2)) * rarity_mult);
            // Minimum: armor always adds at least 1 DEF
            if (def < 1) def = 1;
            break;

        case "trinket":
            // Mixed bonuses, but ensure at least one non-zero stat.
            atk = floor((tier * 0.4) * rarity_mult);
            def = floor((tier * 0.4) * rarity_mult);

            if (sim_chance(sim, 40)) hp = floor((tier * 2) * rarity_mult);
            if (sim_chance(sim, 40)) mp = floor((tier * 2) * rarity_mult);

            // Minimum: if everything is zero, force a small bonus (favor MP/HP for cinematic variety)
            if (atk <= 0 && def <= 0 && hp <= 0 && mp <= 0) {
                if (sim_chance(sim, 50)) mp = 2 + floor(tier * 0.5);
                else hp = 4 + floor(tier * 1.0);
            }
            break;

        case "consumable":
            heal = floor((tier * 4 + sim_rand_range(sim, 6, 12)) * rarity_mult);
            mp_use = floor((tier * 2 + sim_rand_range(sim, 2, 6)) * rarity_mult);

            // Minimum: consumable should always do something
            if (heal < 5) heal = 5;
            if (mp_use < 0) mp_use = 0;

            if (rarity == "epic" || rarity == "legendary") wound_heal = 1;
            break;

        case "treasure":
            // No stats
            break;
    }

    return {
        stats: { atk: atk, def: def, hp: hp, mp: mp },
        use: { heal: heal, mp: mp_use, wound_heal: wound_heal }
    };
}
