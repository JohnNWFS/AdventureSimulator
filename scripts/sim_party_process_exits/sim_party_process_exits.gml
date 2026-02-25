function sim_party_process_exits(sim, ev) {

    var safe_stop = (ev == "merchant" || ev == "relief" || ev == "city_scene" || sim.retreat_to_city);

    for (var i = 0; i < array_length(sim.party); i++) {
        var p = sim.party[i];

        if (p.dead) {
            p.status_state = "dead";
            p.pending_honor = true;
            sim.city_scene_pending = true;
            continue;
        }

        if (!p.retired && !p.dead && p.retire_notice && safe_stop) {
            var wound_push = max(0, (p.wounds - 3) * 10);
            var near_death_push = p.near_death_count * 8;
            var resolve_pull = max(0, (70 - p.resolve));
            var pressure_score = clamp(20 + wound_push + near_death_push + resolve_pull, 20, 95);

            if (pressure_score >= 55) {
                p.exit_flagged = true;
                p.exit_mode = "retire";
                sim.city_scene_pending = true;
            }
        }
    }
}

function sim_resolve_city_scene(sim) {
    if (variable_struct_exists(sim, "city_phase_executed") && sim.city_phase_executed) {
        return;
    }

    sim.city_scene_pending = false;
    sim.city_scene_played = true;
    sim.city_phase_executed = true;

    sim_log_tag(sim, "CITY_ARRIVE",
        "🏙 The party returns to the city to recover, honor the fallen, and make hard decisions."
    );

    var avg_hp_pct = sim_party_avg_hp_pct(sim);
    var rep_delta = 0;
    if (sim.stats.boss_defeated && sim.stats.downed_events <= 0) rep_delta += 3;
    if (avg_hp_pct > 0.80) rep_delta += 2;
    if (sim.stats.downed_events > 0) rep_delta -= 2;
    if (!sim.stats.boss_defeated || sim.retreat_to_city) rep_delta -= 3;
    if (sim.stats.rerolls_count >= 5) rep_delta -= 1;

    sim.city_reputation += rep_delta;
    sim.city_favor = clamp(sim.city_favor + max(-2, floor(rep_delta / 2)), -10, 10);

    if (sim.city_reputation >= 6) {
        sim.city_reputation_tier = "high";
        sim.city_merchant_price_mult = 0.85;
    } else if (sim.city_reputation <= -4) {
        sim.city_reputation_tier = "low";
        sim.city_merchant_price_mult = 1.20;
    } else {
        sim.city_reputation_tier = "neutral";
        sim.city_merchant_price_mult = 1.0;
    }
    sim.city_merchant_effect_pending = true;

    sim_log_tag(sim, "CITY_REPUTATION_UPDATE",
        "📈 Reputation " + string(rep_delta) + " (total=" + string(sim.city_reputation) + ", tier=" + sim.city_reputation_tier + ", favor=" + string(sim.city_favor) + ")."
    );

    for (var i = 0; i < array_length(sim.party); i++) {
        var p = sim.party[i];

        if (p.dead && p.pending_honor) {
            sim_log_tag(sim, "HONOR_FALLEN", "⚰ Bells ring for " + p.name + ". Their deeds are remembered.");
            p.pending_honor = false;

            if (is_struct(sim.stats) && variable_struct_exists(sim.stats, "deaths")) {
                sim.stats.deaths += 1;
            }
            sim_party_apply_legacy(sim, p, "death");
        }

        if (sim_party_is_active(p) && p.injury_lingering) {
            var recover_cost = max(8, floor((p.base_max_hp + p.base_atk * 3) * 0.20));
            if (sim.gold_total >= recover_cost) {
                sim.gold_total -= recover_cost;
                p.injury_lingering = false;
                p.injury_penalty_pct = 0;
                p.injury_stat = "";
                p.injury_flag = false;
                sim_recalc_derived(p);
                sim_log_tag(sim, "INJURY_RECOVERED",
                    "💊 " + p.name + " pays " + string(recover_cost) + "g for treatment and returns to full form."
                );
            }
        }

        if (sim_party_is_active(p) && p.injury_flag) {
            var linger = sim_chance(sim, 40);
            if (p.injury_lingering) linger = true;

            if (linger) {
                var recover_cost2 = max(10, floor((p.base_max_hp + p.base_atk * 2) * 0.18));
                if (sim.gold_total >= recover_cost2 && sim_chance(sim, 55)) {
                    sim.gold_total -= recover_cost2;
                    p.injury_lingering = false;
                    p.injury_penalty_pct = 0;
                    p.injury_stat = "";
                    p.injury_flag = false;
                    sim_log_tag(sim, "INJURY_RECOVERED",
                        "🧵 " + p.name + " settles a " + string(recover_cost2) + "g clinic bill and avoids a lasting injury."
                    );
                } else {
                    var stat_roll = sim_rand_range(sim, 0, 2);
                    p.injury_lingering = true;
                    p.injury_penalty_pct = 10;
                    if (stat_roll == 0) p.injury_stat = "atk";
                    else if (stat_roll == 1) p.injury_stat = "def";
                    else p.injury_stat = "max_hp";
                    sim_log_tag(sim, "INJURY_LINGERS",
                        "🩹 " + p.name + " carries a lingering injury (" + p.injury_stat + " -10%) into the next episode."
                    );
                }
            } else {
                p.injury_lingering = false;
                p.injury_penalty_pct = 0;
                p.injury_stat = "";
                p.injury_flag = false;
                sim_log_tag(sim, "INJURY_RECOVERED",
                    "🌿 " + p.name + " recovers naturally before departure."
                );
            }
        }

        if (sim_party_is_active(p) && p.exit_flagged && p.exit_mode == "retire") {
            p.retired = true;
            p.status_state = "retired";

            sim_log_tag(sim, "VOLUNTARY_RETIREMENT",
                "🏳 " + p.name + " steps away after too many close calls."
            );

            if (is_struct(sim.stats) && variable_struct_exists(sim.stats, "retirements")) {
                sim.stats.retirements += 1;
            }
            sim_party_apply_legacy(sim, p, "retire");
        }

        if (sim_party_is_active(p)) {
            var wound_heal = min(2, p.wounds);
            var before_wounds = p.wounds;
            p.wounds -= wound_heal;
            p.hp = max(2, p.hp);
            p.status_state = "alive";
            p.city_underperform_flag = (p.base_atk <= 7 && p.near_death_count >= 1);
            if (p.near_death_count >= 2 || p.city_underperform_flag) p.city_pressure_marks += 1;
            p.dropped_below_30 = false;
            sim_recalc_derived(p);

            sim_log_tag(sim, "CITY_SHOP",
                "🛠 " + p.name + " receives treatment and repairs (wounds " + string(before_wounds) + "→" + string(p.wounds) + ")."
            );
        }

        p.exit_flagged = false;
        p.exit_mode = "none";
        p.retire_notice = false;
    }

    for (var j = 0; j < array_length(sim.party); j++) {
        var out = sim.party[j];
        var forced_dismissal = (sim_party_is_active(out) && out.city_pressure_marks >= 3);
        if (forced_dismissal) {
            out.retired = true;
            out.status_state = "retired";
            sim_log_tag(sim, "VOLUNTARY_RETIREMENT",
                "📉 " + out.name + " is dismissed after repeated failures under city scrutiny."
            );
        }

        if (!out.dead && !out.retired) continue;

        var role_key = "tank";
        var role_name = "Tank";
        var hp = 70, mp = 5, atk = 8, def = 6;

        if (j == 1) { role_key = "mage"; role_name = "Mage"; hp = 40; mp = 30; atk = 12; def = 2; }
        if (j == 2) { role_key = "thief"; role_name = "Thief"; hp = 45; mp = 10; atk = 10; def = 3; }
        if (j == 3) { role_key = "healer"; role_name = "Healer"; hp = 42; mp = 28; atk = 6; def = 3; }

        if (sim.city_reputation_tier == "high") {
            atk += 1;
            hp += 3;
        }
        if (sim.city_reputation_tier == "low") {
            atk = max(5, atk - 1);
        }

        var new_name = sim_name_pick(sim, role_key);
        sim.party[j] = sim_make_party_member(role_name, new_name, hp, mp, atk, def);
        sim.party[j].city_pressure_marks = 0;

        sim_log_tag(sim, "NEW_RECRUIT",
            "🧑 " + sim.party[j].name + " arrives as the new " + role_name + "."
        );
    }

    var event_roll = (sim.seed + sim.beat + sim.city_reputation + sim.stats.downed_events + sim.stats.rerolls_count + array_length(sim.party)) mod 4;
    if (event_roll < 0) event_roll += 4;
    if (event_roll == 0) {
        sim.city_tension_threshold_shift = -4;
        sim_log_tag(sim, "FACTION_EVENT", "🏛 Patron pressure rises: progress must accelerate next episode.");
    } else if (event_roll == 1) {
        sim.city_ambush_bonus_next += 1;
        sim_log_tag(sim, "FACTION_EVENT", "🗡 Rival guild rumors spread: ambush risk increases.");
    } else if (event_roll == 2) {
        for (var b = 0; b < array_length(sim.party); b++) {
            var pb = sim.party[b];
            if (sim_party_is_active(pb)) pb.hp = min(pb.max_hp, pb.hp + floor(pb.max_hp * 0.15));
        }
        sim_log_tag(sim, "FACTION_EVENT", "⛪ Temple blessing bolsters the party before departure.");
    } else {
        var levy = max(6, floor(sim.gold_total * 0.12));
        sim.gold_total = max(0, sim.gold_total - levy);
        sim_log_tag(sim, "FACTION_EVENT", "💰 Tax levy drains " + string(levy) + "g from the coffers.");
    }

    sim_log_tag(sim, "CITY_EFFECT_APPLIED",
        "🎛 City effects armed for next episode (merchant x" + string_format(sim.city_merchant_price_mult, 1, 2) + ", ambush+" + string(sim.city_ambush_bonus_next) + ", tensionShift=" + string(sim.city_tension_threshold_shift) + ")."
    );

    if (!variable_struct_exists(sim, "cine_roster_emitted_for_city_depart")) sim.cine_roster_emitted_for_city_depart = -1;
    sim_log_tag(sim, "CITY_DEPART", "🚪 The party departs the city and returns to the crawl.");

    sim.retreat_to_city = false;
    sim.retreat_beats_left = 0;
    sim.director.retreat_bridge_left = 0;
    sim.city_phase_executed = false;
    sim.episode_index += 1;
}
