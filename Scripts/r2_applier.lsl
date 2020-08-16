// r2_applier.lsl - SS Combo skin applier
// SPDX-License-Identifier: MIT
// Copyright 2020 Serie Sumei

// v2.0 - 09May2020 <seriesumei@avimail.org> - New applier script
// v2.1 - 21Jun2020 <seriesumei@avimail.org> - Rework skin data to not use JSON functions
// v2.2 - 16Aug2020 <seriesumei@avimail.org> - Add nail colors to config notecard

// This script loads a notecard with skin and eye texture UUIDs
// and listens for link messages with button names to
// send the loaded skin textures to the body.

// Commands (integer number, string message, key id)
// 411: <button>|apply, * - Apply the textures identified by <button>
// 42: APPID,<appid> * - Set the app ID used in computing the channel
// 42: NOTECARD,<notecard> - Set the notecard name to load
// 42: STATUS - Return the applier status: notecard,skin_map
// 42: SKIN - Apply skin texture
// 42: EYES - Apply eye texture
// 42: NAILS - Return a list of nail colors
// 42: THuMBNAILS - Return a list of thumbnail UUIDs

// It also responds to some link mesages with status information:
// loaded card - returns name of loaded notecard, empty if no card is loaded
// buttons - list the loaded button names
// icon - get an icon texture to display

// Halcyon and older OpenSimulator builds may not have the Bakes on Mesh
// constants defined.  If you get a compiler error that these are not defined
// uncomment the following lines:
// string IMG_USE_BAKED_UPPER = "";
// string IMG_USE_BAKED_LOWER = "" ;
// string IMG_USE_BAKED_HEAD = "";
// string IMG_USE_BAKED_EYES = "";

integer DEFAULT_APP_ID = 20181024;
integer app_id;
integer channel;

string DEFAULT_NOTECARD = "!CONFIG";
string notecard_name;
key notecard_qid;
integer line;
integer reading_notecard = FALSE;
string current_section;
list current_buffer;

// Skin textures
// skin_config stores 5 sub-elements: section, thumbnail, head, upper, lower
integer skin_stride = 5;
list skin_config;
list skin_map;
list skin_thumbnails;

// Eye textures
// eye_config stores 3 sub-elements: section, thumbnail, eyes
integer eye_stride = 3;
list eye_config;
list eye_map;
list eye_thumbnails;

integer LINK_OMEGA = 411;
integer LINK_RUTH_HUD = 40;
integer LINK_RUTH_APP = 42;

// Nail colors
// Color 0 is used for BoM
vector DEFAULT_BOM_COLOR = <1.0, 1.0, 1.0>;
list nail_colors = [];

// Memory limit
integer MEM_LIMIT = 64000;

// The name of the XTEA script
string XTEA_NAME = "r2_xtea";

// Set to encrypt 'message' and re-send on channel 'id'
integer XTEAENCRYPT = 13475896;

integer haz_xtea = FALSE;

integer VERBOSE = FALSE;

log(string msg) {
    if (VERBOSE) {
        llOwnerSay(msg);
    }
}

send(string msg) {
    if (haz_xtea) {
        llMessageLinked(LINK_THIS, XTEAENCRYPT, msg, (string)channel);
    } else {
        llSay(channel, msg);
    }
    if (VERBOSE == 1) {
        llOwnerSay("r2_applier: " + msg);
    }
}

// Calculate a channel number based on APP_ID and owner UUID
integer keyapp2chan(integer id) {
    return 0x80000000 | ((integer)("0x" + (string)llGetOwner()) ^ id);
}

// Send the list of skin_thumbnails back to the HUD for display
send_skin_thumbnails() {
    llMessageLinked(LINK_THIS, LINK_RUTH_HUD, llList2CSV(
        [
            "SKIN_THUMBNAILS",
            notecard_name
        ] +
        skin_thumbnails
    ), "");
}

// Send the list of eye_thumbnails back to the HUD for display
send_eye_thumbnails() {
    llMessageLinked(LINK_THIS, LINK_RUTH_HUD, llList2CSV(
        [
            "EYE_THUMBNAILS",
            notecard_name
        ] +
        eye_thumbnails
    ), "");
}

// Send the list of nail_colors back to the HUD for display
send_nail_colors() {
    llMessageLinked(LINK_THIS, LINK_RUTH_HUD, llList2CSV(
        [
            "NAILS",
            notecard_name
        ] +
        nail_colors
    ), "");
}

// This is the v1 TEXTURE API
send_texture(string region, string tex) {
    if (region != "" && tex != "") {
        send("TEXTURE," + region + "," + tex);
    }
}

apply_skin_texture(string button) {
    log("r2_applier: button=" + button);

    if (button == "bom") {
        // Note: if you get a compiler error that these are undefined
        // uncomment the lines near the top of this script
        send_texture("head", IMG_USE_BAKED_HEAD);
        send_texture("upper", IMG_USE_BAKED_UPPER);
        send_texture("lower", IMG_USE_BAKED_LOWER);
        return;
    }

    integer i = llListFindList(skin_map, [button]);
    if (i >= 0) {
        send_texture("head", llList2String(skin_config, (i * skin_stride) + 2));
        send_texture("upper", llList2String(skin_config, (i * skin_stride) + 3));
        send_texture("lower", llList2String(skin_config, (i * skin_stride) + 4));
    }
}

apply_eye_texture(string button) {
    log("r2_applier: button=" + button);

    if (button == "bom") {
        send_texture("lefteye", IMG_USE_BAKED_EYES);
        send_texture("righteye", IMG_USE_BAKED_EYES);
        return;
    }

    integer i = llListFindList(eye_map, [button]);
    if (i >= 0) {
        string eye_tex = llList2String(eye_config, (i * eye_stride) + 2);
        send_texture("lefteye", eye_tex);
        send_texture("righteye", eye_tex);
    }
}

// See if the notecard is present in object inventory
integer can_haz_notecard(string name) {
    integer count = llGetInventoryNumber(INVENTORY_NOTECARD);
    while (count--) {
        if (llGetInventoryName(INVENTORY_NOTECARD, count) == name) {
            log("r2_applier: Found notecard: " + name);
            return TRUE;
        }
    }
    llOwnerSay("r2_applier: Notecard " + name + " not found, no textures will be loaded");
    return FALSE;
}

// See if the script is present in object inventory
integer can_haz_script(string name) {
    integer count = llGetInventoryNumber(INVENTORY_SCRIPT);
    while (count--) {
        if (llGetInventoryName(INVENTORY_SCRIPT, count) == name) {
            log("r2_applier: Found script: " + name);
            return TRUE;
        }
    }
    log("r2_applier: Script " + name + " not found");
    return FALSE;
}

load_notecard(string name) {
    notecard_name = name;
    if (notecard_name == "") {
        notecard_name = DEFAULT_NOTECARD;
    }
    log("r2_applier: Reading notecard: " + notecard_name);
    if (can_haz_notecard(notecard_name)) {
        line = 0;
        // Need to pre-load current_buffer, must be at least the longest stride
        current_buffer = ["", "", "", "", ""];
        reading_notecard = TRUE;
        skin_config = [];
        skin_map = [];
        skin_thumbnails = [];
        eye_config = [];
        eye_map = [];
        eye_thumbnails = [];
        nail_colors = [DEFAULT_BOM_COLOR];
        notecard_qid = llGetNotecardLine(notecard_name, line);
    }
}

save_section() {
    // Save what we have
    log(" " + current_section + " " + (string)current_buffer);
    string value;

    // Get thumbnail
    value = llList2String(current_buffer, 1);

    if (llGetSubString(current_section, 0, 3) == "skin") {
        skin_config += current_buffer;
        skin_map += llGetSubString(current_section, 4, -1);
        if (value != "") {
            // Move the thumbnail UUID to that list
            skin_thumbnails += value;
        } else {
            skin_thumbnails += "";
        }
    }
    else if (llGetSubString(current_section, 0, 3) == "eyes") {
        eye_config += current_buffer;
        eye_map += llGetSubString(current_section, 4, -1);
        if (value != "") {
            // Move the thumbnail UUID to that list
            eye_thumbnails += value;
        } else {
            eye_thumbnails += "";
        }
    }
    else if (llGetSubString(current_section, 0, 4) == "nails") {
        // The section name is the first item in the list, pop it off
        nail_colors += llDeleteSubList(current_buffer, 0, 0);
    }

    // Clean up for next line
    // Need to pre-load current_buffer, must be at least the longest stride
    current_buffer = ["", "", "", "", ""];
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
                current_section = llGetSubString(data, 1, end-1);
                current_buffer = llListReplaceList(current_buffer, [current_section], 0, 0);
                log("Reading section " + current_section);
            }
        } else {
            integer i = llSubStringIndex(data, "=");
            if (i != -1) {
                string attr = llToLower(llStringTrim(llGetSubString(data, 0, i-1), STRING_TRIM));
                string value = "";
                if (i < llStringLength(data)-1) {
                    value = llStringTrim(llGetSubString(data, i+1, -1), STRING_TRIM);
                }

                if (attr == "head" || attr == "omegaHead") {
                    // Save head
                    current_buffer = llListReplaceList(current_buffer, [value], 2, 2);
                }
                else if (attr == "upper" || attr == "lolasSkin") {
                    // Save upper body
                    current_buffer = llListReplaceList(current_buffer, [value], 3, 3);
                }
                else if (attr == "lower" || attr == "skin") {
                    // Save upper body
                    current_buffer = llListReplaceList(current_buffer, [value], 4, 4);
                }
                else if (attr == "thumbnail") {
                    // Save upper body
                    current_buffer = llListReplaceList(current_buffer, [value], 1, 1);
                }
                else if (attr == "eyes") {
                    // Save eyes
                    current_buffer = llListReplaceList(current_buffer, [value], 2, 2);
                }
                else if (current_section == "nails") {
                    // Save nail colors
                    integer slot = (integer)attr;
                    current_buffer = llListReplaceList(current_buffer, [value], slot, slot);
                }
                else {
//                    llOwnerSay("Unknown configuration value: " + name + " on line " + (string)line);
                }
            } else {
                // not an assignment line
//                llOwnerSay("Configuration could not be read on line " + (string)line);
            }
        }
    }
    notecard_qid = llGetNotecardLine(notecard_name, ++line);
}

init() {
    // Set up memory constraints
    llSetMemoryLimit(MEM_LIMIT);

    // Initialize app ID
    if (app_id == 0) {
        app_id = DEFAULT_APP_ID;
    }

    // Initialize channel
    channel = keyapp2chan(app_id);

    log("r2_applier: Free memory " + (string)llGetFreeMemory() + "  Limit: " + (string)MEM_LIMIT);
    reading_notecard = FALSE;
    load_notecard(notecard_name);

    haz_xtea = can_haz_script(XTEA_NAME);
}

default {
    state_entry() {
        init();
    }

    dataserver(key query_id, string data) {
        if (query_id == notecard_qid) {
            read_config(data);
            if (data == EOF) {
                // Do end work here
                reading_notecard = FALSE;
                llOwnerSay("r2_applier: Finished reading notecard " + notecard_name);
                llOwnerSay("r2_applier: Free memory " + (string)llGetFreeMemory() + "  Limit: " + (string)MEM_LIMIT);
                send_skin_thumbnails();
                send_eye_thumbnails();
                send_nail_colors();
            }
        }
    }

    link_message(integer sender_number, integer number, string message, key id) {
        if (number == LINK_OMEGA) {
            // Listen for applier-like messages
            // Messages are pipe-separated
            // <button>|<command>
            list cmdargs = llParseString2List(message, ["|"], [""]);
            string command = llList2String(cmdargs, 1);
            log("r2_applier: command: " + command);
            if (command == "apply") {
                apply_skin_texture(llList2String(cmdargs, 0));
            }
        }
        if (number == LINK_RUTH_APP) {
            // <command>,<arg1>,...
            list cmdargs = llCSV2List(message);
            string command = llToUpper(llList2String(cmdargs, 0));
            if (command == "STATUS") {
                llMessageLinked(LINK_THIS, LINK_RUTH_HUD, llList2CSV([
                    command,
                    notecard_name
                ]), "");
            }
            else if (command == "SKIN") {
                apply_skin_texture(llList2String(cmdargs, 1));
            }
            else if (command == "EYES") {
                apply_eye_texture(llList2String(cmdargs, 1));
            }
            else if (command == "NAILS") {
                send_nail_colors();
            }
            else if (command == "THUMBNAILS") {
                send_skin_thumbnails();
                send_eye_thumbnails();
            }
            else if (command == "NOTECARD") {
                load_notecard(llList2String(cmdargs, 1));
            }
            else if (command == "APPID") {
                channel = keyapp2chan(llList2Integer(cmdargs, 1));
            }
            else if (command == "DEBUG") {
                VERBOSE = llList2Integer(cmdargs, 1);
            }
        }
    }

    changed(integer change) {
        if (change & (CHANGED_OWNER | CHANGED_INVENTORY)) {
            init();
        }
    }
}
