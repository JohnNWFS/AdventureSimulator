function loot_generate_item(sim, context) {
    // context: {source, zone, tier_target}
    var zone = context.zone;
    var tier_target = context.tier_target;

    // Named jackpot?
    if (loot_roll_named(sim, context)) {
        var named = loot_named_table_init();
        var pick = named[sim_rand_range(sim, 0, array_length(named) - 1)];
        return pick; // already is_named = true
    }

    // Procedural item
    var item_type = loot_pick_item_type(sim, context);
    var rarity = loot_roll_rarity(sim, context);

    // Tier near target
    var tier = clamp(tier_target + sim_rand_range(sim, -1, 1), 1, 10);

    // Name parts
    var base = "Trinket";
    switch (item_type) {
        case "weapon": base = choose("Sword", "Axe", "Dagger", "Wand"); break;
        case "armor": base = choose("Helm", "Shield", "Cuirass", "Wraps"); break;
        case "trinket": base = choose("Ring", "Charm", "Band", "Sigil"); break;
        case "consumable": base = choose("Tonic", "Vial", "Draught"); break;
        case "treasure": base = choose("Gem", "Idol", "Relic", "Coin Cache"); break;
    }

    var aff = loot_pick_affixes(sim, item_type, rarity, zone);
    var name = loot_build_name(aff.prefix, aff.material, base, aff.suffix);

    // Stats + use
    var rolled = loot_roll_stats(sim, item_type, tier, rarity);
    var stats = rolled.stats;
    var use = rolled.use;

    // Value
	var value = loot_compute_value(sim, item_type, tier, rarity, stats, use);


    // ID (simple, deterministic-ish)
    var id1 = "gen_" + string(item_type) + "_" + string(tier) + "_" + string(sim_rand_range(sim, 1000, 9999));

    // Tags
    var tags = aff.tags;
    // Add one tag for rarity (helps cinematics)
    tags[array_length(tags)] = rarity;

    return loot_item_make(
        id1, name, item_type, tier, rarity, value,
        stats, use, tags,
        aff.fx, aff.anim, false
    );
}
