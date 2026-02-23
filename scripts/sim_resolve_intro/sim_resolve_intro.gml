function sim_resolve_intro(sim) {
    if (!variable_struct_exists(sim, "flags") || !is_struct(sim.flags)) sim.flags = {};
    if (!variable_struct_exists(sim.flags, "complication_emitted")) sim.flags.complication_emitted = false;
    var intro_area = sim.zone;
    if (sim.zone == "Wilderness") intro_area = sim.overland_biome + " wilderness";
    else if (sim.zone == "Dungeon") intro_area = sim.dungeon_type;
    else if (sim.zone == "Town") intro_area = "town commons";
    sim_log(sim, "🧭 The party advances into the " + intro_area + ".");
    if (!variable_struct_exists(sim.flags, "hook_emitted") || !sim.flags.hook_emitted) {
        sim.flags.hook_emitted = true;
        sim_log(sim, "[EPISODE_HOOK] A rumor ties this route to a secret that could change the whole campaign.");
    }
}




