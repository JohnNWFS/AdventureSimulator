function sim_calc_party_power(sim) {
    var party_power = 0;

    for (var i = 0; i < array_length(sim.party); i++) {
        var p = sim.party[i];
        if (p.dead || p.retired) continue;

        sim_recalc_derived(p);

        var hp_weight = floor(p.max_hp * 0.10);
        var atk_weight = floor(p.atk * 0.90);
        var def_weight = floor(p.def * 1.10);
        var mp_weight = ((p.role == "Mage") || (p.role == "Healer")) ? floor(p.max_mp * 0.08) : 0;

        var tier_bonus = 0;
        if (is_struct(p.equip)) {
            var ew = p.equip.weapon;
            var ea = p.equip.armor;
            var et = p.equip.trinket;
            if (!is_undefined(ew) && is_struct(ew) && variable_struct_exists(ew, "tier")) tier_bonus += floor(ew.tier * 0.6);
            if (!is_undefined(ea) && is_struct(ea) && variable_struct_exists(ea, "tier")) tier_bonus += floor(ea.tier * 0.6);
            if (!is_undefined(et) && is_struct(et) && variable_struct_exists(et, "tier")) tier_bonus += floor(et.tier * 0.5);
        }

        party_power += max(1, hp_weight + atk_weight + def_weight + mp_weight + tier_bonus);
    }

    return max(8, party_power);
}

function sim_pick_encounter_tier(sim) {
    var normal_cap_ratio = 1.25;
    var hard_cap_ratio = 1.45;

    var tier = "NORMAL";
    var min_ratio = 0.75;
    var max_ratio = normal_cap_ratio;

    var hard_chance = 10 + ((sim.tension > 72) ? 6 : 0);
    if (sim_chance(sim, hard_chance)) {
        tier = "HARD";
        min_ratio = 1.10;
        max_ratio = hard_cap_ratio;
    }

    if (is_struct(sim.director) && variable_struct_exists(sim.director, "tank_tactic_state")) {
        var state = sim.director.tank_tactic_state;
        if (state.withdrawal_left > 0) {
            tier = "NORMAL";
            min_ratio = 0.75;
            max_ratio = min(normal_cap_ratio, 0.95);
        }
    }

    return { tier: tier, min_ratio: min_ratio, max_ratio: max_ratio };
}

function sim_format_budget_line(party_power, encounter_threat, cap_used, tag, result_tag) {
    var safe_party = max(1, party_power);
    var ratio = encounter_threat / safe_party;
    var line =
        "[ENCOUNTER_BUDGET] party=" + string(party_power) +
        " threat=" + string(encounter_threat) +
        " ratio=" + string_format(ratio, 1, 2) +
        " cap=" + string_format(cap_used, 1, 2) +
        " tag=" + tag +
        " result=" + result_tag;
    return line;
}

function sim_try_scale_encounter(enc, cap_ratio, boss_cap_ratio, force_scale) {
    if (!is_struct(enc) || !variable_struct_exists(enc, "enemies") || !is_array(enc.enemies)) return undefined;
    if (enc.tag == "BOSS") return undefined;

    var party_power = max(1, enc.party_power);
    var ratio = enc.total / party_power;
    if (!force_scale && ratio > cap_ratio + 0.20) return undefined;

    var enemies = enc.enemies;
    var enemy_count = array_length(enemies);
    if (enemy_count <= 0) return undefined;

    var removed_name = "";
    var scaled_total = enc.total;

    if (enemy_count > 1) {
        var remove_idx = 0;
        var remove_threat = enemies[0].threat;
        for (var i = 1; i < enemy_count; i++) {
            if (enemies[i].threat > remove_threat) {
                remove_threat = enemies[i].threat;
                remove_idx = i;
            }
        }
        removed_name = enemies[remove_idx].name;
        array_delete(enemies, remove_idx, 1);

        scaled_total = 0;
        for (var j = 0; j < array_length(enemies); j++) {
            scaled_total += enemies[j].threat;
        }
    } else {
        scaled_total = floor(enc.total * 0.90);
    }

    var scaled_ratio = scaled_total / party_power;
    if (scaled_ratio > boss_cap_ratio + 0.35) return undefined;

    var names = "";
    for (var n = 0; n < array_length(enemies); n++) {
        if (names != "") names += ", ";
        names += enemies[n].name;
    }

    return {
        names: names,
        total: max(1, scaled_total),
        tag: enc.tag,
        scaled: true,
        removed_enemy_name: removed_name,
        weakened_only: (enemy_count <= 1),
        party_power: enc.party_power,
        cap_ratio: cap_ratio,
        enemies: enemies
    };
}

function sim_make_combat_encounter(sim, party_power) {
    var MAX_REROLLS_PER_ENCOUNTER = 10;
    var BOSS_CAP_RATIO = 1.80;

    var pool = [
        { name: "Skeleton", base: 5 },
        { name: "Bandit", base: 6 },
        { name: "Goblin", base: 4 },
        { name: "Slime", base: 3 },
        { name: "Warg", base: 7 },
        { name: "Cult Acolyte", base: 6 },
        { name: "Ogre Brute", base: 11 }
    ];

    var tier_pick = sim_pick_encounter_tier(sim);
    var tag = tier_pick.tier;
    var cap_ratio = tier_pick.max_ratio;

    var min_budget = floor(party_power * tier_pick.min_ratio);
    var max_budget = floor(party_power * tier_pick.max_ratio);
    var boss_cap = floor(party_power * BOSS_CAP_RATIO);
    max_budget = min(max_budget, boss_cap);

    var debug_budget = variable_global_exists("debug_verbose") ? global.debug_verbose : false;
    var rerolls = 0;
    var prevented = 0;
    var attempts = 0;
    var candidates = [];

    for (var attempt = 0; attempt < MAX_REROLLS_PER_ENCOUNTER; attempt++) {
        var group_size = sim_rand_range(sim, 1, 3);
        var total = 0;
        var names = "";
        var enemies = [];

        for (var i = 0; i < group_size; i++) {
            var e = pool[sim_rand_range(sim, 0, array_length(pool) - 1)];
            var per_enemy = floor((e.base + sim_rand_range(sim, -1, 2)) * (1 + sim.difficulty * 0.08));

            // Smooth non-boss spikes.
            var non_boss_cap = max(3, floor(party_power * 0.45));
            per_enemy = clamp(per_enemy, 2, non_boss_cap);

            total += per_enemy;
            if (names != "") names += ", ";
            names += e.name;
            array_push(enemies, { name: e.name, threat: per_enemy });
        }

        attempts += 1;

        var ratio = total / max(1, party_power);
        var candidate = {
            names: names,
            total: total,
            tag: tag,
            party_power: party_power,
            ratio: ratio,
            cap_ratio: cap_ratio,
            enemies: enemies
        };
        array_push(candidates, candidate);

        if (total > boss_cap) {
            prevented += 1;
            rerolls += 1;
            if (debug_budget) sim_log_tag(sim, "ENCOUNTER_BUDGET", sim_format_budget_line(party_power, total, cap_ratio, tag, "REROLL"));
            continue;
        }

        if (total >= min_budget && total <= max_budget) {
            if (debug_budget) sim_log_tag(sim, "ENCOUNTER_BUDGET", sim_format_budget_line(party_power, total, cap_ratio, tag, "ACCEPT"));
            return {
                degraded: false,
                scaled: false,
                bestfit_selected: false,
                names: names,
                total: total,
                tag: tag,
                rerolls: rerolls,
                prevented: prevented,
                attempts: attempts
            };
        }

        var scaled_attempt = sim_try_scale_encounter(candidate, cap_ratio, BOSS_CAP_RATIO, false);
        if (!is_undefined(scaled_attempt)) {
            prevented += 1;
            if (debug_budget) sim_log_tag(sim, "ENCOUNTER_BUDGET", sim_format_budget_line(party_power, total, cap_ratio, tag, "SCALED"));
            return {
                degraded: false,
                scaled: true,
                bestfit_selected: false,
                names: scaled_attempt.names,
                total: scaled_attempt.total,
                tag: tag,
                rerolls: rerolls,
                prevented: prevented,
                attempts: attempts,
                removed_enemy_name: scaled_attempt.removed_enemy_name,
                weakened_only: scaled_attempt.weakened_only
            };
        }

        rerolls += 1;
        if (total > max_budget) prevented += 1;
        if (debug_budget) sim_log_tag(sim, "ENCOUNTER_BUDGET", sim_format_budget_line(party_power, total, cap_ratio, tag, "REROLL"));
    }

    var bestfit_under_cap = undefined;
    for (var c = 0; c < array_length(candidates); c++) {
        var cand = candidates[c];
        if (cand.ratio <= cap_ratio) {
            if (is_undefined(bestfit_under_cap) || cand.ratio > bestfit_under_cap.ratio) {
                bestfit_under_cap = cand;
            }
        }
    }

    if (!is_undefined(bestfit_under_cap)) {
        if (debug_budget) sim_log_tag(sim, "ENCOUNTER_BUDGET", sim_format_budget_line(party_power, bestfit_under_cap.total, cap_ratio, tag, "ACCEPT"));
        return {
            degraded: false,
            scaled: false,
            bestfit_selected: true,
            names: bestfit_under_cap.names,
            total: bestfit_under_cap.total,
            tag: tag,
            rerolls: rerolls,
            prevented: prevented,
            attempts: attempts + 1
        };
    }

    var lowest_over_cap = undefined;
    for (var m = 0; m < array_length(candidates); m++) {
        var over = candidates[m];
        if (is_undefined(lowest_over_cap) || over.ratio < lowest_over_cap.ratio) lowest_over_cap = over;
    }

    if (!is_undefined(lowest_over_cap)) {
        var scaled_fallback = sim_try_scale_encounter(lowest_over_cap, cap_ratio, BOSS_CAP_RATIO, true);
        if (!is_undefined(scaled_fallback)) {
            prevented += 1;
            if (debug_budget) sim_log_tag(sim, "ENCOUNTER_BUDGET", sim_format_budget_line(party_power, lowest_over_cap.total, cap_ratio, tag, "SCALED"));
            return {
                degraded: false,
                scaled: true,
                bestfit_selected: false,
                names: scaled_fallback.names,
                total: scaled_fallback.total,
                tag: tag,
                rerolls: rerolls,
                prevented: prevented,
                attempts: attempts + 1,
                removed_enemy_name: scaled_fallback.removed_enemy_name,
                weakened_only: scaled_fallback.weakened_only
            };
        }
    }

    if (debug_budget) {
        var threat_log = is_undefined(lowest_over_cap) ? 0 : lowest_over_cap.total;
        sim_log_tag(sim, "ENCOUNTER_BUDGET", sim_format_budget_line(party_power, threat_log, cap_ratio, tag, "DEGRADED"));
    }

    return {
        degraded: true,
        scaled: false,
        bestfit_selected: false,
        tag: tag,
        rerolls: rerolls,
        prevented: prevented + 1,
        attempts: attempts + 1,
        total: 0,
        names: ""
    };
}

function sim_push_tank_crisis(sim, crisis_add) {
    if (!is_struct(sim.director)) return 0;

    if (!variable_struct_exists(sim.director, "tank_crisis_window")) sim.director.tank_crisis_window = 10;
    if (!variable_struct_exists(sim.director, "tank_crisis_history") || !is_array(sim.director.tank_crisis_history)) {
        sim.director.tank_crisis_history = [];
    }

    array_push(sim.director.tank_crisis_history, { beat: sim.beat, score: crisis_add });

    var k = 0;
    while (k < array_length(sim.director.tank_crisis_history)) {
        var entry = sim.director.tank_crisis_history[k];
        if (sim.beat - entry.beat >= sim.director.tank_crisis_window) array_delete(sim.director.tank_crisis_history, k, 1);
        else k += 1;
    }

    var score = 0;
    for (var i = 0; i < array_length(sim.director.tank_crisis_history); i++) {
        score += sim.director.tank_crisis_history[i].score;
    }

    return score;
}

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
