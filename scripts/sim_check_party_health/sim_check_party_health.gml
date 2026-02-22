function sim_check_party_health(sim) {

    var RETIRE_WOUNDS_MIN = 4;
    var RETIRE_WOUNDS_HARD = 7;
    var WOUND_RETREAT_THRESHOLD = variable_struct_exists(sim, "wound_retreat_threshold") ? sim.wound_retreat_threshold : 3;
    var DOWNED_WINDOW = 10;
    var RESOLVE_HIT_KD = 12;

    for (var i = 0; i < array_length(sim.party); i++) {
        var p = sim.party[i];

        if (p.dead || p.retired) {
            p.downed_this_beat = false;
            continue;
        }

        if (p.hp <= -p.max_hp) {
            p.dead = true;
            p.status_state = "dead";
            p.pending_honor = true;
            p.hp = min(p.hp, -1);
            sim_log_tag(sim, "DEATH",
                "💀 " + p.name + " falls. Their body is carried back for honors."
            );
            sim.city_scene_pending = true;
            continue;
        }

        if (p.hp <= 0) {
            p.status_state = "downed";
            p.hp = 1;
            var chain_from_near_death = (variable_struct_exists(p, "near_death_triggered_this_beat") && p.near_death_triggered_this_beat);

            if (!chain_from_near_death) {
                p.wounds += 1;
                p.def = max(0, p.base_def - p.wounds);
            }

            if (is_struct(sim.stats) && variable_struct_exists(sim.stats, "knockdowns")) {
                sim.stats.knockdowns += 1;
            }
            if (is_struct(sim.stats) && variable_struct_exists(sim.stats, "downed_events")) {
                sim.stats.downed_events += 1;
            }
            if (is_struct(sim.stats) && variable_struct_exists(sim.stats, "total_downed_count")) {
                sim.stats.total_downed_count += 1;
            }
            if (p.role == "Tank" && is_struct(sim.stats) && variable_struct_exists(sim.stats, "tank_downed_count")) {
                sim.stats.tank_downed_count += 1;
                if (is_struct(sim.director)) sim.director.last_tank_downed_beat = sim.beat;
            }

            if (!is_array(p.recent_downed_beats)) p.recent_downed_beats = [];
            array_push(p.recent_downed_beats, sim.beat);
            var k = 0;
            while (k < array_length(p.recent_downed_beats)) {
                if (sim.beat - p.recent_downed_beats[k] > DOWNED_WINDOW) {
                    array_delete(p.recent_downed_beats, k, 1);
                } else {
                    k += 1;
                }
            }

            p.resolve = clamp(p.resolve - RESOLVE_HIT_KD, 0, 100);

            if (!p.downed_this_beat) {
                sim_log_tag(sim, "DOWNED",
                    "⚠ " + p.name + " is downed and stabilized at 1 HP."
                );
                if (!chain_from_near_death) {
                    sim_log_tag(sim, "WOUND",
                        "🩸 Wounded: " + p.name + " gains a wound (" + string(p.wounds) +
                        "). DEF now " + string(p.def) + "."
                    );
                }
            }
            p.downed_this_beat = true;

            if (!sim.retreat_to_city && p.wounds >= WOUND_RETREAT_THRESHOLD) {
                sim.retreat_to_city = true;
                sim.city_scene_pending = true;
                sim.retreat_beats_left = sim_rand_range(sim, 1, 2);
                sim.director.retreat_bridge_left = sim_rand_range(sim, 1, 2);
                sim_log_tag(sim, "RETREAT_CALL",
                    "⚠ The party breaks off and heads to the city before someone dies."
                );
            }

            if (!sim.retreat_to_city && array_length(p.recent_downed_beats) >= 2) {
                sim.retreat_to_city = true;
                sim.city_scene_pending = true;
                sim.retreat_beats_left = max(sim.retreat_beats_left, 2);
                sim.director.retreat_bridge_left = max(sim.director.retreat_bridge_left, 1);
                sim.director.downed_loop_interventions += 1;
                var caller = "the party";
                if (array_length(sim.party) > 3) {
                    var healer = sim.party[3];
                    if (!healer.dead && !healer.retired) caller = healer.name;
                }
                sim_log_tag(sim, "RETREAT_VOTE",
                    "🗳 [RETREAT_VOTE] " + caller + " calls for a withdrawal after repeated knockdowns."
                );
                sim_log_tag(sim, "RETREAT_CALL",
                    "🏃 Repeated knockdowns force an escape call before the fight spirals."
                );
                var retreat_costs = ["lost time", "reduced loot chance", "heightened pursuit risk"];
                var retreat_cost = retreat_costs[sim_rand_range(sim, 0, array_length(retreat_costs) - 1)];
                sim_log_tag(sim, "RETREAT_COST",
                    "⚖ Retreat consequence: " + retreat_cost + "."
                );
            }

            if (!p.retire_notice && (p.wounds >= RETIRE_WOUNDS_MIN || p.near_death_count >= 3)) {
                p.retire_notice = true;
                p.exit_flagged = true;
                p.exit_mode = "retire";
                sim_log_tag(sim, "RETIRE_NOTICE",
                    "🪦 " + p.name + " is badly battered and may retire in town."
                );
                sim.city_scene_pending = true;
            }
        } else if (p.status_state == "downed") {
            p.status_state = "alive";
        }

        var hp_pct = p.hp / max(1, p.max_hp);

        if (hp_pct < 0.20) {
            if (!p.near_death_flag) {
                p.near_death_flag = true;
                p.near_death_triggered_this_beat = true;
                p.near_death_count += 1;
                p.wounds += 1;
                p.def = max(0, p.base_def - p.wounds);
                if (is_struct(sim.stats) && variable_struct_exists(sim.stats, "near_deaths")) {
                    sim.stats.near_deaths += 1;
                }
                if (!p.near_death_logged_once) {
                    p.near_death_logged_once = true;
                    sim_log_tag(sim, "NEAR_DEATH",
                        "🚨 Near-death: " + p.name + " is under 20% HP!"
                    );
                }
                sim_log_tag(sim, "WOUND",
                    "🩸 " + p.name + " carries another lasting wound (" + string(p.wounds) + ")."
                );
            }
        } else if (p.near_death_flag && hp_pct > 0.35) {
            p.near_death_flag = false;
        }

        p.near_death_triggered_this_beat = false;
        p.downed_this_beat = false;

        if (!p.retire_notice && (p.wounds >= RETIRE_WOUNDS_HARD || p.near_death_count >= 4)) {
            p.retire_notice = true;
            p.exit_flagged = true;
            p.exit_mode = "retire";
            sim_log_tag(sim, "RETIRE_NOTICE",
                "🪦 " + p.name + " has had enough. Retirement is likely at the next city return."
            );
            sim.city_scene_pending = true;
        }
    }
}
