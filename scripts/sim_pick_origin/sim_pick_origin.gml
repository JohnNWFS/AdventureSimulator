function sim_pick_origin(sim) {
    var origins = [
        "Dockside", "Temple-run", "Caravan-born", "Ruins scholar",
        "Ex-militia", "Sewer-raised", "Highroad drifter", "Old garrison"
    ];
    return origins[sim_rand_range(sim, 0, array_length(origins) - 1)];
}
