function sim_format_budget_line(party_power, encounter_threat, cap_used, tag, result_tag) {
    var safe_party = max(1, party_power);
    var ratio = encounter_threat / safe_party;
    var line =
        "[ENCOUNTER_BUDGET] party=" + string(party_power) +
        " threat=" + string(encounter_threat) +
        " ratio=" + string_format(ratio, 1, 2) +
        " cap=" + string_format(cap_used, 1, 2) +
        " tag=" + tag +
        " result=" + result_tag;
    return line;
}

