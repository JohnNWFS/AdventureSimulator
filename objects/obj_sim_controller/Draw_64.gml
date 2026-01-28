/// obj_sim_controller :: Draw GUI
draw_set_font(-1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

var gui_x = 16;
var gui_y = 16;

// Header
var header =
    "Seed: " + string(sim.seed) +
    " | Beat: " + string(sim.beat) + "/" + string(sim.beats_target) +
    " | Zone: " + string(sim.zone) +
    " | Tension: " + string(sim.tension) +
    " | Gold: " + string(sim.gold_total) +
    (sim.finished ? " | FINISHED" : (auto_run ? " | RUNNING" : " | PAUSED"));

draw_text(gui_x, gui_y, header);
gui_y += 22;

// Party HUD (simple)
for (var i = 0; i < array_length(sim.party); i++) {
    var p = sim.party[i];
	var line = p.role + " " + p.name +
    "  HP " + string(p.hp) + "/" + string(p.max_hp) +
    "  MP " + string(p.mp) + "/" + string(p.max_mp) +
    "  ATK " + string(p.atk) + " DEF " + string(p.def) +
    "  Wounds " + string(p.wounds) +
    "  W:" + (p.weapon == "" ? "-" : p.weapon) +
    "  A:" + (p.armor == "" ? "-" : p.armor) +
    "  T:" + (p.trinket == "" ? "-" : p.trinket);

    draw_text(gui_x, gui_y, line);
    gui_y += 18;
}






y += 8;
draw_text(x, y, "Controls: ENTER=new seed | R=replay seed | SPACE=toggle run | N=step (when paused)");
y += 22;

// Log (last N lines)
var start = max(0, array_length(sim.log) - ui_max_lines);
for (var j = start; j < array_length(sim.log); j++) {
    draw_text(x, y, sim.log[j]);
    y += 16;
}
