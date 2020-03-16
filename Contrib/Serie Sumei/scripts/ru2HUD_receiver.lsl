// ru2HUD_receiver.lsl - Ruth2 v3 HUD Receiver
// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright 2017 Shin Ingen
// Copyright 2019 Serie Sumei

// v1 26Jan2019 <seriesumei@avimail.org> - Initial combination of body, feet
//      and hands scripts, includes fingernails
// v2 03Feb2019 <seriesumei@avimail.org> - Reset script on ownership change,
//      listen on multiple APP_IDs
// v3 09Feb2019 <seriesumei@avimail.org> - Add XTEA support
// v4 06Apr2019 <seriesumei@avimail.org> - Fix initialization bug in OpenSim
// v5 15Mar2020 <seriesumei@avimail.org> - Remove part type for hands and feet
//      to handle when hands and feet are linked to body

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

// The body part types are used to track which type the script is handling
// and is inferred at start-up by looking for specific names in the linkset.
// Override this by directly setting PART_TYPE_DEFAULT below.
integer PART_TYPE_NULL = 0;
integer PART_TYPE_BODY = 1;
integer PART_TYPE_HANDS = 2;
integer PART_TYPE_FEET = 3;
integer PART_TYPE_DEFAULT = 0;
integer part_type;

// Map prim name and descriptions to link numbers
list prim_map = [];
list prim_desc = [];

// Spew some info
integer VERBOSE = FALSE;

// Memory limit
integer MEM_LIMIT = 32000;

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

send_csv(list msg) {
    send(llList2CSV(msg));
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

// ALPHA,<target>,<face>,<alpha>
do_alpha(list args) {
    if (llGetListLength(args) > 3) {
        string target = llStringTrim(llToUpper(llList2String(args, 1)), STRING_TRIM);
        integer face = llList2Integer(args, 2);
        float alpha = llList2Float(args, 3);
        integer link = llListFindList(prim_map, [target]);
        integer found = FALSE;
        if (link > -1) {
            // Found a matching part name, use it
            found = TRUE;
        }
        // // Override link on hands and feet
        // if (part_type == PART_TYPE_HANDS && target == "HANDS") {
        //     link = LINK_ALL_CHILDREN;
        //     found = TRUE;
        // }
        // else if (part_type == PART_TYPE_FEET && target == "FEET") {
        //     link = LINK_ALL_CHILDREN;
        //     found = TRUE;
        // }
        if (found) {
            llSetLinkAlpha(link, alpha, face);
        }
    }
}

// STATUS,<hud-api-version>
do_status(list args) {
    send_csv(["STATUS", API_VERSION, part_type, last_attach]);
}

// TEXTURE,<target>,<texture>[,<face>,<color>]
do_texture(list args) {
    // Check for v1 args
    if (llGetListLength(args) >= 3) {
        string target = llStringTrim(llToUpper(llList2String(args, 1)), STRING_TRIM);
        string texture = llList2String(args, 2);
        integer face;
        vector color;
        integer has_color = FALSE;
        if (llGetListLength(args) > 3) {
            has_color = TRUE;
            // Get v2 face
            face = llList2Integer(args, 3);
            // Get v2 color arg
            color = (vector)llList2String(args, 4);
        }
        if (llListFindList(["FINGERNAILS", "HEAD", "LOWER", "TOENAILS", "UPPER"], [target]) < 0) {
            log(" prim="+target);
            // Search for a prim name
            integer prim = llListFindList(prim_map, [target]);
            if (prim > -1) {
                llSetLinkColor(prim, color, face);
            }
        } else {
            integer i;
            integer x = llGetListLength(prim_desc);

            for (; i < x; ++i) {
                string objdesc = llList2String(prim_desc, i);

                if (objdesc == target) {
                    if (texture != "") {
                        llSetLinkPrimitiveParamsFast(
                            i,
                            [
                                PRIM_TEXTURE,
                                ALL_SIDES,
                                texture,
                                <1,1,0>,
                                <0,0,0>,
                                0
                            ]
                        );
                    }
                    if (has_color) {
                        llSetLinkColor(i, color, face);
                    }
                }
            }
        }
    }
}

default {
    state_entry() {
        haz_xtea = can_haz_xtea();

        // Initialize attach state
        last_attach = llGetAttached();
        log("state_entry() attached="+(string)last_attach);

        map_linkset();

        // Deduce part type from the linked names
        part_type = PART_TYPE_DEFAULT;
        if (~llListFindList(prim_map, ["CHEST"])) {
            part_type = PART_TYPE_BODY;
        }
        // else if (~llListFindList(prim_map, ["HANDS"])) {
        //     part_type = PART_TYPE_HANDS;
        // }
        // else if (~llListFindList(prim_map, ["FEET"])) {
        //     part_type = PART_TYPE_FEET;
        // }

        // Set up listener
        r2channel = keyapp2chan(APP_ID);
        listen_main = llListen(r2channel, "", "", "");
        if (MULTI_LISTEN) {
            r2channel_alt1 = keyapp2chan(APP_ID_ALT1);
            listen_alt1 = llListen(r2channel_alt1, "", "", "");
        }

        // if (part_type == PART_TYPE_HANDS) {
        //     llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
        // }

        log("Free memory " + (string)llGetFreeMemory() + "  Limit: " + (string)MEM_LIMIT);
    }

    run_time_permissions(integer perm) {
        if (part_type == PART_TYPE_BODY && (perm & PERMISSION_TRIGGER_ANIMATION)) {
            llStopAnimation("bentohandrelaxedP1");
            llStartAnimation("bentohandrelaxedP1");
            llSetTimerEvent(3);
        }
    }

    timer() {
        llSetTimerEvent(0);
        // if (part_type == PART_TYPE_HANDS) {
        //     llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
        // }
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
