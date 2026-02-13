function sim_resolve_chest(sim) {
    sim_log_tag(sim, "CHEST_OPEN", "🧰 Chest found.");
    sim.stats.chests_opened += 1;

    // Trap chance
    if (sim_chance(sim, 15)) {
        sim_log_tag(sim, "CHEST_TRAP", "🧰 Chest: it's a trap! Poison needles.");
        sim_apply_party_damage(sim, sim_rand_range(sim, 4, 8));
        return;
    }

    // Gold chest (most common)
    if (sim_chance(sim, 60)) {
        var gold = sim_rand_range(sim, 10, 28) + floor(sim.difficulty / 2);
        sim.gold_total += gold;

        sim_log_tag(sim, "CHEST_GOLD", "🧰 Chest: +" + string(gold) + " gold.");
        return;
    }

    // Item chest (struct-based)
    var tier_target = clamp(1 + floor(sim.difficulty / 2), 1, 10);
    var item = loot_generate_item(sim, { source: "chest", zone: sim.zone, tier_target: tier_target });

    if (item.is_named || item.rarity == "rare" || item.rarity == "epic" || item.rarity == "legendary") {
        sim.stats.rares_found += 1;
        sim_log_tag(sim, "CHEST_RARE", "🧰 Chest: RARE find! " + item.name + ".");
    } else {
        sim_log_tag(sim, "CHEST_ITEM", "🧰 Chest: found " + item.name + ".");
    }

    sim_give_item(sim, item);
}
