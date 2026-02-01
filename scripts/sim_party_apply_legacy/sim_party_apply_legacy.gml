function sim_party_apply_legacy(sim, fallen, mode) {

    if (is_struct(sim.stats) && variable_struct_exists(sim.stats, "legacies")) {
        sim.stats.legacies += 1;
    }

    // Legacy reward is subtle: it nudges resolve up, which makes retirement less likely
    // and makes “survivors press on” feel consistent.
    var bump = (mode == "death") ? 12 : 8;

    for (var j = 0; j < array_length(sim.party); j++) {
        var p2 = sim.party[j];
        if (p2.dead || p2.retired) continue;
        p2.resolve = clamp(p2.resolve + bump, 0, 100);
    }

    sim_log_tag(sim, "LEGACY",
        "📜 Legacy of " + fallen.name + ": the party steels itself (resolve +" + string(bump) + ")."
    );
}
