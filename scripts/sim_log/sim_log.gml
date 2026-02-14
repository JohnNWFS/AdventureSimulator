function sim_log(sim, text) {
    // Keep in-memory
    array_push(sim.log, text);

    if (variable_global_exists("debug_enabled") && global.debug_enabled) {
        if (!variable_global_exists("run_log_text")) global.run_log_text = "";
        if (global.run_log_text == "") global.run_log_text = text;
        else global.run_log_text += "\n" + text;
    }

    // Also dump to Output console for sharing back
    show_debug_message(text);
}
