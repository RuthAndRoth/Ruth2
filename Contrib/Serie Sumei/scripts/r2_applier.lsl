// r2_applier.lsl - SS Combo skin applier
// SPDX-License-Identifier: CC-BY-3.0
// Copyright 2019 Serie Sumei

// ss-a - 24Mar2019 <seriesumei@avimail.org> - Initial release - apply skins only
// ss-b - 21Mar2020 <seriesumei@avimail.org> - Add Bakes on Mesh

// This script loads a notecard with button-to-skin
// mappings and listens for link messages with button names to
// send the loaded skin textures to the body.

// Commands (integer number, string message, key id)
// 411, <button>|apply, * - Apply the textures identified by <button>

// (planned features below)
// 0, <channel>|appid, * - Set the app ID used in computing the channel
// 0, <notecard>|notecard, * - Set the notecard name to load

// It also responds to some link mesages with status information:
// loaded card - returns name of loaded notecard, empty if no card is loaded
// buttons - list the loaded button names
// icon - get an icon texture to display

integer DEFAULT_APP_ID = 20181024;
integer app_id;
integer channel;

// To simplify the creator's life we read Omega-compatible notecards
string DEFAULT_NOTECARD = "!MASTER_CONFIG";
string notecard_name;
key notecard_qid;
list skin_config;
list button_names;
list thumbnails;
integer line;
integer reading_notecard = FALSE;

integer LINK_OMEGA = 411;
integer LINK_RUTH_HUD = 40;
integer LINK_RUTH_APP = 42;

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
        llOwnerSay("ap: " + msg);
    }
}

// Calculate a channel number based on APP_ID and owner UUID
integer keyapp2chan(integer id) {
    return 0x80000000 | ((integer)("0x" + (string)llGetOwner()) ^ id);
}

// Send the list of thumbnails back to the HUD for display
send_thumbnails() {
    llMessageLinked(LINK_THIS, LINK_RUTH_HUD, llList2CSV(
        [
            "THUMBNAILS",
            notecard_name
        ] +
        thumbnails
    ), "");
}

apply_texture(string button) {
    log("ap: button=" + button);

    if (button == "bom") {
        send("TEXTURE,upper," + (string)IMG_USE_BAKED_UPPER);
        send("TEXTURE,lower," + (string)IMG_USE_BAKED_LOWER);
        send("TEXTURE,head," + (string)IMG_USE_BAKED_HEAD);
        return;
    }

    integer i;
    for (; i < llGetListLength(skin_config); ++i) {
        list d = llParseStringKeepNulls(llList2String(skin_config, i), ["|"], []);
        if (llList2String(d, 0) == button) {
            if (llList2String(d, 1) == "omegaHead") {
                send("TEXTURE,head," + llList2String(d, 2));
            }
            if (llList2String(d, 1) == "lolasSkin") {
                send("TEXTURE,upper," + llList2String(d, 2));
            }
            if (llList2String(d, 1) == "skin") {
                send("TEXTURE,lower," + llList2String(d, 2));
            }
        }
    }
}

// See if the notecard is present in object inventory
integer can_haz_notecard(string name) {
    integer count = llGetInventoryNumber(INVENTORY_NOTECARD);
    while (count--) {
        if (llGetInventoryName(INVENTORY_NOTECARD, count) == name) {
            log("ap: Found notecard: " + name);
            return TRUE;
        }
    }
    llOwnerSay("ap: Notecard " + name + " not found");
    return FALSE;
}

// See if the script is present in object inventory
integer can_haz_script(string name) {
    integer count = llGetInventoryNumber(INVENTORY_SCRIPT);
    while (count--) {
        if (llGetInventoryName(INVENTORY_SCRIPT, count) == name) {
            log("ap: Found script: " + name);
            return TRUE;
        }
    }
    llOwnerSay("ap: Script " + name + " not found");
    return FALSE;
}

load_notecard(string name) {
    notecard_name = name;
    if (notecard_name == "") {
        notecard_name = DEFAULT_NOTECARD;
    }
    llOwnerSay("ap: Reading notecard: " + notecard_name);
    if (can_haz_notecard(notecard_name)) {
        line = 0;
        skin_config = [];
        button_names = [];
        thumbnails = [];
        reading_notecard = TRUE;
        notecard_qid = llGetNotecardLine(notecard_name, line);
    }
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

    reading_notecard = FALSE;
    log("ap: Free memory " + (string)llGetFreeMemory() + "  Limit: " + (string)MEM_LIMIT);
    load_notecard(notecard_name);

    haz_xtea = can_haz_script(XTEA_NAME);
}

default {
    state_entry() {
        init();
    }

    dataserver(key query_id, string data) {
        if (query_id == notecard_qid) {
            if (data != EOF) {
                data = llStringTrim(data, STRING_TRIM_HEAD);
                if (data != "" && llSubStringIndex(data, "*") != 0) {
                    if (llSubStringIndex(data, "|") >= 0) {
                        // Only save lines that might be valid
                        list d = llParseStringKeepNulls(data, ["|"], []);
                        if (llList2String(d, 1) == "thumbnail") {
                            thumbnails += llList2String(d, 2);
                        } else {
                            skin_config += data;
                            string b_name = llList2String(d, 0);
                            if (llListFindList(button_names, [b_name]) < 0) {
                                button_names += b_name;
                                log(b_name);
                            }
                        }
                    }
                    else if (llSubStringIndex(data, "mode:") >= 0) {
                        // process mode line
                        string mode = llGetSubString(data, 5, -1);
                        if (mode == "loud") {
                            VERBOSE = TRUE;
                        }
                        else if (mode = "autodelete") {
                            // remove notecard here someday
                        }
                    }
                }
                notecard_qid = llGetNotecardLine(notecard_name, ++line);
            } else {
                reading_notecard = FALSE;
                llOwnerSay("ap: Finished reading notecard " + notecard_name);
                llOwnerSay("ap: Free memory " + (string)llGetFreeMemory() + "  Limit: " + (string)MEM_LIMIT);
                send_thumbnails();
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
            log("ap: command: " + command);
            if (command == "apply") {
                apply_texture(llList2String(cmdargs, 0));
            }
        }
        if (number == LINK_RUTH_APP) {
            // <command>,<arg1>,...
            list cmdargs = llCSV2List(message);
            string command = llToUpper(llList2String(cmdargs, 0));
            if (command == "STATUS") {
                llMessageLinked(LINK_THIS, LINK_RUTH_HUD, llList2CSV([
                    command,
                    notecard_name,
                    button_names
                ]), "");
            }
            else if (command == "THUMBNAILS") {
                send_thumbnails();
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
