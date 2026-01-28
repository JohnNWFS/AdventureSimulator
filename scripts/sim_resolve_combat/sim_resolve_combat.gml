function sim_resolve_combat(sim) {
    var threat = sim.difficulty + sim_rand_range(sim, 0, 3);

    var foe = choose("Skeletons", "Slimes", "Bandits", "Cultists", "Wolfpack");
    if (sim.zone == "Castle") foe = choose("Knights", "Gargoyles", "Sentinel Orbs");

    var tank = sim.party[0];

    // Tank takes primary damage
    var dmg_to_tank = max(0, (threat * 4 + sim_rand_range(sim, 2, 8)) - tank.def);
    var before_tank = tank.hp;
    tank.hp -= dmg_to_tank;
    if (tank.hp <= 0) tank.downed_this_beat = true;

    // Optional clip to someone else
    if (sim_chance(sim, 35)) {
        var idx = sim_rand_range(sim, 1, 3);
        var p = sim.party[idx];
        var dmg = max(0, (threat * 2 + sim_rand_range(sim, 1, 6)) - p.def);
        var before = p.hp;
        p.hp -= dmg;
        if (p.hp <= 0) p.downed_this_beat = true;

        sim_log_tag(sim, "COMBAT_HIT",
            "⚔ " + foe + " clash: " + p.name + " takes " + string(dmg) +
            " (" + string(before) + "→" + string(p.hp) + ")."
        );
    }

    // Mage hits back (storyboard number for animation)
    var mage = sim.party[1];
    var crit = sim_chance(sim, 15);
    var hit = threat * 6 + sim_rand_range(sim, 4, 14);
    if (crit) hit *= 2;

    sim_log_tag(sim, "COMBAT_EXCHANGE",
        "⚔ " + foe + " clash: " + tank.name + " takes " + string(dmg_to_tank) +
        " (" + string(before_tank) + "→" + string(tank.hp) + "). " +
        "✨ " + mage.name + " hits for " + string(hit) + (crit ? " (CRIT!)." : ".")
    );

    // Healer reacts (real healing + tagged logging inside sim_auto_heal)
    sim_auto_heal(sim);

    // IMPORTANT: resolve collapses/wounds/near-death BEFORE loot narration
    sim_check_party_health(sim);

    // Loot AFTER health resolution
    var gold = sim_rand_range(sim, 3, 10) + sim.difficulty;
    sim.gold_total += gold;

    sim_log_tag(sim, "LOOT", "💰 Loot: +" + string(gold) + " gold.");

    sim.tension = clamp(sim.tension + 12 + threat * 2, 0, 100);
}
