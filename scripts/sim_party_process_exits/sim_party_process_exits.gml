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
            var chance = clamp(20 + wound_push + near_death_push + resolve_pull, 20, 95);

            if (sim_chance(sim, chance)) {
                p.exit_flagged = true;
                p.exit_mode = "retire";
                sim.city_scene_pending = true;
            }
        }
    }
}

function sim_resolve_city_scene(sim) {
    sim.city_scene_pending = false;
    sim.city_scene_played = true;

    sim_log_tag(sim, "CITY_ARRIVE",
        "🏙 The party returns to the city to recover, honor the fallen, and make hard decisions."
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

        if (!p.dead && !p.retired && p.exit_flagged && p.exit_mode == "retire") {
            p.retired = true;
            p.status_state = "retired";

            sim_log_tag(sim, "RETIRE_DECISION",
                "🏳 " + p.name + " retires after too many close calls."
            );

            if (is_struct(sim.stats) && variable_struct_exists(sim.stats, "retirements")) {
                sim.stats.retirements += 1;
            }
            sim_party_apply_legacy(sim, p, "retire");
        }

        if (!p.dead && !p.retired && p.wounds > 0) {
            var wound_heal = min(2, p.wounds);
            var before_wounds = p.wounds;
            p.wounds -= wound_heal;
            p.hp = max(2, p.hp);
            p.status_state = "alive";
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
        if (!out.dead && !out.retired) continue;

        var role_key = "tank";
        var role_name = "Tank";
        var hp = 70, mp = 5, atk = 8, def = 6;

        if (j == 1) { role_key = "mage"; role_name = "Mage"; hp = 40; mp = 30; atk = 12; def = 2; }
        if (j == 2) { role_key = "thief"; role_name = "Thief"; hp = 45; mp = 10; atk = 10; def = 3; }
        if (j == 3) { role_key = "healer"; role_name = "Healer"; hp = 42; mp = 28; atk = 6; def = 3; }

        var new_name = sim_name_pick(sim, role_key);
        sim.party[j] = sim_make_party_member(role_name, new_name, hp, mp, atk, def);

        sim_log_tag(sim, "RECRUIT_JOIN",
            "🧑 " + sim.party[j].name + " joins as the new " + role_name + "."
        );
    }

    var tank_name = "Unknown";
    var thief_name = "Unknown";
    var mage_name = "Unknown";
    var healer_name = "Unknown";

    for (var k = 0; k < array_length(sim.party); k++) {
        var member = sim.party[k];
        if (member.role == "Tank") tank_name = member.name;
        else if (member.role == "Thief") thief_name = member.name;
        else if (member.role == "Mage") mage_name = member.name;
        else if (member.role == "Healer") healer_name = member.name;
    }

    sim_log_tag(sim, "PARTY_ROSTER",
        "Tank=" + tank_name + "; Thief=" + thief_name + "; Mage=" + mage_name + "; Healer=" + healer_name + "."
    );

    sim_log_tag(sim, "CITY_DEPART", "🚪 The party departs the city and returns to the crawl.");

    sim.retreat_to_city = false;
    sim.retreat_beats_left = 0;
    sim.director.retreat_bridge_left = 0;
}
