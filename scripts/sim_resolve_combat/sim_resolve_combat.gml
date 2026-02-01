function sim_resolve_combat(sim) {

    // ---- Harden stats ----
    if (!is_struct(sim.stats)) {
        sim.stats = {
            combats: 0,
            near_deaths: 0,
            knockdowns: 0,
            chests_opened: 0,
            merchants_seen: 0,
            rares_found: 0,
            boss_defeated: false,
            deaths: 0,
            retirements: 0,
            legacies: 0
        };
    }
    if (!variable_struct_exists(sim.stats, "combats")) sim.stats.combats = 0;

    sim.stats.combats += 1;

    var foe = choose("Skeleton", "Bandit", "Goblin", "Slime", "Warg", "Cult Acolyte");
    var threat = sim_rand_range(sim, 1, 6) + floor(sim.difficulty / 2);

    // Optional micro-modifier for variety (combat-only)
    var _mod = sim_roll_encounter_mod(sim);
    if (is_struct(_mod)) threat += _mod.threat_add;

    sim_log_tag(sim, "ENCOUNTER",
        "⚔ Combat: " + foe + " (threat " + string(threat) + ")."
    );
    if (is_struct(_mod)) sim_log_tag(sim, _mod.tag, _mod.desc);

    // Party roles (canonical order)
    var tank   = sim.party[0];
    var mage   = sim.party[1];
    var thief  = sim.party[2];
    var healer = sim.party[3];

    // Ensure equip/derived schema exists before anything reads p.equip
    sim_recalc_derived(tank);
    sim_recalc_derived(mage);
    sim_recalc_derived(thief);
    sim_recalc_derived(healer);

    // --- AMBUSH pre-strike ---
    if (is_struct(_mod) && _mod.pre_strike) {
        var j = sim_rand_range(sim, 1, array_length(sim.party) - 1);
        var v = sim.party[j];

        sim_recalc_derived(v);

        var pre_raw = sim_rand_range(sim, 3, 9) + floor(threat / 2) - v.def;
        var pre_dmg = max(1, pre_raw);

        var vb = v.hp;
        v.hp -= pre_dmg;

        sim_adjust_resolve(sim, v, -12, "RESOLVE_AMBUSH");

        sim_log_tag(sim, "AMBUSH_HIT",
            "🕳 AMBUSH → " + v.name + " takes " + string(pre_dmg) +
            " (" + string(vb) + "→" + string(v.hp) + ")."
        );
    }

    // --- Enemy hits tank ---
    var dmg_mult = (is_struct(_mod)) ? _mod.dmg_mult : 1.0;
    var def_mult = (is_struct(_mod)) ? _mod.def_mult : 1.0;

    var base_dmg = ((threat * 6) + sim_rand_range(sim, 3, 10));
    base_dmg = floor(base_dmg * dmg_mult);

    var eff_def = floor(tank.def * def_mult);
    var dmg_to_tank = max(0, base_dmg - eff_def);

    var before_tank = tank.hp;
    tank.hp -= dmg_to_tank;

    sim_log_tag(sim, "COMBAT_EXCHANGE",
        "⚔ " + foe + " strikes: " + tank.name + " takes " + string(dmg_to_tank) +
        " (" + string(before_tank) + "→" + string(tank.hp) + ")."
    );

    // Catastrophic check right away (rare, but dramatic)
    if (tank.hp <= -tank.max_hp) {
        tank.dead = true;
        tank.status_state = "dead";
        sim.stats.deaths += 1;
        sim_log_tag(sim, "DEATH", "☠ " + tank.name + " is shattered in one awful moment.");
    }

    // --- Mid-fight chaos (allow execution blows) ---
    if (is_struct(_mod) && _mod.extra_splash > 0) {
        sim_log_tag(sim, "CHAOS", "💢 Chaos erupts in the scrum.");
        sim_apply_party_damage(sim, _mod.extra_splash);
    }

    // --- Thief identity: Execution mode ---
    var avg_hp_pct = sim_party_avg_hp_pct(sim);
    var exec_mode = (tank.hp <= 0) || (avg_hp_pct < 0.45) || (sim.tension > 75);

    var thief_base = max(1, thief.atk * 2 + sim_rand_range(sim, 2, 8));
    var thief_bonus = exec_mode ? sim_rand_range(sim, 2, 8) : 0;
    var thief_hit = thief_base + thief_bonus;

    var thief_crit = sim_chance(sim, exec_mode ? 28 : 16);
    if (thief_crit) thief_hit *= 2;

    var thief_tag;
    if (exec_mode) thief_tag = thief_crit ? "THIEF_EXEC_CRIT" : "THIEF_EXEC";
    else           thief_tag = thief_crit ? "THIEF_CRIT"      : "THIEF_HIT";

    sim_log_tag(sim, thief_tag,
        "🗡 " + thief.name +
        (exec_mode ? " smells blood" : " slips in") +
        ": " + string(thief_hit) + " damage" + (thief_crit ? " (CRIT!)." : ".")
    );

    // --- Mage hits back (MP matters) ---
    var mp_add = (is_struct(_mod)) ? _mod.mp_cost_add : 0;
    var mp_cost = clamp(2 + floor(threat / 3) + mp_add, 2, 8);

    var cast = (mage.mp >= mp_cost);
    var before_mp = mage.mp;

    var mage_crit = sim_chance(sim, cast ? 18 : 10);
    var mage_hit;

    if (cast) {
        mage.mp -= mp_cost;
        mage_hit = (threat * 7) + sim_rand_range(sim, 6, 18) + floor(mage.atk * 0.5);
    } else {
        mage_hit = (threat * 3) + sim_rand_range(sim, 2, 10);
    }

    if (mage_crit) mage_hit *= 2;

    sim_log_tag(sim, mage_crit ? "MAGE_CRIT" : "MAGE_HIT",
        "✨ " + mage.name + (cast ? " casts" : " jabs") +
        " for " + string(mage_hit) + (mage_crit ? " (CRIT!)." : ".") +
        (cast ? (" [MP " + string(before_mp) + "→" + string(mage.mp) + "]") : " [NO MP]")
    );

    // --- Healer reacts ---
    sim_auto_heal(sim);

    // --- Knockdowns / near-death / death consistency ---
    sim_check_party_health(sim);

    // If anyone died, do an emergency town vignette + replacements
    if (sim_party_any_dead(sim)) {
        sim_log_tag(sim, "RETREAT", "🏘 The party staggers back to town to regroup.");
        sim_log_tag(sim, "TOWN_RETURN", "🏘 Town lights blur through rain and exhaustion.");
        sim_party_process_exits(sim, "combat");
    }

    // --- Tension climbs ---
    sim.tension = clamp(sim.tension + sim_rand_range(sim, 6, 14), 0, 100);
}
