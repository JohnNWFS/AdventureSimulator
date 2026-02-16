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
        // F7
        beat_output_emit("DEBUG", "Macro " + string(macro_runs_done+1) + "/" + string(macro_runs_target) + ": F7", undefined);
        debug_handle_f7();
        macro_step = 1;
        alarm[0] = 1;
        break;

    case 1:
        // O (open)
        beat_output_emit("DEBUG", "Macro " + string(macro_runs_done+1) + "/" + string(macro_runs_target) + ": O (open)", undefined);
        debug_handle_o();
        macro_step = 2;
        alarm[0] = 1;
        break;

    case 2:
        // R (run) then WAIT
        beat_output_emit("DEBUG", "Macro " + string(macro_runs_done+1) + "/" + string(macro_runs_target) + ": R (run)", undefined);
        debug_handle_r();

        macro_waiting_run = true;
        macro_wait_deadline_ms = current_time + macro_wait_timeout_ms;

        // do NOT advance macro_step here; wait block above will move us to step 3
        alarm[0] = 1;
        break;

    case 3:
        // O (close)
        beat_output_emit("DEBUG", "Macro " + string(macro_runs_done+1) + "/" + string(macro_runs_target) + ": O (close)", undefined);
        debug_handle_o();

        macro_runs_done += 1;

        if (macro_runs_done >= macro_runs_target) {
            macro_active = false;
            beat_output_emit("DEBUG", "Macro complete: " + string(macro_runs_done) + " runs", undefined);
            alarm[0] = -1;
        } else {
            macro_step = 0;
            alarm[0] = 1;
        }
        break;
}