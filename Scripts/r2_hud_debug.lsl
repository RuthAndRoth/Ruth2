// r2_hud_debug.lsl - Debugging functions for the Rut2/Roth2 avatar HUDs
// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright 2020 Serie Sumei

// v3.0 04Apr2020 <seriesumei@avimail.org> - New script, matches to the Ruth2 v3 scripts

// The Debug dialog is activated by a long-click on the HUD (hold the
// click for more than 2 seconds).

// The app ID is used on calculating the actual channel number used for communication
// and must match in both the HUD and receivers.
integer APP_ID = 20181024;

integer VERBOSE = FALSE;
integer MEM_LIMIT = 32000;

list prim_map = [];
integer num_links = 0;

// Ruth link messages
integer LINK_RUTH_HUD = 40;
integer LINK_RUTH_APP = 42;

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

integer r2channel;


// ***
// Popup Dialogs
float MENU_TIMEOUT = 30.0;
integer MENU_CHANNEL = -19283;
integer menu_handle;

// Debug popup
list DEBUG_MENU = ["Debug", "Alpha", "Done", "Elements"];
string DEBUG_TEXT = "Debug Options";

// Alpha popup
list ALPHA_MENU = ["Back", "_", "Done", "Blending", "Masking", "Emissive", "Cutoff=0", "Cutoff=128", "Cutoff=255"];
string ALPHA_TEXT = "Set Alpha mode for body";
integer alpha_mode = 0;
integer mask_cutoff = 0;
// ***

// Buffer for chunked messages
list buffer;

log(string msg) {
    if (VERBOSE == 1) {
        llOwnerSay(msg);
    }
}

// See if the XTEA script is present in object inventory
integer can_haz_script(string name) {
    integer count = llGetInventoryNumber(INVENTORY_SCRIPT);
    while (count--) {
        if (llGetInventoryName(INVENTORY_SCRIPT, count) == name) {
            log("Found script: " + name);
            return TRUE;
        }
    }
    llOwnerSay("Script " + name + " not found");
    return FALSE;
}

send(string msg) {
    if (haz_xtea) {
        llMessageLinked(LINK_THIS, XTEAENCRYPT, msg, (string)r2channel);
    } else {
        llSay(r2channel, msg);
    }
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

// ***
// Popup dialogs

// Display the debug dialog
debug_dialog(key id) {
    string text = DEBUG_TEXT +
        "\nDebug: " + (string)VERBOSE;
    menu_handle = llListen(MENU_CHANNEL, "", NULL_KEY, "");
    llDialog(id, text, DEBUG_MENU, MENU_CHANNEL);
    llSetTimerEvent(MENU_TIMEOUT);
}

// Display the alpha dialog
alpha_dialog(key id) {
    log("d: alpha_dialog()");
    string text = ALPHA_TEXT +
        "\nalpha mode: " + (string)alpha_mode +
        "\nmask cutoff: " + (string)mask_cutoff;
    menu_handle = llListen(MENU_CHANNEL, "", NULL_KEY, "");
    llDialog(id, text, ALPHA_MENU, MENU_CHANNEL);
    llSetTimerEvent(MENU_TIMEOUT);
}

// Handle dialog responses
do_menu(key id, string message) {
    log("d: do_menu(): " + message);
    if (message == "Back") {
        // Assume there is only two levels of dialogs
        debug_dialog(id);
        jump exit_menu;
    }
    if (message == "Done") {
        jump exit_menu;
    }
    else if (message == "Debug") {
        VERBOSE = !VERBOSE;
        debug_dialog(id);
        jump exit_menu;
    }
    else if (message == "Elements") {
        // Send the Elements command to the HUD receiver
        send_csv(["ELEMENTS"]);
        debug_dialog(id);
        jump exit_menu;
    }
    else if (message == "Alpha") {
        alpha_dialog(id);
        jump exit_menu;
    }
    else if (message == "Blending") {
        alpha_mode = PRIM_ALPHA_MODE_BLEND;
    }
    else if (message == "Masking") {
        alpha_mode = PRIM_ALPHA_MODE_MASK;
    }
    else if (llGetSubString(message, 0, 5) == "Cutoff") {
        // Get value
        mask_cutoff = (integer)llGetSubString(message, 7, -1);
    }
    send_csv(["ALPHAMODE", "all", -1, alpha_mode, mask_cutoff]);
    alpha_dialog(id);
@exit_menu;
}

init() {
    // Set up memory constraints
    llSetMemoryLimit(MEM_LIMIT);

    r2channel = keyapp2chan(APP_ID);
    llListen(r2channel+1, "", "", "");

    // Create map of all links to prim names
    integer i;
    num_links = llGetNumberOfPrims() + 1;
    for (; i < num_links; ++i) {
        list p = llGetLinkPrimitiveParams(i, [PRIM_NAME]);
        string name = llList2String(p, 0);
        prim_map += [name];
    }

    log("d: Free memory " + (string)llGetFreeMemory() + "  Limit: " + (string)MEM_LIMIT);

    haz_xtea = can_haz_script(XTEA_NAME);
    buffer = [];
}

default {
    state_entry() {
        init();
    }

    listen(integer channel, string name, key id, string message) {
        if (llGetOwnerKey(id) == llGetOwner()) {
            if (channel == r2channel+1) {
                log("d: R: " + message);
                list cmdargs = llCSV2List(message);
                string command = llToUpper(llList2String(cmdargs, 0));

                if (llGetSubString(command, 0, 0) == "+") {
                    // Handle chunked response
                    integer c = llSubStringIndex(message, ",");
                    if (c >= 0) {
                        // Save the raw string for later re-assembly
                        buffer += llGetSubString(message, c+1, -1);
                    }
                }
                else if (command == "STATUS") {
                    llOwnerSay("d: " +
                        "STATUS: " +
                        "API v" + llList2String(cmdargs, 1) + ", " +
                        "Type " + llList2String(cmdargs, 2) + ", " +
                        "Attached " + llList2String(cmdargs, 3)
                    );
                }
                else if (command == "ELEMENTS") {
                    integer c = llSubStringIndex(message, ",");
                    if (c >= 0) {
                        // See if it was a long message
                        if (buffer != []) {
                            // Save last chunk to buffer
                            buffer += llGetSubString(message, c+1, -1);
                            // Re-assemble
                            message = llDumpList2String(buffer, "");
                            buffer = [];
                        }
                        llOwnerSay("msg: " + message);
                    }
                }
            }
            else if (channel == MENU_CHANNEL) {
                llListenRemove(menu_handle);
                llSetTimerEvent(0);
                do_menu(id, message);
            }
        }
    }

    touch_start(integer total_number) {
        llResetTime();
    }

    touch_end(integer total_number) {
        integer long = (llGetTime() > 2.0);
        if (long) {
            log("d: long press");
            // Long touch on top bar
            debug_dialog(llDetectedKey(0));
        }
    }

    timer(){
        // Dialog timeout
        llListenRemove(menu_handle);
        llSetTimerEvent(0);
    }
}
