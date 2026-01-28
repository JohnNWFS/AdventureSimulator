/// obj_sim_controller :: Create
episode_beats_target = 120; // 120 beats ≈ 10 minutes if you later map 1 beat ≈ 5 sec
auto_run = true;
beats_per_step = 1;         // crank this up to 5/10 for turbo simulation
ui_max_lines = 26;

sim = {};                   // will hold run state + party
sim_run_new(sim, episode_beats_target); // new seed, new run
