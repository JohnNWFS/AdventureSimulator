function sim_run_finalize(sim) {
    if (sim.finished && sim.beat >= sim.beats_target) return;

    sim.finished = true;

    if (!sim.city_scene_played || sim_party_any_dead(sim)) {
        sim.city_scene_pending = true;
        sim_resolve_city_scene(sim);
    }

    // Score quick summary
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
        "📊 Downed events=" + string(sim.stats.downed_events) +
        " | Repeat prevented=" + string(sim.director.repeat_prevented) +
        " | Downed-loop interventions=" + string(sim.director.downed_loop_interventions)
    );
}
