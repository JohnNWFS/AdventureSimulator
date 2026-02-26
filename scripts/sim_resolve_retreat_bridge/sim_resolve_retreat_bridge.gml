function sim_resolve_retreat_bridge(sim) {
    var bridge = sim_rand_range(sim, 0, 2);

    switch (bridge) {
        case 0:
            sim_log_tag(sim, "RETREAT_DECISION", "🏳 The party votes to pull out before the next push turns fatal.");
            break;
        case 1:
            sim_log_tag(sim, "RETREAT_ROUTE", "🪜 They retrace marked passages while rear guards hold chokepoints.");
            if (sim_chance(sim, 40)) sim_apply_party_damage(sim, sim_rand_range(sim, 1, 3));
            break;
        default:
            sim_log_tag(sim, "GATE_VERDICT", "🚑 At the outer gate, a healer orders immediate treatment and city return.");
            break;
    }
}