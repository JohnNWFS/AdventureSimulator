/// obj_sim_controller :: Step
// Controls
if (keyboard_check_pressed(vk_return)) {
    sim_run_new(sim, episode_beats_target); // new seed
}
if (keyboard_check_pressed(ord("R"))) {
    sim_run_restart_same_seed(sim);         // replay same seed
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
