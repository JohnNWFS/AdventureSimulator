if (!macro_active) exit;

// If we’re waiting on a long run, poll completion here
if (macro_waiting_run) {

    var finished = false;

    // Try to detect completion via your sim controller (preferred)
    if (object_exists(obj_sim_controller)) {
        with (obj_sim_controller) {
            if (is_struct(sim) && variable_struct_exists(sim, "finished")) {
                finished = sim.finished;
            }
        }
    }

    // If we can't detect finished, or as a safety net, use timeout
    if (!finished) {
        if (current_time >= macro_wait_deadline_ms) {
            beat_output_emit("DEBUG", "Macro: run wait timed out, proceeding anyway.", undefined);
            finished = true;
        }
    }

    if (!finished) {
        // Not done yet; check again shortly
        alarm[0] = 1;
        exit;
    }

    // Run is done (or timed out): proceed to the "close file" step
    macro_waiting_run = false;
    macro_step = 3;
    alarm[0] = 1;
    exit;
}

switch (macro_step) {

    case 0:
        if (global.debug_batch_mode == "find") {
            var find_seed = global.debug_find_seed_start + global.debug_find_index * global.debug_find_seed_step;
            global.debug_seed = find_seed;

            global.debug_lines = [];
            global.debug_beats_emitted = 0;
            if (!variable_global_exists("run_log_text")) global.run_log_text = "";
            global.run_log_text = "";

            beat_output_emit("DEBUG", "[DEBUG_FIND] Seed -> " + string(global.debug_seed) + " (" + string(global.debug_find_index + 1) + "/" + string(global.debug_find_repeats) + ")", undefined);
        } else {
            // F7
            beat_output_emit("DEBUG", "Macro " + string(macro_runs_done+1) + "/" + string(macro_runs_target) + ": F7", undefined);
            debug_handle_f7();
        }

        macro_step = 1;
        alarm[0] = 1;
        break;

    case 1:
        // O (open)
        if (global.debug_batch_mode == "find") {
            beat_output_emit("DEBUG", "[DEBUG_FIND] " + string(global.debug_find_index + 1) + "/" + string(global.debug_find_repeats) + ": O (open)", undefined);
        } else {
            beat_output_emit("DEBUG", "Macro " + string(macro_runs_done+1) + "/" + string(macro_runs_target) + ": O (open)", undefined);
        }
        debug_handle_o();
        macro_step = 2;
        alarm[0] = 1;
        break;

    case 2:
        // R (run) then WAIT
        if (global.debug_batch_mode == "find") {
            beat_output_emit("DEBUG", "[DEBUG_FIND] " + string(global.debug_find_index + 1) + "/" + string(global.debug_find_repeats) + ": R (run)", undefined);
        } else {
            beat_output_emit("DEBUG", "Macro " + string(macro_runs_done+1) + "/" + string(macro_runs_target) + ": R (run)", undefined);
        }
        debug_handle_r();

        macro_waiting_run = true;
        macro_wait_deadline_ms = current_time + macro_wait_timeout_ms;

        // do NOT advance macro_step here; wait block above will move us to step 3
        alarm[0] = 1;
        break;

    case 3:
        // O (close)
        if (global.debug_batch_mode == "find") {
            beat_output_emit("DEBUG", "[DEBUG_FIND] " + string(global.debug_find_index + 1) + "/" + string(global.debug_find_repeats) + ": O (close)", undefined);
        } else {
            beat_output_emit("DEBUG", "Macro " + string(macro_runs_done+1) + "/" + string(macro_runs_target) + ": O (close)", undefined);
        }
        debug_handle_o();

        if (global.debug_batch_mode == "find") {
            var run_seed = global.debug_find_seed_start + global.debug_find_index * global.debug_find_seed_step;
            var found = false;
            var match_line = "";

            if (!variable_global_exists("run_log_text")) global.run_log_text = "";
            if (string_pos(global.debug_find_string, global.run_log_text) > 0) {
                found = true;
                var lines = string_split(global.run_log_text, "\n");
                var lines_len = array_length(lines);
                for (var li = 0; li < lines_len; li++) {
                    if (string_pos(global.debug_find_string, lines[li]) > 0) {
                        match_line = lines[li];
                        break;
                    }
                }
            }

            if (found) {
                global.debug_find_hits += 1;
                var hit_line = "HIT seed=" + string(run_seed) + " run=" + string(global.debug_find_index + 1) + " match='" + global.debug_find_string + "'";
                if (match_line != "") hit_line += " line='" + match_line + "'";
                array_push(global.debug_find_results, hit_line);
            }

            global.debug_find_index += 1;
            macro_runs_done += 1;

            var done_find = (global.debug_find_index >= global.debug_find_repeats);
            if (global.debug_find_stop_on_first && global.debug_find_hits > 0) done_find = true;

            if (done_find) {
                var dir = "logs";
                if (!directory_exists(dir)) directory_create(dir);

                var out_path = global.debug_find_results_filename;
                if (out_path == "") {
                    var now2 = date_current_datetime();
                    var ts2 =
                        string(date_get_year(now2)) +
                        _zero_pad(date_get_month(now2), 2) +
                        _zero_pad(date_get_day(now2), 2) + "_" +
                        _zero_pad(date_get_hour(now2), 2) +
                        _zero_pad(date_get_minute(now2), 2) +
                        _zero_pad(date_get_second(now2), 2);
                    out_path = "logs/find_" + ts2 + "_seed" + string(global.debug_find_seed_start) + "_n" + string(global.debug_find_repeats) + "_token.txt";
                    global.debug_find_results_filename = out_path;
                }

                var ff = file_text_open_write(out_path);
                file_text_write_string(ff, "Find string: " + global.debug_find_string + "\n");
                file_text_write_string(ff, "Repeats: " + string(global.debug_find_repeats) + "\n");
                file_text_write_string(ff, "Seed start: " + string(global.debug_find_seed_start) + "\n");
                file_text_write_string(ff, "Seed step: " + string(global.debug_find_seed_step) + "\n");
                file_text_write_string(ff, "Hits: " + string(global.debug_find_hits) + "\n");
                file_text_write_string(ff, "\n");

                var result_len = array_length(global.debug_find_results);
                for (var ri = 0; ri < result_len; ri++) {
                    file_text_write_string(ff, global.debug_find_results[ri] + "\n");
                }
                file_text_close(ff);

                global.debug_find_active = false;
                macro_active = false;
                beat_output_emit("DEBUG", "[DEBUG_FIND] Done: hits=" + string(global.debug_find_hits) + " / " + string(global.debug_find_repeats) + " file=" + global.debug_find_results_filename, undefined);
                alarm[0] = -1;
            } else {
                macro_step = 0;
                alarm[0] = 1;
            }
        } else {
            macro_runs_done += 1;

            if (macro_runs_done >= macro_runs_target) {
                macro_active = false;
                beat_output_emit("DEBUG", "Macro complete: " + string(macro_runs_done) + " runs", undefined);
                alarm[0] = -1;
            } else {
                macro_step = 0;
                alarm[0] = 1;
            }
        }
        break;
}
