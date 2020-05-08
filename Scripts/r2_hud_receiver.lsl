// r2_hud_receiver.lsl - Ruth2 v3 HUD Receiver
// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright 2017 Shin Ingen
// Copyright 2019 Serie Sumei

// v3.0 02Apr2020 <seriesumei@avimail.org> - Based on ss-v5 from Controb/Serie Sumei
// v3.1 04Apr2020 <seriesumei@avimail.org> - Add alphamode and elements to v2 API
// v3.2 01May2020 <seriesumei@avimail.org> - Use notecard element map for skins, alpha
// v3.3 07May2020 <seriesumei@avimail.org> - Re-enable default hand animation

// This is a heavily modified version of Shin's RC3 receiver scripts for
// head, body, hands and feet combined into one.
//
// It has some requirements of the hands and feet mesh similar to that already
// on the body with regard to linking and prim naming.  Link order does not
// matter, everything works based on the prim name and description fields.

// The body part is identified by looking for specific names in the linkset
// during the initial scan: "chest" (for the body), "feet", "hands", "head".
// This implies that the hands and feet need to be linked to a root prim in
// order for the actual mesh parts to have the right name.  The body already
// has this requirement so we can use the same root prim cube here too.

// The commands have been expanded a bit to allow more flexibility in texturing
// the parts.  It is still totally compatible with the RC2 and RC3 commands
// provided the APP_ID is correct (we will handle that soon too).

// The app ID is used on calculating the actual channel number used for communication
// and must match in both the HUD and receivers.
integer APP_ID = 20181024;
integer APP_ID_ALT1 = 20171105;

integer MULTI_LISTEN = TRUE;

// Which API version do we implement?
integer API_VERSION = 2;

// Enumerate the body region types as of Bakes on Mesh
// We added our fingernail and toenail types at the end
// The index of this list is the value of <body-region> in the element_map

list regions = [
    "HEAD",
    "UPPER",
    "LOWER",
    "EYES",
    "SKIRT",
    "HAIR",
    "LEFTARM",
    "LEFTLEG",
    "AUX1",
    "AUX2",
    "AUX3",
    "FINGERNAILS",
    "TOENAILS"
];

// Any linkset that includes a part named "hands" will run the
// default hand pose
integer has_hands = FALSE;
string hand_animation = "bentohandrelaxedP1";
// Refresh hand animation wait, in seconds
float hand_refresh = 30.0;

// Map prim name and descriptions to link numbers
list prim_map = [];
list prim_desc = [];

integer element_stride = 4;
list element_map = [];
list section_map = [];

// Spew some info
integer VERBOSE = FALSE;

// Memory limit
integer MEM_LIMIT = 48000;

// The name of the XTEA script
string XTEA_NAME = "r2_xtea";

// Set to encrypt 'message' and re-send on channel 'id'
integer XTEAENCRYPT = 13475896;

// Set in the reply to a received XTEAENCRYPT if the passed channel is 0 or ""
integer XTEAENCRYPTED = 8303877;

// Set to decrypt 'message' and reply vi llMessageLinked()
integer XTEADECRYPT = 4690862;

// Set in the reply to a received XTEADECRYPT
integer XTEADECRYPTED = 3450924;

integer haz_xtea = FALSE;

// ***
// Notecard
string DEFAULT_NOTECARD = "!R2 CONFIG";
string notecard_name;
key notecard_qid;
integer line;
string current_section;
string current_buffer;
integer reading_notecard = FALSE;
//***

// save the listen handles
integer listen_main;
integer listen_alt1;
integer r2channel;
integer r2channel_alt1;
integer last_attach = 0;

log(string msg) {
    if (VERBOSE == 1) {
        llOwnerSay(msg);
    }
}

// See if the notecard is present in object inventory
integer can_haz_notecard(string name) {
    integer count = llGetInventoryNumber(INVENTORY_NOTECARD);
    while (count--) {
        if (llGetInventoryName(INVENTORY_NOTECARD, count) == name) {
            log("Found notecard: " + name);
            return TRUE;
        }
    }
    llOwnerSay("Notecard " + name + " not found");
    return FALSE;
}

integer can_haz_xtea() {
    // See if the XTEA script is present in object inventory
    integer count = llGetInventoryNumber(INVENTORY_SCRIPT);
    while (count--) {
        if (llGetInventoryName(INVENTORY_SCRIPT, count) == XTEA_NAME) {
            llOwnerSay("Found XTEA script");
            return TRUE;
        }
    }
    return FALSE;
}

send(string msg) {
    llSay(r2channel+1, msg);
    if (VERBOSE == 1) {
        llOwnerSay("S: " + msg);
    }
}

// Send the list of command args as CSV, breaking up into chunks if the
// length exceeds 1000 chars.  Chunked messages have a '+' char prepended
// to the comamnd word (first word in the list) for all but the last chunk.
send_csv(list msg) {
    string strmsg = llList2CSV(msg);
    if (llStringLength(strmsg) > 1000) {
        // break it up
        string cmd = llList2String(msg, 0);
        strmsg = llList2CSV(llList2List(msg, 1, -1));
        do {
            // Send a chunk with a marker on the command
            // Make the chunk a bit smaller than above to allow for command overhead
            send("+" + cmd + "," + llGetSubString(strmsg, 0, 990));
            strmsg = llGetSubString(strmsg, 991, -1);
        } while (llStringLength(strmsg) > 990);
        // Send the remaining bit without the marker so the receiver knows this is the end
        send(cmd + "," + strmsg);
    } else {
        send(strmsg);
    }
}

// Calculate a channel number based on APP_ID and owner UUID
integer keyapp2chan(integer id) {
    return 0x80000000 | ((integer)("0x" + (string)llGetOwner()) ^ id);
}

map_linkset() {
    // Create map of all links to prim names
    integer i = 0;
    integer num_links = llGetNumberOfPrims() + 1;
    for (; i < num_links; ++i) {
        list p = llGetLinkPrimitiveParams(i, [PRIM_NAME, PRIM_DESC]);
        prim_map += [llToUpper(llList2String(p, 0))];
        prim_desc += [llToUpper(llList2String(p, 1))];
    }
}

load_notecard(string name) {
    notecard_name = name;
    if (notecard_name == "") {
        notecard_name = DEFAULT_NOTECARD;
    }
    llOwnerSay("Reading notecard: " + notecard_name);
    if (can_haz_notecard(notecard_name)) {
        line = 0;
        current_buffer = "";
        element_map = [];
        reading_notecard = TRUE;
        notecard_qid = llGetNotecardLine(notecard_name, line);
    }
}

save_section() {
    // Save what we have
    log(" " + current_section + " " + (string)current_buffer);
    // skin_config += current_buffer;
    // skin_map += current_section;

    // Clean up for next line
    current_buffer = "";
    current_section = "";
}

read_config(string data) {
    if (data == EOF) {
        // All done
        save_section();
        return;
    }

    data = llStringTrim(data, STRING_TRIM_HEAD);
    if (data != "" && llSubStringIndex(data, "#") != 0) {
        if (llSubStringIndex(data, "[") == 0) {
            // Save previous section if valid
            save_section();
            // Section header
            integer end = llSubStringIndex(data, "]");
            if (end != 0) {
                // Well-formed section header
                current_section = llToUpper(llGetSubString(data, 1, end-1));
                log("Reading section " + current_section);
                // Reset section globals
            }
        } else {
            if (current_section = "elements") {
                // <prim-name>, <face>, <group>, <body-region>
                list d = llCSV2List(data);
                element_map += [
                    llToUpper(llList2String(d, 0)),
                    (integer)llList2String(d, 1),
                    llToUpper(llList2String(d, 2)),
                    (integer)llList2String(d, 3)
                ];
            }
        }
    }
    notecard_qid = llGetNotecardLine(notecard_name, ++line);
}

// ALPHA,<target>,<face>,<alpha>
do_alpha(list args) {
    if (llGetListLength(args) > 3) {
        string target = llStringTrim(llToUpper(llList2String(args, 1)), STRING_TRIM);
        integer face = llList2Integer(args, 2);
        float alpha = llList2Float(args, 3);
        integer link = llListFindList(prim_map, [target]);
        integer found = FALSE;

        // Look for target in the section list
        integer section = llListFindList(section_map, [target]);
        if (section >= 0) {
            // Put a texture on faces belonging to a group
            integer len = llGetListLength(section_map);
            integer i;
            for (; i < len; ++i) {
                // Look for matching sections in the element map
                if (llList2String(section_map, i) == target) {
                    // Get link via link name in element_map
                    link = llListFindList(prim_map, [llList2String(element_map, i * element_stride)]);
                    if (link >= 0) {
                        llSetLinkAlpha(
                            link,
                            alpha,
                            llList2Integer(element_map, (i * element_stride) + 1)
                        );
                    }
                }
            }
        }
        else if (link >= 0) {
            // Target is a prim name
            llSetLinkAlpha(link, alpha, face);
        }
        else if (target == "ALL") {
            // Set entire linkset
            integer i;
            integer len = llGetListLength(prim_map);

            for (; i < len; ++i) {
                llSetLinkAlpha(i, alpha, face);
            }
        }
    }
}

// ALPHAMODE,<target>,<face>,<alpha>
do_alphamode(list args) {
    if (llGetListLength(args) > 4) {
        string target = llStringTrim(llToUpper(llList2String(args, 1)), STRING_TRIM);
        integer face = llList2Integer(args, 2);
        integer alpha_mode = llList2Integer(args, 3);
        integer mask_cutoff =  llList2Integer(args, 4);

        integer i;
        integer len = llGetListLength(prim_map);

        for (; i < len; ++i) {
            string name = llList2String(prim_map, i);
            log(" name: " + name);
            if (name == target || target == "ALL") {
                llSetLinkPrimitiveParamsFast(i, [
                    PRIM_ALPHA_MODE, face, alpha_mode, mask_cutoff
                ]);
            }
        }

    }
}

// STATUS,<hud-api-version>
do_status(list args) {
    send_csv(["STATUS", API_VERSION, last_attach]);
}

set_tex(string target, integer face, string texture, vector color) {
    integer link = llListFindList(prim_map, [target]);
    if (link >= 0) {
        if (texture != "") {
            llSetLinkPrimitiveParamsFast(
                link,
                [
                    PRIM_TEXTURE,
                    face,
                    texture,
                    <1,1,0>,
                    <0,0,0>,
                    0
                ]
            );
        }
        if (color.x > -1) {
            // Only set if color is valid
            llSetLinkColor(link, color, face);
        }
    }
}

// TEXTURE,<target>,<texture>[,<face>,<color>]
do_texture(list args) {
    // Check for v1 args
    if (llGetListLength(args) >= 3) {
        string target = llStringTrim(llToUpper(llList2String(args, 1)), STRING_TRIM);
        string texture = llList2String(args, 2);
        integer face = ALL_SIDES;
        vector color = <-1, 0, 0>;  // not a legal color so we can test for it
        if (llGetListLength(args) > 3) {
            // Get v2 face
            face = llList2Integer(args, 3);
            // Get v2 color arg
            color = (vector)llList2String(args, 4);
        }
        integer region = llListFindList(regions, [llToUpper(target)]);
        if (region < 0) {
            // Assume target is a prim name
            set_tex(target, face, texture, color);
        } else {
            // Put a texture on faces belonging to a group
            list e3 = llList2ListStrided(llDeleteSubList(element_map, 0, 2), 0, -1, element_stride);
            integer len = llGetListLength(e3);
            integer i;
            for (; i < len; ++i) {
                // Look for matching groups in the element map
                if (llList2Integer(e3, i) == region) {
                    set_tex(
                        llList2String(element_map, i * element_stride),
                        llList2Integer(element_map, (i * element_stride) + 1),
                        texture,
                        color
                    );
                }
            }
        }
    }
}

// Initialization after notecard has been completely read
late_init() {
    // Map sections from notecard
    // section is third in stride
    section_map = llList2ListStrided(llDeleteSubList(element_map, 0, 1), 0, -1, element_stride);

    has_hands = (~llListFindList(section_map, ["HANDS"]) &&
        llGetInventoryType(hand_animation) == INVENTORY_ANIMATION);
    if (has_hands) {
        log("Using hand animation " + hand_animation);
        llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
    }
}

default {
    state_entry() {
        // Set up memory constraints
        llSetMemoryLimit(MEM_LIMIT);

        haz_xtea = can_haz_xtea();

        // Initialize attach state
        last_attach = llGetAttached();
        log("state_entry() attached="+(string)last_attach);

        reading_notecard = FALSE;
        load_notecard(notecard_name);

        map_linkset();

        // Set up listener
        r2channel = keyapp2chan(APP_ID);
        listen_main = llListen(r2channel, "", "", "");
        if (MULTI_LISTEN) {
            r2channel_alt1 = keyapp2chan(APP_ID_ALT1);
            listen_alt1 = llListen(r2channel_alt1, "", "", "");
        }

        log("Free memory " + (string)llGetFreeMemory() + "  Limit: " + (string)MEM_LIMIT);
    }

    dataserver(key query_id, string data) {
        if (query_id == notecard_qid) {
            read_config(data);
            if (data == EOF) {
                // Do end work here
                reading_notecard = FALSE;
                late_init();
                llOwnerSay("Finished reading notecard " + notecard_name);
                llOwnerSay("Free memory " + (string)llGetFreeMemory() + "  Limit: " + (string)MEM_LIMIT);
            }
        }
    }

    run_time_permissions(integer perm) {
        if (has_hands && (perm & PERMISSION_TRIGGER_ANIMATION)) {
            llStopAnimation(hand_animation);
            llStartAnimation(hand_animation);
            llSetTimerEvent(hand_refresh);
        }
    }

    timer() {
        llSetTimerEvent(hand_refresh);
        if (has_hands) {
            llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
        }
    }

    listen(integer channel, string name, key id, string message) {
        if (llGetOwnerKey(id) == llGetOwner()) {
            if (channel == r2channel || channel == r2channel_alt1) {
                log("R: " + message);
                list cmdargs = llCSV2List(message);
                string command = llToUpper(llList2String(cmdargs, 0));

                if (command == "ALPHA") {
                    do_alpha(cmdargs);
                }
                else if (command == "ALPHAMODE") {
                    do_alphamode(cmdargs);
                }
                else if (command == "ELEMENTS") {
                    send_csv(["ELEMENTS", llList2Json(JSON_ARRAY, element_map)]);
                }
                else if (command == "STATUS") {
                    do_status(cmdargs);
                }
                else if (command == "TEXTURE") {
                    do_texture(cmdargs);
                }
                else {
                    if (haz_xtea) {
                        llMessageLinked(LINK_THIS, XTEADECRYPT, message, "");
                    }
                }
            }
        }
    }

    link_message(integer sender_number, integer number, string message, key id) {
        if (number == XTEADECRYPTED) {
            list cmdargs = llCSV2List(message);
            string command = llToUpper(llList2String(cmdargs, 0));

                if (command == "ALPHA") {
                    do_alpha(cmdargs);
                }
                else if (command == "ALPHAMODE") {
                    do_alphamode(cmdargs);
                }
                else if (command == "ELEMENTS") {
                    send_csv(["ELEMENTS", llList2Json(JSON_ARRAY, element_map)]);
                }
                else if (command == "STATUS") {
                    do_status(cmdargs);
                }
                else if (command == "TEXTURE") {
                    do_texture(cmdargs);
                }
        }
    }

    changed(integer change) {
        if (change & (CHANGED_OWNER | CHANGED_INVENTORY)) {
            llResetScript();
        }
    }
}
