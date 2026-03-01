// Simple key-edge detection
var k_r = keyboard_check(ord("R")); // rerun same seed
var k_n = keyboard_check(ord("N")); // next seed
var k_s = keyboard_check(ord("S")); // toggle short mode
var k_c = keyboard_check(ord("C")); // clear console
var k_v = keyboard_check(ord("V")); // copy run log
var k_o = keyboard_check(ord("O")); // toggle autosave-to-file
var k_hash = keyboard_check(vk_f7); // Randomize Seed (F7)
var k_f8 = keyboard_check(vk_f8); // toggle very short mode (F8)


if (keyboard_check_pressed(vk_f2)) {
    global.tuner_active = !global.tuner_active;
    if (global.tuner_active) {
        global.tuner_session = {
            episodes: 0,
            sum_combats: 0,
            sum_chests: 0,
            sum_merchants: 0,
            sum_rares: 0,
            sum_retirements: 0,
            sum_deaths: 0,
            sum_gold: 0,
            boss_defeated_count: 0
        };
        beat_output_emit("DEBUG", "Fine Tuner overlay: ON (session reset)", undefined);
    } else {
        beat_output_emit("DEBUG", "Fine Tuner overlay: OFF", undefined);
    }
}

if (global.tuner_active && is_array(tuner_sliders) && array_length(tuner_sliders) > 0) {
    if (keyboard_check_pressed(vk_up)) {
        slider_index = max(0, slider_index - 1);
    }
    if (keyboard_check_pressed(vk_down)) {
        slider_index = min(array_length(tuner_sliders) - 1, slider_index + 1);
    }

    var shift_down = keyboard_check(vk_shift);
    var step_dir = 0;
    if (keyboard_check_pressed(vk_left)) step_dir = -1;
    if (keyboard_check_pressed(vk_right)) step_dir = 1;

    if (step_dir != 0) {
        var row = tuner_sliders[slider_index];
        var current = variable_struct_get(global.tuning, row.key);
        var step_amt = shift_down ? row.big_step : row.step;
        var next_val = clamp(current + (step_amt * step_dir), row.min, row.max);
        if (row.decimals <= 0) next_val = floor(next_val + 0.0001);
        else {
            var snap = power(10, row.decimals);
            next_val = round(next_val * snap) / snap;
        }
        variable_struct_set(global.tuning, row.key, next_val);
    }

    if (mouse_check_button_pressed(mb_left)) {
        var mx = device_mouse_x_to_gui(0);
        var my = device_mouse_y_to_gui(0);

        var ox = 20;
        var oy = 80;
        var row_y = oy + 36;
        var btn_x = ox + 12;
        var btn_w = 20;
        var btn_h = 16;

        for (var bi = 0; bi < array_length(tuner_sliders); bi++) {
            if (mx >= btn_x && mx <= btn_x + btn_w && my >= row_y && my <= row_y + btn_h) {
                var help_key = tuner_sliders[bi].key;
                if (tuner_selected_help_key == help_key) tuner_selected_help_key = "";
                else tuner_selected_help_key = help_key;
                break;
            }
            row_y += 24;
        }
    }
}


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
    if (!global.debug_short_mode) global.debug_very_short_mode = false;
    beat_output_emit("DEBUG", "Short mode: " + string(global.debug_short_mode) + " | Very short: " + string(global.debug_very_short_mode), undefined);
    _debug_start_run();
}

if (k_f8 && !key_prev_f8) {
    global.debug_very_short_mode = !global.debug_very_short_mode;
    if (global.debug_very_short_mode) global.debug_short_mode = true;
    beat_output_emit("DEBUG", "Very short mode: " + string(global.debug_very_short_mode) + " | Short: " + string(global.debug_short_mode), undefined);
    _debug_start_run();
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
key_prev_f8 = k_f8;
