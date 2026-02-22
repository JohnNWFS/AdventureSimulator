function sim_resolve_intro(sim) {
    if (!variable_struct_exists(sim, "flags") || !is_struct(sim.flags)) sim.flags = {};
    if (!variable_struct_exists(sim.flags, "complication_emitted")) sim.flags.complication_emitted = false;
    sim_log(sim, "🧭 The party advances into the " + sim.zone + ".");
    if (!variable_struct_exists(sim.flags, "hook_emitted") || !sim.flags.hook_emitted) {
        sim.flags.hook_emitted = true;
        sim_log(sim, "[EPISODE_HOOK] A rumor ties this route to a secret that could change the whole campaign.");
    }
}




