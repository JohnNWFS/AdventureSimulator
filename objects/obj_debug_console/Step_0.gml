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

if (keyboard_check_pressed(vk_f9)) {
    if (global.debug_find_enabled && !macro_active) {
        global.debug_batch_mode = "find";
        macro_active = true;
        macro_step = 0;
        macro_runs_done = 0;

        macro_waiting_run = false;
        macro_wait_deadline_ms = 0;

        global.debug_find_active = true;
        global.debug_find_index = 0;
        global.debug_find_hits = 0;
        global.debug_find_results = [];

        var raw_token = global.debug_find_string;
        var safe_token = "";
        var token_len = string_length(raw_token);
        for (var ti = 1; ti <= token_len; ti++) {
            var ch = string_char_at(raw_token, ti);
            var ok = false;
            if (ch >= "a" && ch <= "z") ok = true;
            if (ch >= "A" && ch <= "Z") ok = true;
            if (ch >= "0" && ch <= "9") ok = true;
            if (ok) safe_token += ch; else safe_token += "_";
        }
        if (string_length(safe_token) > 24) safe_token = string_copy(safe_token, 1, 24);
        if (safe_token == "") safe_token = "token";

        var now = date_current_datetime();
        var ts =
            string(date_get_year(now)) +
            _zero_pad(date_get_month(now), 2) +
            _zero_pad(date_get_day(now), 2) + "_" +
            _zero_pad(date_get_hour(now), 2) +
            _zero_pad(date_get_minute(now), 2) +
            _zero_pad(date_get_second(now), 2);

        global.debug_find_results_filename =
            "logs/find_" + ts +
            "_seed" + string(global.debug_find_seed_start) +
            "_n" + string(global.debug_find_repeats) +
            "_" + safe_token + ".txt";

        alarm[0] = 1;
        beat_output_emit("DEBUG", "[DEBUG_FIND] Starting find batch: string='" + global.debug_find_string + "' repeats=" + string(global.debug_find_repeats) + " seed_start=" + string(global.debug_find_seed_start) + " step=" + string(global.debug_find_seed_step), undefined);
    }
}

if (keyboard_check_pressed(vk_f11)) {
    global.debug_output_enabled = !global.debug_output_enabled;
    if (!global.debug_output_enabled) {
        global.debug_lines = [];
    }
    beat_output_emit("DEBUG", "Debug output: " + string(global.debug_output_enabled) + " (beats remain ON)", undefined);
}

if (keyboard_check_pressed(vk_f10)) {
    global.debug_batch_mode = "runs";
    macro_active = true;
    macro_step = 0;
    macro_runs_done = 0;

    macro_waiting_run = false;
    macro_wait_deadline_ms = 0;

    alarm[0] = 1;
    beat_output_emit("DEBUG", "Macro start: " + string(macro_runs_target) + " runs", undefined);
}


key_prev_r = k_r;
key_prev_n = k_n;
key_prev_s = k_s;
key_prev_c = k_c;
key_prev_v = k_v;
key_prev_o = k_o;
key_prev_hash = k_hash;
