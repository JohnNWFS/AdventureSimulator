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

    var debug_budget = variable_global_exists("debug_verbose") ? global.debug_verbose : false;
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

        if (debug_budget) {
            sim_log_tag(sim, "ENCOUNTER_BUDGET",
                "[ENCOUNTER_BUDGET] party=" + string(enc.party_power) +
                " threat=" + string(enc.total) +
                " ratio=" + string_format(enc.ratio, 1, 2) +
                " tier=" + enc.tag +
                " scaled=0 bestfit=0 degraded=1"
            );
        }

        sim.tension = clamp(sim.tension + 4, 0, 100);
        return;
    }

    if (enc.scaled) {
        sim.stats.encounter_scaled_down += 1;
        var removed_enemy = (!is_undefined(enc.removed_enemy_name) && enc.removed_enemy_name != "");
        if (removed_enemy) {
            sim_log_tag(sim, "ENCOUNTER_SHIFT", "🪓 Budget scale-down removed " + enc.removed_enemy_name + " from the encounter.");
        } else if (debug_budget) {
            sim_log_tag(sim, "ENCOUNTER_SHIFT", "🧪 Budget scale-down applied a light non-boss weakening to keep threat fair.");
        }
    } else {
        sim.stats.encounter_accepted += 1;
    }

    if (enc.bestfit_selected) sim.stats.encounter_bestfit_selected += 1;

    if (debug_budget) {
        sim_log_tag(sim, "ENCOUNTER_BUDGET",
            "[ENCOUNTER_BUDGET] party=" + string(enc.party_power) +
            " threat=" + string(enc.total) +
            " ratio=" + string_format(enc.ratio, 1, 2) +
            " tier=" + enc.tag +
            " scaled=" + string(enc.scaled ? 1 : 0) +
            " bestfit=" + string(enc.bestfit_selected ? 1 : 0) +
            " degraded=0"
        );
    }

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
    if (!variable_struct_exists(tactics, "stagger_left")) tactics.stagger_left = 0;
    if (!variable_struct_exists(tactics, "withdrawal_announced")) tactics.withdrawal_announced = false;

    var dmg_taken_mult = 1.0;
    var flank_base_chance = 18;
    var party_out_mult = 1.0;

    if (tactics.stagger_left > 0) {
        party_out_mult *= 0.85;
        flank_base_chance += 6;
        tactics.stagger_left -= 1;
    }

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
        if (tactics.withdrawal_left <= 0) tactics.withdrawal_announced = false;
    }

    var had_ambush_pre_strike = false;
    // --- AMBUSH pre-strike ---
    if (is_struct(_mod) && _mod.pre_strike) {
        had_ambush_pre_strike = true;
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

    var base_dmg = ((threat * 3) + floor(sqrt(max(0, threat)) * 6) + sim_rand_range(sim, 3, 10));
    base_dmg = floor(base_dmg * dmg_mult * dmg_taken_mult);

    var eff_def = floor(tank.def * def_mult);
    var dmg_to_tank = max(0, base_dmg - eff_def);
    var per_hit_cap = floor(tank.max_hp * 0.55);
    if (enc.tag != "BOSS") dmg_to_tank = min(dmg_to_tank, per_hit_cap);

    if (enc.tag != "BOSS" && variable_struct_exists(sim.director, "last_tank_downed_beat") && (sim.beat - sim.director.last_tank_downed_beat) <= 2) {
        var floor_cap = -floor(tank.max_hp * 0.15);
        var min_hp_after = max(floor_cap, tank.hp - dmg_to_tank);
        dmg_to_tank = tank.hp - min_hp_after;
    }

    var before_tank = tank.hp;
    var pre_wounds = tank.wounds;
    var pre_tank_downed = sim.stats.tank_downed_count;

    tank.hp -= dmg_to_tank;

    if ((dmg_to_tank >= floor(tank.max_hp * 0.45)) || (tank.hp > 0 && tank.hp < floor(tank.max_hp * 0.15))) {
        tactics.stagger_left = max(tactics.stagger_left, 1);
        if (tactics.defensive_left <= 0) tactics.defensive_left = 1;
        sim_log_tag(sim, "TANK_STAGGER", "🪨 " + tank.name + " staggers; formation slips.");
    }

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

    var had_chaos_splash = false;
    // --- Mid-fight chaos (allow execution blows) ---
    if (is_struct(_mod) && _mod.extra_splash > 0) {
        had_chaos_splash = true;
        sim_log_tag(sim, "CHAOS", "💢 Chaos erupts in the scrum.");
        sim_apply_party_damage(sim, floor(_mod.extra_splash * dmg_taken_mult));
    }

    // --- Thief identity: Execution mode ---
    var avg_hp_pct = sim_party_avg_hp_pct(sim);
    var exec_mode = (tank.hp <= 0) || (avg_hp_pct < 0.45) || (sim.tension > 75);
    var thief_misstep = false;

    if (!thief.dead && !thief.retired && thief.status_state != "downed") {
        var thief_base = max(1, thief.atk * 2 + sim_rand_range(sim, 2, 8));
        var thief_bonus = exec_mode ? sim_rand_range(sim, 2, 8) : 0;
        var thief_hit = floor((thief_base + thief_bonus) * party_out_mult);

        var thief_crit_chance = exec_mode ? 28 : 16;
        var thief_risk_success = false;
        var thief_risk_play = (!exec_mode && sim_chance(sim, 18));
        if (thief_risk_play) {
            if (sim_chance(sim, 70)) {
                thief_risk_success = true;
                thief_hit = floor(thief_hit * 1.60);
                thief_crit_chance += 10;
            } else {
                thief_hit = 0;
                thief_misstep = true;
                var thief_chip = sim_rand_range(sim, 3, 10);
                var thief_before_hp = thief.hp;
                thief.hp -= thief_chip;
                sim_log_tag(sim, "THIEF_MISSTEP",
                    "💥 " + thief.name + " overextends, takes " + string(thief_chip) +
                    " (" + string(thief_before_hp) + "→" + string(thief.hp) + ")."
                );
            }
        }

        var thief_crit = sim_chance(sim, thief_crit_chance);
        if (thief_crit) thief_hit *= 2;

        if (thief_hit > 0) {
            var thief_tag;
            if (thief_risk_success) thief_tag = "THIEF_GAMBLE";
            else if (exec_mode) thief_tag = thief_crit ? "THIEF_EXEC_CRIT" : "THIEF_EXEC";
            else thief_tag = thief_crit ? "THIEF_CRIT" : "THIEF_HIT";

            var thief_text = "🗡 " + thief.name +
                (exec_mode ? " smells blood" : " slips in") +
                ": " + string(thief_hit) + " damage" + (thief_crit ? " (CRIT!)." : ".");
            if (thief_risk_success) thief_text = "🎲 " + thief.name + " lunges: " + string(thief_hit) + " damage.";
            sim_log_tag(sim, thief_tag, thief_text);
        }
    }

    // --- Mage hits back (MP matters) ---
    var mp_add = (is_struct(_mod)) ? _mod.mp_cost_add : 0;
    var mp_cost = clamp(2 + floor(threat / 3) + mp_add, 2, 8);

    var cast = (!mage.dead && !mage.retired && mage.status_state != "downed" && mage.mp >= mp_cost);
    var before_mp = mage.mp;

    var mage_crit = sim_chance(sim, cast ? 18 : 10);
    var mage_hit;
    var mage_overchanneled = false;

    if (cast) {
        var high_tension = (sim.tension >= 70) || (tank.hp <= 0) || (tactics.stagger_left > 0);
        if (mage.mp >= (mp_cost + 2) && high_tension && sim_chance(sim, 25)) {
            mage_overchanneled = true;
            mage.mp -= (mp_cost + 2);
            mage_hit = floor((((threat * 7) + sim_rand_range(sim, 6, 18) + floor(mage.atk * 0.5)) * 1.25) * party_out_mult);
            var backlash = sim_rand_range(sim, 2, 6);
            var mage_before_hp = mage.hp;
            mage.hp -= backlash;
            sim_log_tag(sim, "MAGE_OVERCHANNEL",
                "⚡ " + mage.name + " overchannels: " + string(mage_hit) +
                " damage [MP " + string(before_mp) + "→" + string(mage.mp) + "] (backlash " + string(backlash) +
                ", HP " + string(mage_before_hp) + "→" + string(mage.hp) + ")."
            );
        } else {
            mage.mp -= mp_cost;
            mage_hit = floor(((threat * 7) + sim_rand_range(sim, 6, 18) + floor(mage.atk * 0.5)) * party_out_mult);
        }
    } else if (!mage.dead && !mage.retired && mage.status_state != "downed") {
        if (mage.mp < mp_cost && sim_chance(sim, 20)) {
            tactics.cover_left += 1;
            mage_hit = 0;
            sim_log_tag(sim, "MAGE_REPOSITION", "🌀 " + mage.name + " shifts the line; enemies lose their angle.");
        } else {
            mage_hit = floor(((threat * 3) + sim_rand_range(sim, 2, 10)) * party_out_mult);
        }
    } else {
        mage_hit = 0;
    }

    if (mage_crit) mage_hit *= 2;

    if (mage_hit > 0 && !mage_overchanneled) {
        sim_log_tag(sim, mage_crit ? "MAGE_CRIT" : "MAGE_HIT",
            "✨ " + mage.name + (cast ? " casts" : " jabs") +
            " for " + string(mage_hit) + (mage_crit ? " (CRIT!)." : ".") +
            (cast ? (" [MP " + string(before_mp) + "→" + string(mage.mp) + "]") : " [NO MP]")
        );
    }

    // --- Healer reacts ---
    var pre_heal_hp = [];
    var pre_heal_max_hp = [];
    for (var p = 0; p < array_length(sim.party); p++) {
        pre_heal_hp[p] = sim.party[p].hp;
        pre_heal_max_hp[p] = sim.party[p].max_hp;
    }

    sim_auto_heal(sim);

    var heal_note_done = false;
    var had_clutch = false;
    var had_major_heal = false;
    var had_tank_triage = false;
    var heal_target_name = "";
    var heal_before = 0;
    var heal_after = 0;

    for (var h = 0; h < array_length(sim.party); h++) {
        var member = sim.party[h];
        var hp_before = pre_heal_hp[h];
        var hp_after = member.hp;
        var healed_amount = hp_after - hp_before;

        if (hp_before <= 0 && hp_after > 0 && !had_clutch) {
            had_clutch = true;
            heal_target_name = member.name;
            heal_before = hp_before;
            heal_after = hp_after;
        }

        if (!had_major_heal && healed_amount > floor(pre_heal_max_hp[h] * 0.25)) {
            had_major_heal = true;
            heal_target_name = member.name;
            heal_before = hp_before;
            heal_after = hp_after;
        }
    }

    if (pre_heal_hp[0] <= floor(tank.max_hp * 0.15) && tank.hp >= floor(tank.max_hp * 0.30)) {
        had_tank_triage = true;
        heal_target_name = tank.name;
        heal_before = pre_heal_hp[0];
        heal_after = tank.hp;
    }

    // --- Knockdowns / near-death / death consistency ---
    sim_check_party_health(sim);

    // Tank crisis tracking and anti-loop interventions.
    var tank_downed_happened = (sim.stats.tank_downed_count > pre_tank_downed);

    var crisis_add = 0;
    if (tank.hp < floor(tank.max_hp * 0.25)) crisis_add += 1;
    if (dmg_to_tank >= floor(tank.max_hp * 0.30)) crisis_add += 2;
    if (tank.wounds > pre_wounds) crisis_add += 2;
    if (tank_downed_happened) crisis_add += 4;

    var crisis_score = sim_push_tank_crisis(sim, crisis_add);

    if (!heal_note_done && had_clutch) {
        sim_log_tag(sim, "HEAL_CLUTCH",
            "✋ " + healer.name + " yanks " + heal_target_name +
            " back from the brink (" + string(heal_before) + "→" + string(heal_after) + ")."
        );
        heal_note_done = true;
    } else if (!heal_note_done && had_tank_triage) {
        sim_log_tag(sim, "HEAL_TRIAGE",
            "🩺 " + healer.name + " triage steadies " + heal_target_name +
            " (" + string(heal_before) + "→" + string(heal_after) + ")."
        );
        heal_note_done = true;
    } else if (!heal_note_done && had_major_heal) {
        sim_log_tag(sim, "HEAL_TRIAGE",
            "🩺 " + healer.name + " triage surges through " + heal_target_name +
            " (" + string(heal_before) + "→" + string(heal_after) + ")."
        );
        heal_note_done = true;
    }

    if (crisis_score >= 10 && tactics.withdrawal_left <= 0) {
        tactics.withdrawal_left = 2;
        tactics.withdrawal_announced = false;
        sim_log_tag(sim, "TACTIC", "🏃 [TACTIC] Controlled withdrawal initiated: next encounters will be lighter.");
    } else if (crisis_score >= 7 && tactics.cover_left <= 0) {
        tactics.cover_left = 2;
        sim_log_tag(sim, "TACTIC", "🧱 [TACTIC] Choke point secured: incoming accuracy reduced for 2 beats.");
    } else if (crisis_score >= 4 && tactics.defensive_left <= 0) {
        tactics.defensive_left = 2;
        sim_log_tag(sim, "TACTIC", "🛡 [TACTIC] Defensive stance called: reduced damage taken for 2 beats.");
    }

    if ((crisis_score >= 10 || tank_downed_happened) && tactics.withdrawal_left < 2) {
        tactics.withdrawal_left = 2;
        tactics.withdrawal_announced = false;
    }
    if ((crisis_score >= 10 || tank_downed_happened) && !tactics.withdrawal_announced) {
        sim_log_tag(sim, "HEAL_COMMAND", "🗣 \"We are leaving NOW.\"");
        tactics.withdrawal_announced = true;
    }

    // --- Tension climbs ---
    var tension_add = sim_rand_range(sim, 6, 14);
    if (mage_overchanneled) tension_add += 2;
    if (thief_misstep) tension_add += 2;
    if (had_ambush_pre_strike) tension_add += 2;
    if (had_chaos_splash) tension_add += 2;
    sim.tension = clamp(sim.tension + tension_add, 0, 100);
}
