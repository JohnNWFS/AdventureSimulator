function _debug_start_run()
{
    global.debug_beats_emitted = 0;

    // Flush previous run's leftover lines
    debug_log_flush();

    // Clear run log text
    global.run_log_text = "";
    clipboard_set_text("");

    // Seed the RNG
    rng_seed_init(global.debug_seed);

    // Start ONE new log file (if autosave is on)
    if (global.debug_autosave) {
        debug_log_start_file(global.debug_seed);
    }

    beat_output_emit("DEBUG", "Run started. Seed=" + string(global.debug_seed), undefined);

    if (object_exists(obj_sim_controller)) {
        with (obj_sim_controller) {
            sim_run_new(sim, episode_beats_target, global.debug_seed);
        }
    }
}