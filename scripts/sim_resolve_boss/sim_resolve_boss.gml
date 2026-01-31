function sim_resolve_boss(sim) {
    var boss = (sim.zone == "Castle") ? "Iron Warden" : "Hollow Ogre";
    sim_log_tag(sim, "BOSS_SPAWN", "👑 BOSS: " + boss + " emerges!");

    var tank   = sim.party[0];
    var mage   = sim.party[1];
    var thief  = sim.party[2];

    // --- BOSS: smash tank ---
    var boss_hit = (sim.difficulty * 6 + sim_rand_range(sim, 10, 22));
    var dmg_tank = max(0, boss_hit - tank.def);

    var before_hp = tank.hp;
    tank.hp -= dmg_tank;
    if (tank.hp <= 0) tank.downed_this_beat = true;

    sim_log_tag(sim, "BOSS_SMASH",
        "⚔ " + boss + " smashes: " + tank.name + " takes " + string(dmg_tank) +
        " (" + string(before_hp) + "→" + string(tank.hp) + ")."
    );

    // --- BOSS: splash ---
    sim_apply_party_damage(sim, sim_rand_range(sim, 2, 6));

    // --- PARTY COUNTERS (numbers for animation; log-only) ---
    sim_log_tag(sim, "BRACE", "🛡 " + tank.name + " braces and holds the line.");

    var thief_hit = max(1, thief.atk + sim_rand_range(sim, 2, 10));
    var thief_crit = sim_chance(sim, 20);
    if (thief_crit) thief_hit *= 2;

    sim_log_tag(sim, thief_crit ? "THIEF_CRIT" : "THIEF_HIT",
        "🗡 " + thief.name + " slips in: " + string(thief_hit) + " damage" + (thief_crit ? " (CRIT!)." : ".")
    );

    var mage_hit = max(1, mage.atk * 3 + sim_rand_range(sim, 5, 18));
    var mage_crit = sim_chance(sim, 15);
    if (mage_crit) mage_hit *= 2;

    sim_log_tag(sim, mage_crit ? "MAGE_CRIT" : "MAGE_HIT",
        "✨ " + mage.name + " unleashes a blast: " + string(mage_hit) + " damage" + (mage_crit ? " (CRIT!)." : ".")
    );

    // Healer reaction (real healing)
    sim_auto_heal(sim);

    // Knockdowns / near-death tracking
    sim_check_party_health(sim);

    // Determine outcome: if tank survives and avg HP not terrible, win
    var avg_hp_pct = sim_party_avg_hp_pct(sim);

    if (tank.hp > 0 && avg_hp_pct > 0.25) {
        sim.stats.boss_defeated = true;

        // FINISHER cue (log-only)
        var finisher_name = mage.name;
        var finisher_desc = "blast";
        var finisher_dmg  = mage_hit;
        if (thief_hit > finisher_dmg) {
            finisher_name = thief.name;
            finisher_desc = "strike";
            finisher_dmg  = thief_hit;
        }

        sim_log_tag(sim, "FINISHER",
            "💥 FINISHER → " + finisher_name + "'s " + finisher_desc +
            " breaks the " + boss + "! (" + string(finisher_dmg) + ")"
        );

        var gold = sim_rand_range(sim, 50, 90);
        sim.gold_total += gold;


        sim_log_tag(sim, "BOSS_DEFEATED", "🏆 Boss defeated! +" + string(gold) + " gold.");

        // Equip after drop (sim_give_item logs EQUIP + STAT deltas)
		var trophy = loot_generate_item(sim, { source: "boss", zone: sim.zone, tier_target: 7 });

		sim_log_tag(sim, "TROPHY_DROP",  "🎁 Trophy drop: " + trophy.name + ".");
		sim_give_item(sim, trophy);


        sim.tension = clamp(sim.tension + 30, 0, 100);

        // End episode on boss victory
        sim.finished = true;
        sim_run_finalize(sim);
        return;

    } else {
        sim_log_tag(sim, "RETREAT", "💀 Boss overwhelms the party. Retreat!");
        sim.tension = 100;
        sim.finished = true;
        sim_run_finalize(sim);
        return;
    }
}
