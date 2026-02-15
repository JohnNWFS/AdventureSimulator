function _zero_pad(val, digits) {
    var s = string(floor(val));
    while (string_length(s) < digits) s = "0" + s;
    return s;
}