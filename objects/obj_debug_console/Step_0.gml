// Simple key-edge detection
var k_r = keyboard_check(ord("R")); // rerun same seed
var k_n = keyboard_check(ord("N")); // next seed
var k_s = keyboard_check(ord("S")); // toggle short mode
var k_c = keyboard_check(ord("C")); // clear console
var k_v = keyboard_check(ord("V")); // copy run log
var k_o = keyboard_check(ord("O")); // toggle autosave-to-file
var k_hash = keyboard_check(vk_f7); // Randomize Seed (F7)


if (k_c && !key_prev_c) {
    global.debug_lines = [];
    global.debug_beats_emitted = 0;
    beat_output_emit("DEBUG", "Console cleared.", undefined);
}

if (k_hash && !key_prev_hash) {
    // Clear console/run buffers
    global.debug_lines = [];
    global.debug_beats_emitted = 0;
    if (!variable_global_exists("run_log_text")) global.run_log_text = "";
    global.run_log_text = ""; // clear clipboard buffer target too (your V copies this)

    // Pick new seed
    var new_seed = irandom_range(1, 99999);
    global.debug_seed = new_seed;

    // Emit + start run
    beat_output_emit("DEBUG", "Seed -> " + string(global.debug_seed), undefined);
    _debug_start_run();
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

if (k_v && !key_prev_v) {
    if (!variable_global_exists("run_log_text")) global.run_log_text = "";
    clipboard_set_text(global.run_log_text);
    beat_output_emit("DEBUG", "Copied run log to clipboard (" + string(string_length(global.run_log_text)) + " chars).", undefined);
}

if (k_o && !key_prev_o) {
    global.debug_autosave = !global.debug_autosave;
    beat_output_emit("DEBUG", "Autosave-to-file: " + string(global.debug_autosave), undefined);
}


key_prev_r = k_r;
key_prev_n = k_n;
key_prev_s = k_s;
key_prev_c = k_c;
key_prev_v = k_v;
key_prev_o = k_o;
key_prev_hash = k_hash;

