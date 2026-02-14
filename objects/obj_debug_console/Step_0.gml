// Simple key-edge detection
var k_r = keyboard_check(ord("R")); // rerun same seed
var k_n = keyboard_check(ord("N")); // next seed
var k_s = keyboard_check(ord("S")); // toggle short mode
var k_c = keyboard_check(ord("C")); // clear console

if (k_c && !key_prev_c) {
    global.debug_lines = [];
    global.debug_beats_emitted = 0;
    beat_output_emit("DEBUG", "Console cleared.", undefined);
}

if (k_s && !key_prev_s) {
    global.debug_short_mode = !global.debug_short_mode;
    beat_output_emit("DEBUG", "Short mode: " + string(global.debug_short_mode), undefined);
}

if (k_n && !key_prev_n) {
    global.debug_seed += global.debug_seed_step;
    beat_output_emit("DEBUG", "Seed -> " + string(global.debug_seed), undefined);
    // Trigger a rerun with the new seed
    _debug_start_run();
}

if (k_r && !key_prev_r) {
    beat_output_emit("DEBUG", "Rerun seed " + string(global.debug_seed), undefined);
    _debug_start_run();
}

key_prev_r = k_r;
key_prev_n = k_n;
key_prev_s = k_s;
key_prev_c = k_c;

// Local function: start a deterministic run
function _debug_start_run()
{
    // Reset counters
    global.debug_beats_emitted = 0;

    // Set RNG seed deterministically
    rng_seed_init(global.debug_seed);

    // OPTIONAL: call into your sim controller if it exists.
    // You will need to adapt ONE line below to your project.
    //
    // If you have an object that starts an episode, call it here.
    // Example patterns:
    // with (obj_sim_controller) sim_start_episode();
    // or global.sim_request_restart = true;
    //
    // For now, we just emit a line so you can wire the hook later:
    beat_output_emit("DEBUG", "Run started. Seed=" + string(global.debug_seed), undefined);

    if (object_exists(obj_sim_controller)) {
        with (obj_sim_controller) {
            sim_run_new(sim, episode_beats_target, global.debug_seed);
        }
    }
}
