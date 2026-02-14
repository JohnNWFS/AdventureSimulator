/// obj_sim_controller :: Step
// Controls
if (keyboard_check_pressed(vk_return)) {
    global.debug_seed += global.debug_seed_step;
    sim_run_new(sim, global.debug_short_mode ? episode_beats_target_short : episode_beats_target, global.debug_seed);
}
if (keyboard_check_pressed(ord("R"))) {
    sim_run_restart_same_seed(sim);         // replay same seed
}
if (keyboard_check_pressed(ord("T"))) {
    global.debug_short_mode = !global.debug_short_mode;
    sim_log_tag(sim, "DEBUG_MODE", "🧪 Short run mode: " + string(global.debug_short_mode));
    sim_run_new(sim, global.debug_short_mode ? episode_beats_target_short : episode_beats_target, global.debug_seed);
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
