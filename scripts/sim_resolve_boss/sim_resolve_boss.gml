function sim_resolve_boss(sim) {
    var boss = (sim.zone == "Castle") ? "Iron Warden" : "Hollow Ogre";
    sim_log_tag(sim, "BOSS_SPAWN", "👑 BOSS: " + boss + " emerges!");

    var tank   = sim.party[0];
    var mage   = sim.party[1];
    var thief  = sim.party[2];

    // Ensure derived stats/equip exist (prevents equip/schema crashes mid-boss)
    sim_recalc_derived(tank);
    sim_recalc_derived(mage);
    sim_recalc_derived(thief);

    // --- BOSS: smash tank ---
    var boss_hit = (sim.difficulty * 6 + sim_rand_range(sim, 10, 22));
    var dmg_tank = max(0, boss_hit - tank.def);

    var before_hp = tank.hp;
    tank.hp -= dmg_tank;

    // Mark downed cue if they crossed 0 this beat (but don't force death here)
    if (before_hp > 0 && tank.hp <= 0) tank.downed_this_beat = true;

    sim_log_tag(sim, "BOSS_SMASH",
        "⚔ " + boss + " smashes: " + tank.name + " takes " + string(dmg_tank) +
        " (" + string(before_hp) + "→" + string(tank.hp) + ")."
    );

    // --- BOSS: splash ---
    sim_apply_party_damage(sim, sim_rand_range(sim, 2, 6));

    // Refresh references (splash may have changed HP)
    tank = sim.party[0];
    mage = sim.party[1];
    thief = sim.party[2];

    // Tank "up" is defined as: not dead/retired AND hp > 0
    var tank_up = (!tank.dead) && (!tank.retired) && (tank.hp > 0);

    // --- PARTY COUNTERS (log-only) ---
    if (tank_up) {
        sim_log_tag(sim, "BRACE", "🛡 " + tank.name + " braces and holds the line.");
    } else {
        sim_log_tag(sim, "BRACE_FAIL", "🪦 " + tank.name + " is down and can't brace.");
    }

    // Thief hit (always happens as a counter action)
    var thief_hit = max(1, thief.atk + sim_rand_range(sim, 2, 10));
    var thief_crit = sim_chance(sim, 20);
    if (thief_crit) thief_hit *= 2;

    sim_log_tag(sim, thief_crit ? "THIEF_CRIT" : "THIEF_EXEC",
        "🗡 " + thief.name + " smells blood: " + string(thief_hit) + " damage" + (thief_crit ? " (CRIT!)." : ".")
    );

    // Mage boss output: expensive big cast if possible, otherwise weaker fallback
    var mp_cost = clamp(6 + floor(sim.difficulty / 2), 6, 10);
    var cast = (mage.mp >= mp_cost);
    var before_mp = mage.mp;

    var mage_hit;
    var mage_crit = sim_chance(sim, cast ? 18 : 8);

    if (cast) {
        mage.mp -= mp_cost;
        mage_hit = max(1, mage.atk * 3 + sim.difficulty * 2 + sim_rand_range(sim, 10, 26));
    } else {
        mage_hit = max(1, mage.atk + sim_rand_range(sim, 3, 12));
    }

    if (mage_crit) mage_hit *= 2;

    sim_log_tag(sim, mage_crit ? "MAGE_CRIT" : "MAGE_HIT",
        "✨ " + mage.name + (cast ? " detonates a full cast" : " sputters a weak zap") +
        ": " + string(mage_hit) + " damage" + (mage_crit ? " (CRIT!)." : ".") +
        (cast ? (" [MP " + string(before_mp) + "→" + string(mage.mp) + "]") : " [NO MP]")
    );

    // Healer reaction
    sim_auto_heal(sim);

    // Knockdowns / near-death / true-death checks
    sim_check_party_health(sim);

    // Determine outcome: win if boss encounter doesn't collapse the whole party
    var avg_hp_pct = sim_party_avg_hp_pct(sim);

    // Re-fetch after checks
    tank = sim.party[0];

    // Party is considered "still fighting" if at least one non-dead, non-retired member exists
    var any_standing = false;
    for (var i = 0; i < array_length(sim.party); i++) {
        var p = sim.party[i];
        if (!p.dead && !p.retired && p.hp > 0) { any_standing = true; break; }
    }

    if (any_standing && avg_hp_pct > 0.20) {
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

        // Trophy
        var trophy = loot_generate_item(sim, { source: "boss", zone: sim.zone, tier_target: 7 });
        sim_log_tag(sim, "TROPHY_DROP", "🎁 Trophy drop: " + trophy.name + ".");
        sim_give_item(sim, trophy);

        sim.tension = clamp(sim.tension + 30, 0, 100);

        // End episode on boss victory
        sim.finished = true;
        sim_run_finalize(sim);
        return;

    } else {
        // No hard "lose screen"; you wanted continuity.
        // Treat this as a retreat event, then end the episode cleanly.
        sim_log_tag(sim, "RETREAT", "💀 Boss overwhelms the party. Retreat!");

        sim.tension = 100;
        sim.finished = true;
        sim_run_finalize(sim);
        return;
    }
}
