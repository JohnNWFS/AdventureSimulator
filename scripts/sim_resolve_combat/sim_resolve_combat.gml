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
            legacies: 0,
            downed_events: 0,
            tank_downed_count: 0,
            total_downed_count: 0,
            encounters_over_budget_prevented: 0,
            rerolls_count: 0,
            encounter_attempts: 0,
            encounter_accepted: 0,
            encounter_rerolled: 0,
            encounter_scaled_down: 0,
            encounter_degraded: 0,
            encounter_bestfit_selected: 0
        };
    }
    if (!variable_struct_exists(sim.stats, "combats")) sim.stats.combats = 0;
    if (!variable_struct_exists(sim.stats, "encounters_over_budget_prevented")) sim.stats.encounters_over_budget_prevented = 0;
    if (!variable_struct_exists(sim.stats, "rerolls_count")) sim.stats.rerolls_count = 0;
    if (!variable_struct_exists(sim.stats, "encounter_attempts")) sim.stats.encounter_attempts = 0;
    if (!variable_struct_exists(sim.stats, "encounter_accepted")) sim.stats.encounter_accepted = 0;
    if (!variable_struct_exists(sim.stats, "encounter_rerolled")) sim.stats.encounter_rerolled = 0;
    if (!variable_struct_exists(sim.stats, "encounter_scaled_down")) sim.stats.encounter_scaled_down = 0;
    if (!variable_struct_exists(sim.stats, "encounter_degraded")) sim.stats.encounter_degraded = 0;
    if (!variable_struct_exists(sim.stats, "encounter_bestfit_selected")) sim.stats.encounter_bestfit_selected = 0;

    sim.stats.combats += 1;

    var party_power = sim_calc_party_power(sim);
    var enc = sim_make_combat_encounter(sim, party_power);

    sim.stats.encounters_over_budget_prevented += enc.prevented;
    sim.stats.rerolls_count += enc.rerolls;
    sim.stats.encounter_attempts += enc.attempts;
    sim.stats.encounter_rerolled += enc.rerolls;

    if (enc.degraded) {
        sim.stats.encounter_degraded += 1;
        sim_log_tag(sim, "ENCOUNTER_SHIFT",
            "🧯 Threat budget rejected repeated over-cap rolls; encounter degrades into an escape hazard."
        );
        sim_log_tag(sim, "ESCAPE",
            "🏃 [TACTIC] Controlled withdrawal through unstable ground buys time but costs momentum."
        );
        sim.tension = clamp(sim.tension + 4, 0, 100);
        return;
    }

    if (enc.scaled) {
        sim.stats.encounter_scaled_down += 1;
        if (enc.weakened_only) {
            sim_log_tag(sim, "ENCOUNTER_SHIFT", "🧪 Budget scale-down applied a light non-boss weakening to keep threat fair.");
        } else if (!is_undefined(enc.removed_enemy_name) && enc.removed_enemy_name != "") {
            sim_log_tag(sim, "ENCOUNTER_SHIFT", "🪓 Budget scale-down removed " + enc.removed_enemy_name + " from the encounter.");
        }
    } else {
        sim.stats.encounter_accepted += 1;
    }

    if (enc.bestfit_selected) sim.stats.encounter_bestfit_selected += 1;

    var tag_label = enc.tag;
    if (tag_label == "HARD") tag_label = "[HARD]";

    sim_log_tag(sim, "ENCOUNTER",
        "⚔ Combat: " + enc.names + " (threat " + string(enc.total) + ") " + tag_label + "."
    );

    // Optional micro-modifier for variety (combat-only)
    var _mod = sim_roll_encounter_mod(sim);
    var threat = enc.total;
    if (is_struct(_mod)) threat += _mod.threat_add;

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

    // Crisis tactics state
    var tactics = sim.director.tank_tactic_state;
    var dmg_taken_mult = 1.0;
    var flank_base_chance = 18;
    var party_out_mult = 1.0;

    if (tactics.defensive_left > 0) {
        dmg_taken_mult *= 0.70;
        party_out_mult *= 0.80;
        tactics.defensive_left -= 1;
        sim_log_tag(sim, "TACTIC", "🛡 [TACTIC] Defensive stance active: incoming damage reduced this beat.");
    }
    if (tactics.cover_left > 0) {
        flank_base_chance = 8;
        tactics.cover_left -= 1;
        sim_log_tag(sim, "TACTIC", "🧱 [TACTIC] Choke point/cover active: enemy accuracy reduced.");
    }
    if (tactics.withdrawal_left > 0) {
        dmg_taken_mult *= 0.85;
        tactics.withdrawal_left -= 1;
        sim_log_tag(sim, "TACTIC", "🏃 [TACTIC] Controlled withdrawal active: disengagement posture lowers pressure.");
    }

    // --- AMBUSH pre-strike ---
    if (is_struct(_mod) && _mod.pre_strike) {
        var j = sim_rand_range(sim, 1, array_length(sim.party) - 1);
        var v = sim.party[j];

        sim_recalc_derived(v);

        var pre_raw = sim_rand_range(sim, 3, 9) + floor(threat / 2) - v.def;
        var pre_dmg = max(1, floor(pre_raw * dmg_taken_mult));

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
    base_dmg = floor(base_dmg * dmg_mult * dmg_taken_mult);

    var eff_def = floor(tank.def * def_mult);
    var dmg_to_tank = max(0, base_dmg - eff_def);

    var before_tank = tank.hp;
    var pre_wounds = tank.wounds;
    var pre_tank_downed = sim.stats.tank_downed_count;

    tank.hp -= dmg_to_tank;

    sim_log_tag(sim, "COMBAT_EXCHANGE",
        "⚔ " + enc.names + " strikes: " + tank.name + " takes " + string(dmg_to_tank) +
        " (" + string(before_tank) + "→" + string(tank.hp) + ")."
    );

    if (sim_chance(sim, flank_base_chance)) {
        var off_i = sim_rand_range(sim, 1, array_length(sim.party) - 1);
        var off_target = sim.party[off_i];
        if (!off_target.dead && !off_target.retired && off_target.status_state != "downed") {
            var flank_dmg = max(1, floor(((base_dmg * sim_rand_range(sim, 30, 50)) / 100) * dmg_taken_mult) - floor(off_target.def * 0.5));
            var before_off = off_target.hp;
            off_target.hp -= flank_dmg;
            sim_log_tag(sim, "FLANK_HIT",
                "🪓 Flanking blow! " + off_target.name + " takes " + string(flank_dmg) +
                " (" + string(before_off) + "→" + string(off_target.hp) + ")."
            );
        }
    }

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
        sim_apply_party_damage(sim, floor(_mod.extra_splash * dmg_taken_mult));
    }

    // --- Thief identity: Execution mode ---
    var avg_hp_pct = sim_party_avg_hp_pct(sim);
    var exec_mode = (tank.hp <= 0) || (avg_hp_pct < 0.45) || (sim.tension > 75);

    if (!thief.dead && !thief.retired && thief.status_state != "downed") {
        var thief_base = max(1, thief.atk * 2 + sim_rand_range(sim, 2, 8));
        var thief_bonus = exec_mode ? sim_rand_range(sim, 2, 8) : 0;
        var thief_hit = floor((thief_base + thief_bonus) * party_out_mult);

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
    }

    // --- Mage hits back (MP matters) ---
    var mp_add = (is_struct(_mod)) ? _mod.mp_cost_add : 0;
    var mp_cost = clamp(2 + floor(threat / 3) + mp_add, 2, 8);

    var cast = (!mage.dead && !mage.retired && mage.status_state != "downed" && mage.mp >= mp_cost);
    var before_mp = mage.mp;

    var mage_crit = sim_chance(sim, cast ? 18 : 10);
    var mage_hit;

    if (cast) {
        mage.mp -= mp_cost;
        mage_hit = floor(((threat * 7) + sim_rand_range(sim, 6, 18) + floor(mage.atk * 0.5)) * party_out_mult);
    } else if (!mage.dead && !mage.retired && mage.status_state != "downed") {
        mage_hit = floor(((threat * 3) + sim_rand_range(sim, 2, 10)) * party_out_mult);
    } else {
        mage_hit = 0;
    }

    if (mage_crit) mage_hit *= 2;

    if (mage_hit > 0) {
        sim_log_tag(sim, mage_crit ? "MAGE_CRIT" : "MAGE_HIT",
            "✨ " + mage.name + (cast ? " casts" : " jabs") +
            " for " + string(mage_hit) + (mage_crit ? " (CRIT!)." : ".") +
            (cast ? (" [MP " + string(before_mp) + "→" + string(mage.mp) + "]") : " [NO MP]")
        );
    }

    // --- Healer reacts ---
    sim_auto_heal(sim);

    // --- Knockdowns / near-death / death consistency ---
    sim_check_party_health(sim);

    // Tank crisis tracking and anti-loop interventions.
    var crisis_add = 0;
    if (tank.hp < floor(tank.max_hp * 0.25)) crisis_add += 1;
    if (dmg_to_tank >= floor(tank.max_hp * 0.30)) crisis_add += 2;
    if (tank.wounds > pre_wounds) crisis_add += 2;
    if (sim.stats.tank_downed_count > pre_tank_downed) crisis_add += 4;

    var crisis_score = sim_push_tank_crisis(sim, crisis_add);

    if (crisis_score >= 10 && tactics.withdrawal_left <= 0) {
        tactics.withdrawal_left = 2;
        sim_log_tag(sim, "TACTIC", "🏃 [TACTIC] Controlled withdrawal initiated: next encounters will be lighter.");
    } else if (crisis_score >= 7 && tactics.cover_left <= 0) {
        tactics.cover_left = 2;
        sim_log_tag(sim, "TACTIC", "🧱 [TACTIC] Choke point secured: incoming accuracy reduced for 2 beats.");
    } else if (crisis_score >= 4 && tactics.defensive_left <= 0) {
        tactics.defensive_left = 2;
        sim_log_tag(sim, "TACTIC", "🛡 [TACTIC] Defensive stance called: reduced damage taken for 2 beats.");
    }

    // --- Tension climbs ---
    sim.tension = clamp(sim.tension + sim_rand_range(sim, 6, 14), 0, 100);
}
