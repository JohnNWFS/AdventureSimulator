/// obj_sim_controller :: Step
// Controls
if (keyboard_check_pressed(vk_return)) {
    global.debug_seed += global.debug_seed_step;
    var run_target = global.debug_very_short_mode ? episode_beats_target_very_short : (global.debug_short_mode ? episode_beats_target_short : episode_beats_target);
    sim_run_new(sim, run_target, global.debug_seed);
}
if (keyboard_check_pressed(ord("R"))) {
    sim_run_restart_same_seed(sim);         // replay same seed
}
if (keyboard_check_pressed(ord("T"))) {
    global.debug_short_mode = !global.debug_short_mode;
    if (global.debug_short_mode) global.debug_very_short_mode = false;
    sim_log_tag(sim, "DEBUG_MODE", "🧪 Short run mode: " + string(global.debug_short_mode));
    var run_target = global.debug_very_short_mode ? episode_beats_target_very_short : (global.debug_short_mode ? episode_beats_target_short : episode_beats_target);
    sim_run_new(sim, run_target, global.debug_seed);
}
if (keyboard_check_pressed(ord("V"))) {
    global.debug_very_short_mode = !global.debug_very_short_mode;
    if (global.debug_very_short_mode) global.debug_short_mode = true;
    sim_log_tag(sim, "DEBUG_MODE", "⚡ Very short mode: " + string(global.debug_very_short_mode));
    var run_target = global.debug_very_short_mode ? episode_beats_target_very_short : (global.debug_short_mode ? episode_beats_target_short : episode_beats_target);
    sim_run_new(sim, run_target, global.debug_seed);
}
if (keyboard_check_pressed(ord("Q"))) {
    sim_run_multi_seed_short_test(sim, global.debug_seed, global.debug_multi_seed_count, episode_beats_target_short);
}
if (keyboard_check_pressed(vk_space)) {
    auto_run = !auto_run;
}
if (!auto_run && keyboard_check_pressed(ord("N"))) {
    beats_per_step = 1;
    sim_run_step(sim);
}

// Auto-run
if (auto_run && !sim.finished) {
    for (var i = 0; i < beats_per_step; i++) {
        if (sim.finished) break;
        sim_run_step(sim);
    }
}

// If finished, do nothing until rerun/new seed.
