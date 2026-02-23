if (!global.debug_enabled) exit;

var margin = 560;
var _x = margin;
var _y = margin;

var header =
    "DEBUG CONSOLE  |  Seed: " + string(global.debug_seed) +
    "  |  Short: " + string(global.debug_short_mode) +
    "  |  Beats: " + string(global.debug_beats_emitted) + "/" + string(global.debug_max_beats) +
    "\nKeys: R=rerun  N=next seed  S=toggle short  C=clear  V=copy run log  F7=randomize seed" +
    "\nF9=run debug find batch (searches debug_find_string across repeated seeded runs)  F10=macro runs";

draw_set_alpha(1);
draw_text(_x, _y, header);

_y += 48;

// Draw last lines
var lines = global.debug_lines;
var count = array_length(lines);

// How many lines fit? Keep it simple: fixed max visible
var max_visible = 24;
var start = max(0, count - max_visible);

for (var i = start; i < count; i++) {
    draw_text(_x, _y, lines[i]);
    _y += 16;
}
