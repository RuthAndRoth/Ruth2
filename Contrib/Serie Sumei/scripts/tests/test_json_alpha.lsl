// test_json_alpha.lsl - Test json_get_alpha() and json_set_alpha() functions
// v1 - Create tests

/*

The json_get_alpha() and json_set_alpha() functions are used to handle the
alpha state stored as JSON strings in the Ruth2/Roth2 HUD scripts.

* The state of the alpha selections is stored as a JSON string internally.
  The JSON structure is a single object that uses the prim names as keys
  and a bit-mapped integer as the value.
* The state of each face is stored as a single bit in each prim's value
  with the face number determining the bit position. ie, face 0 is bit 0
  (the lowest-order bit in the integer), etc. LSL integers are 32 bit but
  due to weirdness with signed integers these values are masked to only use
  the low 16 bits. Mesh objects are limited to 8 faces so typically we
  will only use the low 8 bits but the manipulation functions support 16.
* The script uses 1 or 1.0 to represent 'visible', corresponding to the
  alpha value that LSL functions use, and 0 or 0.0 for transparent. Since
  we alpha body parts fully in either direction only integers are actually
  used.
* The JSON blob stores the alpha state exactly the opposite of this, ie a
  1 bit represents an invisible face. This allows the storage of faces to
  not be dependent on the number of bits in use. For example, saving a prim
  with faces 0 and 2 transparent would be the value 0101 in binary or 5 in
  decimal and hex. Storing this to match the alpha values would make the
  stored value 1010 in binary or 10 decimal or 0x0a in hex. But only if 4
  bits are used. As an 8 bit value it would be 11111010 (binary), 250
  (decimal) or 0xfa in hex. This would require us to also keep track of
  the number of bits. The translation between these two states is completely
  encapsulated in the json_get_alpha() and json_set_alpha() functions and
  should not be of concern to script writers.

This storage method for alpha state allows us to keep an arbitrary number
of saved states in a list where each set is a single JSON string. These
strings are human-readable, and could even be put into notecards or easily
passed between scripts as required.

*/



integer VERBOSE = TRUE;

log(string msg) {
    if (VERBOSE == 1) {
        llOwnerSay(msg);
    }
}

// *****
// Test bits

integer failures;
integer total;

integer test_integer(integer actual, integer expected, string desc) {
    total++;
    string str = "OK";
    if (actual != expected) {
        str = "not OK: " + (string)actual + " == " + (string)expected;
        failures++;
    }
    log(desc + ": " + str);
    return (actual == expected);
}

integer test_string(string actual, string expected, string desc) {
    total++;
    string str = "OK";
    if (actual != expected) {
        str = "not OK: " + actual + " == " + expected;
        failures++;
    }
    log(desc + ": " + str);
    return (actual == expected);
}
// *****

// hex() functions from http://wiki.secondlife.com/wiki/Efficient_Hex

// Clever and Small (alt)

string hex(integer value) {
    return hex16(value);
}

// 16 bit unsigned
string hex16(integer value) {
    string nybbles = "";
    do {
        integer lsn = value & 0xF; // least significant nybble
        nybbles = llGetSubString("0123456789abcdef", lsn, lsn) + nybbles;
    } while ((value = (0xfff & (value >> 4))));

    return "0x" + nybbles;
}

// 32 bit unsigned
string hex32(integer value) {
    string nybbles = "";
    do {
        integer lsn = value & 0xF; // least significant nybble
        nybbles = llGetSubString("0123456789abcdef", lsn, lsn) + nybbles;
    } while ((value = (0xfffFFFF & (value >> 4))));

    return "0x" + nybbles;
}
// *****

// *****
// get/set alpha values in JSON buffer

// j - JSON value storage
// name - prim_name
// face - integer face, -1 returns the unmasked 16 bit value
// Internal JSON values are ones complement, ie a 1 bit means the face is not visible
integer json_get_alpha(string j, string name, integer face) {
    integer cur_val = (integer)llJsonGetValue(j, [name]);
    if (face < 0) {
        // All faces, return aggregate value masked to 16 bits
        cur_val = ~cur_val & 0xffff;
    } else {
        cur_val = (cur_val & (1 << face)) == 0;
    }
    return cur_val;
}

// j - JSON value storage
// name - prim_name
// face - integer face, -1 sets all 16 bits in the value
// value - alpha boolean, 0 = invisible, 1 = visible
// Internal JSON values are ones complement, ie a 1 bit means the face is not visible
string json_set_alpha(string j, string name, integer face, integer value) {
    value = !value;  // logical NOT for internal storage
    integer cur_val = (integer)llJsonGetValue(j, [name]);
    integer mask;
    integer cmd;
    if (face < 0) {
        // All faces
        mask = 0x0000;
        // One's complement
        cmd = -value;
    } else {
        mask = ~(1 << face);
        cmd = (value << face);
    }
    // Mask final value to 16 bits
    cur_val = ((cur_val & mask) | cmd) & 0xffff;
    return llJsonSetValue(j, [name], (string)(cur_val));
}
// *****

default {
    state_entry() {
        log("state_entry()");
        string j = "{\"body\": 1, \"fingernails\": 0}";

        // Identity Tests
        log("\nIdentity Tests:");
        log("All on");
        j = "{\"body\": 0}";
        test_integer(json_get_alpha(j, "body", -1), 0xffff, "body -1");
        test_integer(json_get_alpha(j, "body", 0), 1, "body 0");
        test_integer(json_get_alpha(j, "body", 1), 1, "body 1");
        test_integer(json_get_alpha(j, "body", 7), 1, "body 7");

        log("All off");
        j = "{\"body\": 255}";
        test_integer(json_get_alpha(j, "body", -1), 0xff00, "body -1");
        test_integer(json_get_alpha(j, "body", 0), 0, "body 0");
        test_integer(json_get_alpha(j, "body", 1), 0, "body 1");
        test_integer(json_get_alpha(j, "body", 7), 0, "body 7");

        log("face 1 off");
        j = "{\"body\": 2}";
        test_integer(json_get_alpha(j, "body", -1), 0xfffd, "body -1");
        test_integer(json_get_alpha(j, "body", 0), 1, "body 0");
        test_integer(json_get_alpha(j, "body", 1), 0, "body 1");
        test_integer(json_get_alpha(j, "body", 7), 1, "body 7");

        log("\nset tests");
        j = "{\"body\": 0}";
        j = json_set_alpha(j, "body", -1, 0);
        test_integer(json_get_alpha(j, "body", -1), 0, "body -1 0");
        j = json_set_alpha(j, "body", -1, 1);
        test_integer(json_get_alpha(j, "body", -1), 0xffff, "body -1 1");
        j = json_set_alpha(j, "body", 0, 0);
        test_integer(json_get_alpha(j, "body", 0), 0, "body 0 0");
        test_integer(json_get_alpha(j, "body", 1), 1, "body 1 1");
        j = json_set_alpha(j, "body", 0, 1);
        test_integer(json_get_alpha(j, "body", 0), 1, "body 0 1");
        test_integer(json_get_alpha(j, "body", 1), 1, "body 1 1");

        log("\nnew value tests");
        j = "{}";
        test_integer(json_get_alpha(j, "body", -1), 0xffff, "body -1 0");
        test_integer(json_get_alpha(j, "body", 5), 1, "body 5 1");
        j = "{}";
        j = json_set_alpha(j, "body", -1, 0);
        test_integer(json_get_alpha(j, "body", -1), 0, "body -1 0");
        j = "{}";
        j = json_set_alpha(j, "body", 5, 0);
        test_integer(json_get_alpha(j, "body", 5), 0, "body 5 0");

        log("Failures: " + (string)failures);
        log("Total: " + (string)total);
    }
}
