// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function debug_handle_f7(){
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

function debug_handle_o(){
	global.debug_autosave = !global.debug_autosave;
    beat_output_emit("DEBUG", "Autosave-to-file: " + string(global.debug_autosave), undefined);
	
}


function debug_handle_r()
{
	beat_output_emit("DEBUG", "Rerun seed " + string(global.debug_seed), undefined);
    _debug_start_run();
}
