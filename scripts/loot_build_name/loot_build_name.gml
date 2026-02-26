function loot_build_name(prefix, material, base, suffix) {
    var name = "";

    if (prefix != "") name += prefix + " ";
    if (material != "") name += material + " ";
    name += base;
    if (suffix != "") name += " " + suffix;

    // Clean double spaces just in case
    name = string_replace(name, "  ", " ");
    name = string_replace(name, "  ", " ");
    return name;
}
