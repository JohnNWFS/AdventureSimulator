function sim_check_party_health(sim) {

    var RETIRE_WOUNDS_MIN = 6;
    var RETIRE_WOUNDS_HARD = 10;
    var WOUND_RETREAT_THRESHOLD = variable_struct_exists(sim, "wound_retreat_threshold") ? sim.wound_retreat_threshold : 3;
    var RESOLVE_HIT_KD = 12;

    for (var i = 0; i < array_length(sim.party); i++) {
        var p = sim.party[i];

        if (p.dead || p.retired) {
            p.downed_this_beat = false;
            continue;
        }

        if (p.hp <= -p.max_hp) {
            p.dead = true;
            sim_log_tag(sim, "DEATH",
                "💀 " + p.name + " suffers catastrophic damage and dies (HP " +
                string(p.hp) + " vs -" + string(p.max_hp) + ")."
            );
            p.downed_this_beat = true;
            continue;
        }

        if (p.hp <= 0) {
            p.hp = 1;
            p.wounds += 1;
            p.def = max(0, p.base_def - p.wounds);

            if (is_struct(sim.stats) && variable_struct_exists(sim.stats, "knockdowns")) {
                sim.stats.knockdowns += 1;
            }

            p.resolve = clamp(p.resolve - RESOLVE_HIT_KD, 0, 100);

            sim_log_tag(sim, "KNOCKDOWN",
                "⚠ " + p.name + " collapses but is dragged onward (HP set to 1)."
            );
            sim_log_tag(sim, "WOUND",
                "🩸 Wounded: " + p.name + " gains a wound (" + string(p.wounds) +
                "). DEF now " + string(p.def) + "."
            );

            if (!sim.retreat_to_city && p.wounds >= WOUND_RETREAT_THRESHOLD) {
                sim.retreat_to_city = true;
                sim.city_scene_pending = true;
                sim.retreat_beats_left = sim_rand_range(sim, 3, 5);
                sim_log_tag(sim, "RETREAT_CALL",
                    "⚠ " + p.name + " has taken too many wounds. The party turns back toward the city."
                );
            }

            if (!p.retire_notice && p.wounds >= RETIRE_WOUNDS_MIN) {
                p.retire_notice = true;
                p.exit_flagged = true;
                p.exit_mode = "retire";
                sim_log_tag(sim, "RETIRE_NOTICE",
                    "🪦 " + p.name + " looks shaken. Retirement is on the table."
                );
            }
        }

        var hp_pct = p.hp / max(1, p.max_hp);

        // Count near-death pressure continuously so persistent danger is visible in stats
        if (hp_pct < 0.20) {
            if (is_struct(sim.stats) && variable_struct_exists(sim.stats, "near_deaths")) {
                sim.stats.near_deaths += 1;
            }
            if (!p.near_death_flag) {
                p.near_death_flag = true;
                sim_log_tag(sim, "NEAR_DEATH",
                    "🚨 Near-death: " + p.name + " is under 20% HP!"
                );
            }
        } else if (p.near_death_flag && hp_pct > 0.35) {
            p.near_death_flag = false;
        }

        p.downed_this_beat = false;

        if (!p.retire_notice && p.wounds >= RETIRE_WOUNDS_HARD) {
            p.retire_notice = true;
            p.exit_flagged = true;
            p.exit_mode = "retire";
            sim_log_tag(sim, "RETIRE_NOTICE",
                "🪦 " + p.name + " has had enough. They'll likely retire at the next safe stop."
            );
        }
    }
}
