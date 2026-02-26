function loot_pick_weighted(sim, entries) {
    // entries: array of structs like [{w: 60, v: "weapon"}, {w: 40, v: "armor"}]
    var total = 0;
    for (var i = 0; i < array_length(entries); i++) total += max(0, entries[i].w);

    if (total <= 0) {
        // fallback: just return first value if weights are busted
        return entries[0].v;
    }

    var r = sim_rand_range(sim, 1, total);
    var acc = 0;

    for (var i = 0; i < array_length(entries); i++) {
        acc += max(0, entries[i].w);
        if (r <= acc) return entries[i].v;
    }

    return entries[array_length(entries) - 1].v;
}
