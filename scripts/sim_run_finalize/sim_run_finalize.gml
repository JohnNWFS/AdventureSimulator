function sim_run_finalize(sim) {
    if (sim.finished && sim.beat >= sim.beats_target) return;

    sim.finished = true;

    if (!sim.city_scene_played || sim_party_any_dead(sim)) {
        sim.city_scene_pending = true;
        sim_resolve_city_scene(sim);
    }

    // Score quick summary
    if (sim.stats.near_deaths <= 0 && sim.stats.total_downed_count > 0) sim.stats.near_deaths = sim.stats.total_downed_count;
    var avg_hp_pct = sim_party_avg_hp_pct(sim);
    sim_log(sim, "📺 Episode ends. Gold=" + string(sim.gold_total) +
        " | Chests=" + string(sim.stats.chests_opened) +
        " | Merchants=" + string(sim.stats.merchants_seen) +
        " | Rares=" + string(sim.stats.rares_found) +
        " | Near-deaths=" + string(sim.stats.near_deaths) +
        " | Boss=" + (sim.stats.boss_defeated ? "DEFEATED" : "NO"));

    sim_log(sim, "[DEBUG] tension_current=" + string(sim.tension_current) +
        " | threshold=" + string(sim.tension_threshold) +
        " | boss_trigger_beat=" + string(sim.stats.boss_trigger_beat));

    sim_log(sim, "📊 Party avg HP%: " + string(round(avg_hp_pct * 100)) + "%");
    sim_log(sim,
        "📊 Beat counts: Combat=" + string(sim.coverage.combat) +
        " | Expedition=" + string(sim.coverage.exploration) +
        " | Social=" + string(sim.coverage.social) +
        " | Merchant=" + string(sim.coverage.merchant) +
        " | Relief=" + string(sim.coverage.relief) +
        " | Discovery=" + string(sim.coverage.discovery) +
        " | Hazard=" + string(sim.coverage.hazard)
    );
    sim_log(sim,
        "📊 Downed events=" + string(sim.stats.total_downed_count) +
        " | Tank downed=" + string(sim.stats.tank_downed_count) +
        " | Over-budget prevented=" + string(sim.stats.encounters_over_budget_prevented) +
        " | Encounter rerolls=" + string(sim.stats.rerolls_count) +
        " | Repeat prevented=" + string(sim.director.repeat_prevented) +
        " | Downed-loop interventions=" + string(sim.director.downed_loop_interventions)
    );

    if (is_array(sim.route_segments) && variable_struct_exists(sim, "zone_beat_counts") && is_struct(sim.zone_beat_counts)) {
        var zone_summary_keys = [];
        for (var zi = 0; zi < array_length(sim.route_segments); zi++) {
            var seg = sim.route_segments[zi];
            var zone_name = seg.zone;
            if (seg.zone == "Wilderness") zone_name = "Wilderness: " + seg.biome;
            else if (seg.zone == "Dungeon") zone_name = "Dungeon: " + seg.dungeon_type;

            if (array_contains(zone_summary_keys, zone_name)) continue;
            array_push(zone_summary_keys, zone_name);
        }

        for (var zk = 0; zk < array_length(zone_summary_keys); zk++) {
            var summary_zone_name = zone_summary_keys[zk];
            if (!variable_struct_exists(sim.zone_beat_counts, summary_zone_name)) continue;

            var zone_counts = variable_struct_get(sim.zone_beat_counts, summary_zone_name);
            var row_total = zone_counts.combat + zone_counts.exploration + zone_counts.social + zone_counts.hazard + zone_counts.merchant + zone_counts.relief;
            if (row_total <= 0) continue;

            sim_log(sim,
                "[DEBUG] Zone beat counts " + summary_zone_name +
                " | Combat=" + string(zone_counts.combat) +
                " | Exploration=" + string(zone_counts.exploration) +
                " | Social=" + string(zone_counts.social) +
                " | Hazard=" + string(zone_counts.hazard) +
                " | Merchant=" + string(zone_counts.merchant) +
                " | Relief=" + string(zone_counts.relief)
            );
        }
    }

    var encounter_outcome_total = sim.stats.encounter_accepted + sim.stats.encounter_scaled_down + sim.stats.encounter_degraded;
    sim_log(sim,
        "📊 Encounter budget: attempts=" + string(sim.stats.encounter_attempts) +
        " | accepted=" + string(sim.stats.encounter_accepted) +
        " | rerolled=" + string(sim.stats.encounter_rerolled) +
        " | scaled=" + string(sim.stats.encounter_scaled_down) +
        " | degraded=" + string(sim.stats.encounter_degraded) +
        " | bestfit=" + string(sim.stats.encounter_bestfit_selected) +
        " | outcomes_total=" + string(encounter_outcome_total)
    );

    var resolved_encounters = sim.stats.encounter_accepted + sim.stats.encounter_scaled_down;
    var ratio_avg = (resolved_encounters > 0) ? (sim.stats.encounter_ratio_sum / resolved_encounters) : 0;

    var enemy_counts = variable_struct_exists(sim.stats, "encounter_enemy_counts") && is_struct(sim.stats.encounter_enemy_counts)
        ? sim.stats.encounter_enemy_counts
        : {};
    var enemy_names = variable_struct_get_names(enemy_counts);

    var top_name_1 = "-"; var top_count_1 = 0;
    var top_name_2 = "-"; var top_count_2 = 0;
    var top_name_3 = "-"; var top_count_3 = 0;

    for (var en = 0; en < array_length(enemy_names); en++) {
        var en_name = enemy_names[en];
        var en_count = variable_struct_get(enemy_counts, en_name);

        if (en_count > top_count_1) {
            top_name_3 = top_name_2; top_count_3 = top_count_2;
            top_name_2 = top_name_1; top_count_2 = top_count_1;
            top_name_1 = en_name; top_count_1 = en_count;
        } else if (en_count > top_count_2) {
            top_name_3 = top_name_2; top_count_3 = top_count_2;
            top_name_2 = en_name; top_count_2 = en_count;
        } else if (en_count > top_count_3) {
            top_name_3 = en_name; top_count_3 = en_count;
        }
    }

    sim_log(sim,
        "[CALIB] combats=" + string(sim.stats.combats) +
        " accepted=" + string(sim.stats.encounter_accepted) +
        " scaled=" + string(sim.stats.encounter_scaled_down) +
        " degraded=" + string(sim.stats.encounter_degraded) +
        " bestfit=" + string(sim.stats.encounter_bestfit_selected)
    );
    sim_log(sim,
        "[CALIB] ratio avg=" + string_format(ratio_avg, 1, 2) +
        " min=" + string_format(sim.stats.encounter_ratio_min, 1, 2) +
        " max=" + string_format(sim.stats.encounter_ratio_max, 1, 2) +
        " group(1/2/3)=" + string(sim.stats.encounter_group_1) + "/" + string(sim.stats.encounter_group_2) + "/" + string(sim.stats.encounter_group_3)
    );
    sim_log(sim,
        "[CALIB] enemies top=" + top_name_1 + "(" + string(top_count_1) + "), " +
        top_name_2 + "(" + string(top_count_2) + "), " +
        top_name_3 + "(" + string(top_count_3) + ")"
    );

	  debug_log_flush();
	  
}
