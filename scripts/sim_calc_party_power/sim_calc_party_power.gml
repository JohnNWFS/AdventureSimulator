function sim_calc_party_power(sim) {
    var party_power = 0;

    for (var i = 0; i < array_length(sim.party); i++) {
        var p = sim.party[i];
        if (p.dead || p.retired) continue;

        sim_recalc_derived(p);

        var hp_weight = floor(p.max_hp * 0.10);
        var atk_weight = floor(p.atk * 0.90);
        var def_weight = floor(p.def * 1.10);
        var mp_weight = ((p.role == "Mage") || (p.role == "Healer")) ? floor(p.max_mp * 0.08) : 0;

        var tier_bonus = 0;
        if (is_struct(p.equip)) {
            var ew = p.equip.weapon;
            var ea = p.equip.armor;
            var et = p.equip.trinket;
            if (!is_undefined(ew) && is_struct(ew) && variable_struct_exists(ew, "tier")) tier_bonus += floor(ew.tier * 0.6);
            if (!is_undefined(ea) && is_struct(ea) && variable_struct_exists(ea, "tier")) tier_bonus += floor(ea.tier * 0.6);
            if (!is_undefined(et) && is_struct(et) && variable_struct_exists(et, "tier")) tier_bonus += floor(et.tier * 0.5);
        }

        party_power += max(1, hp_weight + atk_weight + def_weight + mp_weight + tier_bonus);
    }

    return max(8, party_power);
}
