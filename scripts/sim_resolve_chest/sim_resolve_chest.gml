function sim_resolve_chest(sim) {
    sim_log_tag(sim, "CHEST_OPEN", "🧰 Chest found.");

    // Trap chance
    if (sim_chance(sim, 15)) {
        sim_log_tag(sim, "CHEST_TRAP", "🧰 Chest: it's a trap! Poison needles.");
        // Use existing splash function (logs itself per member)
        sim_apply_party_damage(sim, sim_rand_range(sim, 4, 8));
        return;
    }

    // Gold chest (most common)
    if (sim_chance(sim, 60)) {
        var gold = sim_rand_range(sim, 10, 28) + floor(sim.difficulty / 2);
        sim.gold_total += gold;

        sim.stats.chests_opened += 1;
        sim_log_tag(sim, "CHEST_GOLD", "🧰 Chest: +" + string(gold) + " gold.");
        return;
    }

    // Item chest
    var item = choose("Mana Vial", "Blessed Wraps", "Swift Boots", "Steel Helm", "Mirror Dagger", "Saint's Charm", "Ember Ring");
    sim.stats.chests_opened += 1;

    var rare = (item == "Saint's Charm" || item == "Ember Ring" || item == "Mirror Dagger");
    if (rare) {
        sim.stats.rares_found += 1;
        sim_log_tag(sim, "CHEST_RARE", "🧰 Chest: RARE find! " + item + ".");
    } else {
        sim_log_tag(sim, "CHEST_ITEM", "🧰 Chest: found " + item + ".");
    }

    // Equip/application handled here (and will emit [EQUIP] + stat deltas)
    sim_give_item(sim, item);
}
