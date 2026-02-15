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
	
	  debug_log_flush();
	  
}
