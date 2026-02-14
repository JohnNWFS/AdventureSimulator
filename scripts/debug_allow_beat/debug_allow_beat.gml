/// @function debug_allow_beat()
/// @desc Returns whether beat-like output should currently be emitted.

function debug_allow_beat()
{
    if (!variable_global_exists("debug_enabled") || !global.debug_enabled) return false;

    if (!variable_global_exists("debug_short_mode")) return true;
    if (!global.debug_short_mode) return true;

    if (!variable_global_exists("debug_beats_emitted")) global.debug_beats_emitted = 0;
    if (!variable_global_exists("debug_max_beats")) return true;

    return (global.debug_beats_emitted < global.debug_max_beats);
}
